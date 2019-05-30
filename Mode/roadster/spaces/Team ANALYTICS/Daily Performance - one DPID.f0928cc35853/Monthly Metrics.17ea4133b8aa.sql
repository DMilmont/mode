
with date_dpid as (
select c.month_year, dp.dpid, dp.name, dp.tableau_secret as dpsk
from fact.d_cal_month c
cross join (
  select distinct dpid, tableau_secret, name from dealer_partners) dp
--  where dpid not like '%demo%')dp
LEFT JOIN public.custom_dealer_grouping cdg ON dp.dpid = cdg.dpid
where c.month_year >= (date_trunc('day', now()) - INTERVAL '61 days')
AND dp.name = '{{ dealer_name }}'
group by 1,2,3,4
)

,in_store_shares as (
SELECT date_trunc('month', cohort_date_utc) month_year,
      dpid,
      count(DISTINCT f_prospect.customer_email) "In-Store Shares"
FROM fact.f_prospect
WHERE item_type = 'SharedExpressVehicle'
AND source = 'Lead Type'
AND is_in_store = True
GROUP BY date_trunc('month', cohort_date_utc), dpid
)

,online_express_traffic as (
select
  date_trunc('month', date) month_year
, dpid
, dpsk
, sum(count) online_express_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express Traffic'
and date >= (date_trunc('day', now()) - INTERVAL '61 days')
group by 1,2,3
    )

,online_express_srp_traffic as (
select
  date_trunc('month', date) month_year
, dpid
, dpsk
, sum(count) as online_express_srp_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express SRP Traffic'
AND date >= (date_trunc('day', now()) - INTERVAL '61 days')
group by 1,2,3
)


,online_express_vdp_traffic as (
select
  date_trunc('month', date) month_year
, dpid
, dpsk
, sum(count) as online_express_vdp_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express VDP Traffic'
AND date >= (date_trunc('day', now()) - INTERVAL '61 days')
group by 1,2,3)

,online_prospects as (
select
  date_trunc('month', date) month_year
, dpid
, dpsk
, sum(count) online_prospects
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Prospects'
AND date >= (date_trunc('day', now()) - INTERVAL '61 days')
group by 1,2,3),

raw_sale_data as (
SELECT DISTINCT sold_date::date, item_type, dpid, vin, days_to_close_from_last_lead
FROM fact.f_sale
WHERE sold_date >= (date_trunc('day', now()) - INTERVAL '61 days')
),

sale_data_daily as (
SELECT date_trunc('month', sold_date) month_year, dpid,
COUNT (DISTINCT CASE WHEN item_type = 'Sale' THEN vin ELSE NULL END) AS "ALL SALES",
COUNT (DISTINCT CASE WHEN item_type = 'Matched Sale' AND days_to_close_from_last_lead < 91 THEN vin ELSE NULL END) AS "MATCHED SALE"
FROM raw_sale_data
GROUP BY date_trunc('month', sold_date), dpid
), 

base_order_data as (
    SELECT cohort_date_utc, dpid, item_type, order_step_id
    FROM fact.f_prospect
    WHERE source = 'Order Step'
),

pivot_orders as (
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
SELECT date_trunc('month', cohort_date_utc) month_year,
       dpid,
       SUM("Service Plans Completed") AS "Service Plans Completed",
        SUM("Credit Completed") AS "Credit Completed",
        SUM("Trade-In Attached") AS "Trade-In Attached",
        SUM("Service Plans Attached") AS "Service Plans Attached",
        SUM("Deal Sheet Accepted") AS "Deal Sheet Accepted",
        SUM("Order Submitted") AS "Order Submitted",
        SUM("Trade-In Completed") AS "Trade-In Completed",
        SUM("Accessories Completed") AS "Accessories Completed",
        SUM("Accessories Attached") AS "Accessories Attached",
        SUM("Final Deal Sent") AS "Final Deal Sent"
FROM pivot_orders
GROUP BY date_trunc('month', cohort_date_utc), dpid
)


select
  to_char(dd.month_year, 'Month') || ' ' || to_char(dd.month_year, 'YYYY') as "Month"

,       CASE
           WHEN dd.name like '%Baierl%' THEN 'Baierl'
           ELSE 'Day'
       END AS "Brand"

, dd.name as "Dealership"
, COALESCE(dt.visitors, 0) as "Dealer Visitors"
, round(COALESCE((et.online_express_visitors::numeric/dt.visitors::numeric), 0),3) as "Online Express Ratio"
, COALESCE(et.online_express_visitors, 0) as "Online Express Visitors"
, COALESCE(online_express_srp_visitors, 0) as "Online Express SRP Visitors"
, COALESCE(online_express_vdp_visitors, 0) as "Online Express VDP Visitors"
, COALESCE(ROUND((op.online_prospects::numeric/et.online_express_visitors::numeric), 3), 0) as "Conversion to Online Prospect"
, COALESCE(op.online_prospects, 0) as "Online Prospects"
, COALESCE(iss."In-Store Shares", 0) AS "In-Store Shares"
, COALESCE("Order Submitted", 0) AS "Orders"
, COALESCE("Deal Sheet Accepted", 0) AS "Deal Sheet Accepted"
, COALESCE("Trade-In Completed", 0) AS "Trade-In Completed"
, COALESCE("Trade-In Attached", 0) AS "Trade-In Attached"
, COALESCE("Credit Completed", 0) AS "Credit Completed"
, COALESCE("Accessories Completed", 0) AS "Accessories Completed"
, COALESCE("Accessories Attached", 0) AS "Accessories Attached"
, COALESCE("Service Plans Attached", 0) AS "Service Plans Attached"
, COALESCE("Service Plans Completed", 0) AS "Service Plans Completed"
, COALESCE("Final Deal Sent", 0) AS "Final Deal Sent"
, COALESCE(sdd."MATCHED SALE", 0) "Matched Sales w/i 90 Days"
, COALESCE(sdd."ALL SALES", 0) "All Sales"
, dd.month_year::date as "Date"

from date_dpid dd
left join online_express_traffic et on et.month_year = dd.month_year and et.dpid = dd.dpid
left join (
  SELECT dpid, date_trunc('month', date) month_year, SUM(visitors) visitors
  FROM fact.agg_daily_dealer_traffic
  GROUP BY dpid, date_trunc('month', date)
  ) dt on dt.dpid = dd.dpid and dt.month_year = dd.month_year
left join online_express_vdp_traffic vdp on vdp.month_year = dd.month_year and vdp.dpid = dd.dpid
left join online_express_srp_traffic srp on srp.month_year = dd.month_year and srp.dpid = dd.dpid
left join online_prospects op on op.dpid = dd.dpid and op.month_year = dd.month_year
LEFT JOIN sale_data_daily sdd ON dd.month_year = sdd.month_year AND dd.dpid = sdd.dpid
LEFT JOIN pivot_orders_agg poa ON dd.month_year = poa.month_year AND dd.dpid = poa.dpid
LEFT JOIN in_store_shares iss ON dd.month_year = iss.month_year AND dd.dpid = iss.dpid
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
ORDER BY dd.month_year::date desc, "Brand" ASC, "Online Express Visitors" desc

