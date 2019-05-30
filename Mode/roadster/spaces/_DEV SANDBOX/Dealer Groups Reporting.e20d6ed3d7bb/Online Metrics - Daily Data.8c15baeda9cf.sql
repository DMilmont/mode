-- Online Metrics Section

with filter_for_dpids as (
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

,online_express_traffic as (
select 
  a.date
, a.dpid
, dpsk
, sum(count) online_express_visitors
from fact.mode_agg_daily_traffic_and_prospects a
INNER JOIN filter_for_dealer_group fdg ON a.dpid = fdg.dpid
where type = 'Online Express Traffic'
and date >= (NOW() - INTERVAL'3 months')   
and date <= (NOW() - INTERVAL'1 day')
AND dealer_group IS NOT NULL
group by 1,2,3)

,online_express_srp_traffic as (
select 
  b.date
, b.dpid
, dpsk
, sum(count) as online_express_srp_visitors
from fact.mode_agg_daily_traffic_and_prospects b
INNER JOIN filter_for_dealer_group fdg ON b.dpid = fdg.dpid
where type = 'Online Express SRP Traffic'
and date >= (NOW() - INTERVAL'3 months')   
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3)


,online_express_vdp_traffic as (
select 
  c.date
, c.dpid
, dpsk
, sum(count) as online_express_vdp_visitors
from fact.mode_agg_daily_traffic_and_prospects c
INNER JOIN filter_for_dealer_group fdg ON c.dpid = fdg.dpid
where type = 'Online Express VDP Traffic'
and date >= (NOW() - INTERVAL'3 months')   
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3)

,online_prospects as (
select 
  d.date
, d.dpid
, dpsk
, sum(count) online_prospects
from fact.mode_agg_daily_traffic_and_prospects d
INNER JOIN filter_for_dealer_group fdg ON d.dpid = fdg.dpid
where type = 'Online Prospects'
and date >= (NOW() - INTERVAL'3 months')   
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3)

, online_shares as (
  
SELECT dpid, date_trunc('day', cohort_date_utc) date, COUNT(DISTINCT customer_email) COUNT_SHARES
FROM fact.f_prospect
WHERE source = 'Lead Type' AND item_type = 'SharedExpressVehicle'
AND IS_IN_STORE = False
AND cohort_date_utc <= (NOW() - INTERVAL'1 day')
AND cohort_date_utc >= (NOW() - INTERVAL'3 months')
GROUP BY 1,2


)

,in_store_shares as (
select 
  d.date
, d.dpid
, dpsk
, sum(count) is_shares
from fact.mode_agg_daily_traffic_and_prospects d
INNER JOIN filter_for_dealer_group fdg ON d.dpid = fdg.dpid
where type = 'In-Store Shares'
and date >= (NOW() - INTERVAL'3 months')   
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3)

,in_store_orders as (
SELECT f_prospect.cohort_date_utc                AS date,
         f_prospect.dpid,
         f_prospect.dpsk,
         count(DISTINCT f_prospect.customer_email) AS instore_orders
  FROM fact.f_prospect
  WHERE ((f_prospect.cohort_date_utc >= date_trunc('month' :: text, (CURRENT_DATE - '3 mons' :: interval))) AND
         (f_prospect.cohort_date_utc < CURRENT_DATE) AND (f_prospect.is_in_store IS NOT FALSE) AND
         (f_prospect.item_type = 'OrderStarted' :: text) AND (f_prospect.source = 'Lead Type' :: text))
  GROUP BY f_prospect.cohort_date_utc, f_prospect.dpid, f_prospect.dpsk, 'Online Orders' :: text
), online_orders as (
select 
  d.date
, d.dpid
, dpsk
, sum(count) online_orders
from fact.mode_agg_daily_traffic_and_prospects d
INNER JOIN filter_for_dealer_group fdg ON d.dpid = fdg.dpid
where type = 'Online Orders'
and date >= (NOW() - INTERVAL'3 months')   
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3)
, instore_prospects as (
SELECT f_prospect.cohort_date_utc                AS date,
         f_prospect.dpid,
         f_prospect.dpsk,
         count(DISTINCT f_prospect.customer_email) AS instore_prospects
  FROM fact.f_prospect
  WHERE ((f_prospect.cohort_date_utc >= date_trunc('month' :: text, (CURRENT_DATE - '3 mons' :: interval))) AND
         (f_prospect.cohort_date_utc < CURRENT_DATE) AND (f_prospect.is_in_store <> FALSE))
  GROUP BY f_prospect.cohort_date_utc, f_prospect.dpid, f_prospect.dpsk
)

, online_sales as (
SELECT dpid,
       date_trunc('day', cohort_date_utc)::date date,
       COUNT(distinct case when source = 'Lead Type' and is_prospect_close_sale = true then customer_email end) COUNT_SALES
FROM fact.f_prospect
WHERE source = 'Lead Type'
AND cohort_date_utc <= (NOW() - INTERVAL'1 day')
AND cohort_date_utc >= (NOW() - INTERVAL'3 months')
AND is_in_store = False
GROUP BY 1,2
)


, final_data as (
select 
  dd.date::date as "Date"
, dd.primary_make
, dd.name as "Dealership"
, dt.visitors as "Dealer Visitors"
, et.online_express_visitors as "Online Express Visitors"
, online_express_srp_visitors as "Online Express SRP Visitors"
, online_express_vdp_visitors as "Online Express VDP Visitors"
, op.online_prospects as "Online Prospects"
, iss.is_shares as "In-Store Shares"
, iso.instore_orders as "In-Store Orders"
, oo.online_orders
, isp.instore_prospects
, os.count_shares online_shares
, oss.count_sales online_sales
, LEAST(ROUND((et.online_express_visitors::numeric/dt.visitors::numeric), 2), 1.0) as "Online Express Ratio"
, LEAST(ROUND((op.online_prospects::numeric/et.online_express_visitors::numeric), 2), 1.0) as "Conversion to Online Prospect"
, ROUND(oss.count_sales / op.online_prospects, 2) "Close Rate"
from date_dpid dd 
left join online_express_traffic et on et.date = dd.date and et.dpid = dd.dpid 
left join fact.agg_daily_dealer_traffic dt on dt.dpid = dd.dpid and dt.date = dd.date
left join online_express_vdp_traffic vdp on vdp.date = dd.date and vdp.dpid = dd.dpid
left join online_express_srp_traffic srp on srp.date = dd.date and srp.dpid = dd.dpid
left join online_prospects op on op.dpid = dd.dpid and op.date = dd.date 
LEFT JOIN in_store_shares iss ON op.dpid = iss.dpid and op.date = iss.date
LEFT JOIN in_store_orders iso ON op.dpid = iso.dpid and op.date = iso.date
LEFT JOIN online_orders oo ON op.dpid = oo.dpid and op.date = oo.date
LEFT JOIN instore_prospects isp ON op.dpid = isp.dpid and op.date = isp.date
LEFT JOIN online_shares os ON op.dpid = os.dpid AND op.date = os.date
LEFT JOIN online_sales oss ON op.dpid = oss.dpid AND op.date = oss.date
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17),

tab as (
SELECT "Date",
"Dealership",
COALESCE(ROUND(AVG("Dealer Visitors"), 2), 0.0) "Dealer Visitors",
COALESCE(ROUND(AVG("Online Express Visitors"), 2), 0.0) "Express Visitors",
COALESCE(ROUND(AVG("Online Express Ratio"), 2), 0.0) "Online Express Ratio",
COALESCE(ROUND(AVG("Conversion to Online Prospect"), 2), 0.0) "Prospect Conversion",
COALESCE(ROUND(AVG(online_shares), 2), 0.0) "Online Shares",
COALESCE(ROUND(AVG(online_orders), 2), 0.0) "Online Orders",
COALESCE(ROUND(AVG(online_sales), 2), 0.0) "Roadster Matched Sales",
COALESCE(ROUND(AVG("Close Rate"), 2), 0.0) "Close Rate"
FROM final_data
GROUP BY 1,2
ORDER BY "Date" DESC
)

SELECT *
FROM tab 