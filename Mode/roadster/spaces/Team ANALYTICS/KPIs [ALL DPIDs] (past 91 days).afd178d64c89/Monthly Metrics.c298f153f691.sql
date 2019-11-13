-- Returns first 100 rows from fact.f_prospect
SELECT * FROM fact.f_prospect LIMIT 100;



with cdk_api as (
SELECT dp.dpid,
       case when properties -> 'cdk_extract_id' <> 'null' then 'CDK API' else '' end AS "cdk_api"
FROM public.dealer_partner_properties dpp
left join public.dealer_partners dp ON dp.id = dpp.dealer_partner_id
WHERE date > (date_trunc('day', now()) - INTERVAL '1 day')
)


,date_dpid as (
select DISTINCT 'Past 91 Days' month_year, dp.dpid, sf.status, 
dp.status dp_status, sf.success_manager, sf.actual_live_date, sf.dealer_group, dp.name, dp.tableau_secret as dpsk
FROM dealer_partners dp
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
where 
(sf.status = 'Live' or dp.status = 'Live')

)

,in_store_shares as (
SELECT 'Past 91 Days' month_year,
      dpid,
      count( f_prospect.customer_email) "In-Store Shares"
FROM fact.f_prospect
WHERE item_type = 'SharedExpressVehicle'
AND source = 'Lead Type'
AND is_in_store = True
and cohort_date_utc > now() - '91 days'::interval 
GROUP BY 1,2
)

,online_express_traffic as (
select
'Past 91 Days' month_year
, dpid
, dpsk
, sum(count) online_express_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express Traffic'
and date >= (date_trunc('day', now()) - INTERVAL '91 days')
group by 1,2,3
    )

,online_express_srp_traffic as (
select
'Past 91 Days' month_year
, dpid
, dpsk
, sum(count) as online_express_srp_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express SRP Traffic'
AND date >= (date_trunc('day', now()) - INTERVAL '31 days')
group by 1,2,3
)


,online_express_vdp_traffic as (
select
'Past 91 Days' month_year
, dpid
, dpsk
, sum(count) as online_express_vdp_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express VDP Traffic'
AND date >= (date_trunc('day', now()) - INTERVAL '91 days')
group by 1,2,3
)

,online_prospects as (
select
'Past 91 Days' month_year
, dpid
, dpsk
, sum(count) online_prospects
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Prospects'
AND date >= (date_trunc('day', now()) - INTERVAL '91 days')
group by 1,2,3
)

, in_store_prospects as (
  SELECT 'Past 91 Days' month_year,
        f_prospect.dpid,
        f_prospect.dpsk,
        'In-Store Prospects' :: text                AS type,
        count(DISTINCT f_prospect.customer_email) AS sum_in_store_prospects
 FROM fact.f_prospect
 WHERE ((f_prospect.cohort_date_utc >= date_trunc('month' :: text, (CURRENT_DATE - '91 days' :: interval))) 
             AND (f_prospect.is_in_store IS TRUE))
 GROUP BY 1,2,3,4

),

raw_sale_data as (
SELECT DISTINCT sold_date::date, item_type, dpid, vin, days_to_close_from_last_lead
FROM fact.f_sale
WHERE sold_date >= (date_trunc('day', now()) - INTERVAL '91 days')
)

,sale_data_daily as (
SELECT 'Past 91 Days' month_year
, dpid,
COUNT (DISTINCT CASE WHEN item_type = 'Sale' THEN vin ELSE NULL END) AS "ALL SALES",
COUNT (DISTINCT CASE WHEN item_type = 'Matched Sale' AND days_to_close_from_last_lead < 91 THEN vin ELSE NULL END) AS "MATCHED SALE"
FROM raw_sale_data
GROUP BY 1,2
)

,base_order_data as (
    SELECT cohort_date_utc, dpid, item_type, order_step_id, is_in_store
    FROM fact.f_prospect
    WHERE source = 'Order Step'
    AND cohort_date_utc >= (date_trunc('day', now()) - INTERVAL '91 days')
)

,pivot_orders as (
      SELECT base_order_data.*,
             CASE WHEN item_type = 'Service Plans Completed' THEN 1 ELSE 0 END AS "Service Plans Completed",
             CASE WHEN item_type = 'Credit Completed' THEN 1 ELSE 0 END        AS "Credit Completed",
             CASE WHEN item_type = 'Trade-In Attached' THEN 1 ELSE 0 END       AS "Trade-In Attached",
             CASE WHEN item_type = 'Service Plans Attached' THEN 1 ELSE 0 END  AS "Service Plans Attached",
             CASE WHEN item_type = 'Deal Sheet Accepted' THEN 1 ELSE 0 END     AS "Deal Sheet Accepted",
             CASE WHEN item_type = 'Order Submitted' THEN 1 ELSE 0 END         AS "Order Submitted",
             CASE WHEN item_type = 'Trade-In Completed' THEN 1 ELSE 0 END      AS "Trade-In Completed",
             CASE WHEN item_type = 'Accessories Completed' THEN 1 ELSE 0 END   AS "Accessories Completed",
             CASE WHEN item_type = 'Accessories Attached' THEN 1 ELSE 0 END    AS "Accessories Attached",
             CASE WHEN item_type = 'Final Deal Sent' THEN 1 ELSE 0 END         AS "Final Deal Sent"
      FROM base_order_data
  ), 
  
