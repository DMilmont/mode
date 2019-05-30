with filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid = '{{ dpid }}' 
),

base_percentile_data as (
    SELECT dpid, percent_rank() OVER (ORDER BY score) keep_dpids
    FROM fact.f_benchmark b
    WHERE end_month = (SELECT max(end_month) from fact.f_benchmark)
    ORDER BY percent_rank() OVER (ORDER BY score) desc
),

percentile_dpids as (

    SELECT DISTINCT 90 percentile, dpid
    FROM base_percentile_data
    WHERE keep_dpids >= .90

    UNION

    SELECT DISTINCT 75 percentile, dpid
    FROM base_percentile_data
    WHERE keep_dpids >= .75

    UNION

    SELECT DISTINCT 50 percentile, dpid
    FROM base_percentile_data
    WHERE keep_dpids >= .50

    ORDER BY percentile, dpid
  ), 
  
 percent_dpids as ( 
SELECT percentile_dpids.*,
       '' || percentile_dpids.percentile::text || 'th Percentile Dealer Groups' "name",
       0 dpsk,
       'All' primary_make
FROM percentile_dpids
),


filter_for_dealer_group  as (
SELECT DISTINCT di.dpid, dealer_group, dp.tableau_secret
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END = (SELECT * FROM filter_for_dpids)
--AND dealer_group <> dp.name
),

date_dpid as (
select c.date, dp.dpid,dp.name, primary_make
from fact.d_cal_date c
cross join (
  select distinct dps.dpid, dps.tableau_secret, dps.name, primary_make
  from dealer_partners dps
  INNER JOIN filter_for_dealer_group fdg ON dps.dpid = fdg.dpid AND dps.tableau_secret = fdg.tableau_secret
  ) dp 
--  where dpid not like '%demo%')dp 
where c.date >= (date_trunc('month', now()))  
group by 1,2,3,4
),

almost_final as (
SELECT
       dp.name "Dealership",
       properties ->> 'unlock_lead_capture' unlock_lead, 
       properties ->> 'show_express_unlock_modal' express_unlock,
       properties ->> 'in_store_purchase_wizard' in_store_wizard, 
       properties ->> 'price_unlock_mode' unlock_mode,
       properties ->> 'unlock_count_unvalidated' unlock_ct_unval,
       properties ->> 'unlock_count_validated' unlock_ct_val,
       properties ->> 'unlock_count_days' unlock_ct_days
FROM dealer_partner_properties dpp
LEFT JOIN dealer_partners dp ON dpp.dealer_partner_id = dp.id
WHERE dpid IN (SELECT distinct dpid FROM date_dpid)
AND date = (SELECT max(date) FROM dealer_partner_properties)
ORDER BY date desc
)

SELECT 
initcap("Dealership") "Dealership",
CASE WHEN in_store_wizard = '' OR in_store_wizard = 'false' THEN 'x'
            else '✓' END "In-Store Purchase Wizard",
CASE 
  WHEN unlock_mode = 'nolock' THEN 'Prices Unlocked'
  WHEN unlock_mode = 'pervin' THEN 'Counted Per-Vin'
  WHEN unlock_mode = 'msrplock' THEN 'Locked - Price < MSRP'
  WHEN unlock_mode = 'invoicelock' THEN 'Locked - Price < Invoice'
  WHEN unlock_mode = 'lock' THEN 'Always Locked'
  ELSE unlock_mode
  END "Price Unlock Mode",
CASE WHEN unlock_lead = 'false' THEN 'Unverified Leads'
    ELSE 'Verified Leads' END AS "Lead Type",
CASE 
  WHEN unlock_mode = 'nolock' THEN ''
  WHEN unlock_lead = 'false' THEN 'https://s3.amazonaws.com/expressstoreunlock/base_unlock_resized.png'
  ELSE 'https://s3.amazonaws.com/expressstoreunlock/full_unlock.png'
  END test_img
FROM almost_final