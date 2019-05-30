WITH 
in_store_shares as (
SELECT dpid, date_trunc('day', cohort_date_utc) date, COUNT(DISTINCT customer_email) COUNT_SHARES
FROM fact.f_prospect
WHERE source = 'Lead Type' AND item_type = 'SharedExpressVehicle'
AND IS_IN_STORE = True
AND cohort_date_utc <= (NOW() - INTERVAL'1 day')
AND cohort_date_utc >= (NOW() - INTERVAL'3 months')
GROUP BY 1,2

), 

in_store_prospects as (
SELECT dpid, date_trunc('day', cohort_date_utc) date, COUNT(DISTINCT customer_email) COUNT_prospects
FROM fact.f_prospect
WHERE source = 'Lead Type' 
AND IS_IN_STORE = True
AND cohort_date_utc <= (NOW() - INTERVAL'1 day')
AND cohort_date_utc >= (NOW() - INTERVAL'3 months')
GROUP BY 1,2
), 

instore_orders as (
SELECT dpid, date_trunc('day', cohort_date_utc) date, COUNT(DISTINCT customer_email) COUNT_orders
FROM fact.f_prospect
WHERE source = 'Lead Type' AND item_type = 'OrderStarted'
AND IS_IN_STORE = True
AND cohort_date_utc <= (NOW() - INTERVAL'1 day')
AND cohort_date_utc >= (NOW() - INTERVAL'3 months')
GROUP BY 1,2
), 

instore_sales as (
SELECT dpid,
       date_trunc('day', cohort_date_utc)::date date,
       COUNT(distinct case when source = 'Lead Type' and is_prospect_close_sale = true then customer_email end) COUNT_SALES
FROM fact.f_prospect
WHERE source = 'Lead Type'
AND cohort_date_utc <= (NOW() - INTERVAL'1 day')
AND cohort_date_utc >= (NOW() - INTERVAL'3 months')
AND is_in_store = True
GROUP BY 1,2
), 

prints_copies as (
SELECT dpid, date, copies_to_clipboard, prints_price_summary + prints_share_details prints
FROM (SELECT dpid,
             date_trunc('day', timestamp) :: date date,
             count(DISTINCT
              CASE
               WHEN ((ue.name) :: text = 'Print Price Summary' :: text) THEN ue.id
               ELSE NULL :: integer
                  END) AS prints_price_summary,
             count(DISTINCT
              CASE
               WHEN ((ue.name) :: text = 'Print Share Details' :: text) THEN ue.id
               ELSE NULL :: integer
                  END) AS prints_share_details,
             count(DISTINCT
              CASE
               WHEN ((ue.name) :: text = 'Copy To Clipboard' :: text) THEN ue.id
               ELSE NULL :: integer
                  END) AS copies_to_clipboard
      FROM user_events ue
            LEFT JOIN dealer_partners dp ON ue.dealer_partner_id = dp.id
      WHERE timestamp <= (NOW() - INTERVAL'1 day')
        AND timestamp >= (NOW() - INTERVAL'3 months')
      GROUP BY 1, 2) t
),

filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT di.dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid = '{{ dpid }}' AND dp.tableau_secret = {{ dpsk }}
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
       'Top ' || percentile_dpids.percentile::text || 'th Percentile Dealer Groups' "name",
       0 dpsk,
       'All' primary_make
FROM percentile_dpids
),


filter_for_dealer_group  as (
SELECT DISTINCT di.dpid, dealer_group, dp.tableau_secret
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dealer_group = (SELECT * FROM filter_for_dpids)
),

date_dpid as (
select c.date, dp.dpid,dp.name, dp.tableau_secret as dpsk, primary_make
from fact.d_cal_date c
cross join (
  select distinct dps.dpid, dps.tableau_secret, dps.name, primary_make
  from dealer_partners dps
  INNER JOIN filter_for_dealer_group fdg ON dps.dpid = fdg.dpid AND dps.tableau_secret = fdg.tableau_secret
  ) dp 
--  where dpid not like '%demo%')dp 
where c.date >= (NOW() - INTERVAL'3 months')    
and c.date <= (NOW() - INTERVAL'1 day')
group by 1,2,3,4,5

UNION

SELECT date, dpid, "name", dpsk, primary_make
FROM percent_dpids
FULL JOIN (
  SELECT *
  FROM fact.d_cal_date
) t ON 1=1

)


SELECT dd.name "Dealership",
dd.date::date "Date", 
COALESCE(ROUND(AVG(count_prospects),2), 0.0) "In-Store Prospects",
COALESCE(ROUND(AVG(count_shares),2), 0.0) "In-Store Shares", 
COALESCE(ROUND(AVG(count_orders),2), 0.0) "In-Store Orders", 
COALESCE(ROUND(AVG(copies_to_clipboard),2), 0.0) "Copies",
COALESCE(ROUND(AVG(prints),2), 0.0) "Prints", 
COALESCE(ROUND(AVG(count_sales),2), 0) "In-Store Sales", 
COALESCE(ROUND(AVG(ROUND(count_sales::decimal / count_shares::decimal,2)),2), 0.0) "Close Rate"
FROM date_dpid dd
LEFT JOIN in_store_prospects isp ON dd.dpid = isp.dpid AND dd.date = isp.date
LEFT JOIN in_store_shares iss ON dd.dpid = iss.dpid AND dd.date = iss.date
LEFT JOIN instore_orders iso ON dd.dpid = iso.dpid AND dd.date = iso.date 
LEFT JOIN instore_sales issa ON dd.dpid = issa.dpid AND dd.date = issa.date
LEFT JOIN prints_copies pc ON dd.dpid = pc.dpid AND dd.date = pc.date
GROUP BY 1,2