pivot_orders_agg as (
SELECT 'Past 91 Days' month_year,
       dpid,
       SUM("Service Plans Completed") AS "Service Plans Completed",
        SUM("Credit Completed") AS "Credit Completed",
        SUM("Trade-In Attached") AS "Trade-In Attached",
        SUM("Service Plans Attached") AS "Service Plans Attached",
        SUM("Deal Sheet Accepted") AS "Deal Sheet Accepted",
        SUM(case when is_in_store = true then "Order Submitted" else null end ) AS "Online Orders Submitted",
        SUM(case when is_in_store = false then "Order Submitted" else null end ) AS "InStore Orders Submitted",
        SUM("Trade-In Completed") AS "Trade-In Completed",
        SUM("Accessories Completed") AS "Accessories Completed",
        SUM("Accessories Attached") AS "Accessories Attached",
        SUM("Final Deal Sent") AS "Final Deal Sent"
FROM pivot_orders
GROUP BY 1,2
)


select
DISTINCT 
COALESCE(to_char(rank_no_dup,'000'), 'too new') as "Roadster Online Rank"
, dd.name as "Dealership"
, dd.dealer_group as "Dealer Group"
, dd.status as "SF Status"
, dd.dp_status as "DA Status"
, dd.success_manager
, dp.primary_make as "Primary Make"
, to_char(dd.actual_live_date,'yyyy_mm_dd') as "SF Go Live"
, cdk_api
--, dpp.properties ->> 'crm_vendor' "Dealer Admin CRM"
, COALESCE(sdd."MATCHED SALE", 0) "Matched Sales"
, COALESCE(sdd."ALL SALES", 0) "All Sales"
, COALESCE(dt.visitors, 0) as "Dealer Visitors"
, round(COALESCE((et.online_express_visitors::numeric/dt.visitors::numeric), 0),3) as "Online Express Ratio"
, COALESCE(et.online_express_visitors, 0) as "Online Express Visitors"
, COALESCE(online_express_srp_visitors, 0) as "Online Express SRP Visitors"
, COALESCE(online_express_vdp_visitors, 0) as "Online Express VDP Visitors"
, dp.price_unlock_mode
, COALESCE(ROUND((op.online_prospects::numeric/et.online_express_visitors::numeric), 3), 0) as "Conversion to Online Prospect"
, COALESCE(op.online_prospects, 0) as "Online Prospects"
, COALESCE(isp.sum_in_store_prospects, 0) as "In-Store Prospects"
--, COALESCE(iss."In-Store Shares", 0) AS "In-Store Shares"
,COALESCE(sor."Agent Shares",0) as "Agent Shares"
,COALESCE(sor."Shares Opened",0) as "Shares Opened"
, COALESCE(sor."Shares Opened %",0) as "Shares Open Rate"
,COALESCE(sor."Shares Clicked",0) as "Shares Clicked"
, COALESCE(sor."Shares Clicked %",0) as "Shares Click Thru Rate"
, COALESCE("Online Orders Submitted",0) + coalesce("InStore Orders Submitted", 0) AS "Total Orders"
, COALESCE("Online Orders Submitted", 0) AS "Online Orders"
, COALESCE("InStore Orders Submitted", 0) AS "InStore Orders"
, COALESCE("Deal Sheet Accepted", 0) AS "Deal Sheet Accepted"
, COALESCE("Trade-In Completed", 0) AS "Trade-In Completed"
, COALESCE("Trade-In Attached", 0) AS "Trade-In Attached"
, COALESCE("Credit Completed", 0) AS "Credit Completed"
, COALESCE("Accessories Completed", 0) AS "Accessories Completed"
, COALESCE("Accessories Attached", 0) AS "Accessories Attached"
, COALESCE("Service Plans Attached", 0) AS "Service Plans Attached"
, COALESCE("Service Plans Completed", 0) AS "Service Plans Completed"
, COALESCE("Final Deal Sent", 0) AS "Final Deal Sent"
, dd.month_year
from date_dpid dd
left join online_express_traffic et on et.month_year = dd.month_year and et.dpid = dd.dpid
left join (
  SELECT dpid,'Past 91 Days' month_year, SUM(visitors) visitors
  FROM fact.agg_daily_dealer_traffic
  WHERE date  >= (date_trunc('day', now()) - INTERVAL '91 days')
  GROUP BY 1,2
  ) dt on dt.dpid = dd.dpid and dt.month_year = dd.month_year
left join cdk_api ca on ca.dpid = dd.dpid
LEFT JOIN dealer_partners dp  ON dd.dpid = dp.dpid
left join public.dealer_partner_properties dpp on dpp.dealer_partner_id = dp.id
left join online_express_vdp_traffic vdp on vdp.month_year = dd.month_year and vdp.dpid = dd.dpid
left join online_express_srp_traffic srp on srp.month_year = dd.month_year and srp.dpid = dd.dpid
left join online_prospects op on op.dpid = dd.dpid and op.month_year = dd.month_year
LEFT JOIN sale_data_daily sdd ON dd.month_year = sdd.month_year AND dd.dpid = sdd.dpid
LEFT JOIN pivot_orders_agg poa ON dd.month_year = poa.month_year AND dd.dpid = poa.dpid
LEFT JOIN in_store_shares iss ON dd.month_year = iss.month_year AND dd.dpid = iss.dpid
LEFT JOIN in_store_prospects isp ON dd.month_year = isp.month_year AND dd.dpid = isp.dpid
LEFT JOIN report_layer.vw_share_open_rate_past_30 sor on dd.month_year=sor.ddate and dd.dpid= sor.dpid
LEFT JOIN (
  SELECT dpid, rank_no_dup
FROM fact.f_benchmark
WHERE time_frame = '3 month'
AND insert_date = (SELECT max(insert_date) FROM fact.f_benchmark WHERE time_frame = '3 month')
) rankings ON dd.dpid = rankings.dpid
ORDER BY 1
