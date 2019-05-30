
with filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT di.dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid = '{{ dpid }}' AND dp.tableau_secret = {{ dpsk }}
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
group by 1,2,3,4,5)

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
), 

expected_rates as (
SELECT percentile,
SUM(CASE WHEN metric = 'online_express_ratio' Then rate ELSE NULL END)  online_express_ratio,
SUM(CASE WHEN metric = 'online_express_to_order_ratio' Then rate ELSE NULL END)  online_express_to_order_ratio,
SUM(CASE WHEN metric = 'online_non_unlock_lead_conversion' Then rate ELSE NULL END)  online_non_unlock_lead_conversion,
SUM(CASE WHEN metric = 'online_service_plan_attach_rate' Then rate ELSE NULL END)  online_service_plan_attach_rate,
SUM(CASE WHEN metric = 'online_trade_attach_rate' Then rate ELSE NULL END)  online_trade_attach_rate,
SUM(CASE WHEN metric = 'online_close_rate' Then rate ELSE NULL END)  online_close_rate
FROM (
  SELECT *
  FROM get_percentile_ranking('online_express_ratio', 'online_express_ratio_percentile')
  UNION 
  SELECT *
  FROM get_percentile_ranking('online_express_to_order_ratio', 'online_express_to_order_ratio_percentile')
  UNION 
  SELECT *
  FROM get_percentile_ranking('online_non_unlock_lead_conversion', 'non_unlock_lead_conversion_percentile')
  UNION
  SELECT *
  FROM get_percentile_ranking('online_service_plan_attach_rate', 'online_service_plan_attach_rate_percentile')
  UNION
  SELECT *
  FROM get_percentile_ranking('online_trade_attach_rate', 'online_trade_attach_rate_percentile')
  UNION
  SELECT *
  FROM get_percentile_ranking('online_close_rate', 'online_close_rate_percentile')
) t
GROUP BY percentile
ORDER BY percentile


) 



, semifinal_data as (
select 
  dd.date::date as "Date"
, integration.dealer_group_name 
, dd.dpid
, dd.primary_make
, dd.dpsk
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
, LEAST(ROUND((et.online_express_visitors::numeric/dt.visitors::numeric), 2), 1.0) as "Online Express Ratio"
, LEAST(ROUND((op.online_prospects::numeric/et.online_express_visitors::numeric), 2), 1.0) as "Conversion to Online Prospect"
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

---
--FIX ME
---
left join roadster_salesforce.integration ON dd.dpid = integration.dpid
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)

,final_data as (
SELECT ---"Date"
"Dealership",
SUM(COALESCE("Dealer Visitors", 0.0)) "Dealer_Visitors", 
SUM(COALESCE("In-Store Shares", 0.0)) "In-Store Shares", 
SUM(COALESCE("Online Express Visitors", 0.0)) "Online Express Visitors", 
SUM(COALESCE("Online Express SRP Visitors", 0.0)) "Online Express SRP Visitors", 
SUM(COALESCE("Online Express VDP Visitors", 0.0)) "Online Express VDP Visitors", 
SUM(COALESCE("Online Prospects", 0.0)) "Online Prospects", 
SUM(COALESCE(instore_prospects, 0.0)) "In-Store-Prospects",
SUM(COALESCE("In-Store Orders", 0.0)) "In-Store-Orders",
SUM(COALESCE(online_orders, 0.0)) "Online Orders",
ROUND(AVG(COALESCE("Online Express Ratio", 0.0)), 2) "Online_Express_Ratio", 
ROUND(AVG(COALESCE("Conversion to Online Prospect", 0.0)), 2) "Conversion to Online Prospect"
FROM semifinal_data
GROUP BY 1
ORDER BY "Dealership" DESC
)

SELECT final_data.*, 
er.*, 
ROUND(online_express_ratio * "Dealer_Visitors",3) expected_express_visitors,
ROUND(online_express_to_order_ratio * "Online Express Visitors",3) expected_online_orders,
ROUND(online_non_unlock_lead_conversion * "Online Express Visitors",3) expected_non_unlock_lead_conversion, 
ROUND(online_service_plan_attach_rate * "Online Orders", 3) expected_service_plan_attach_rate,
ROUND(online_trade_attach_rate * "Online Orders",3) expected_trade_attach_rate, 
ROUND(online_close_rate * "Online Prospects", 3) expected_close_rate

FROM final_data
LEFT JOIN expected_rates er ON 1=1
ORDER BY "Dealership"

