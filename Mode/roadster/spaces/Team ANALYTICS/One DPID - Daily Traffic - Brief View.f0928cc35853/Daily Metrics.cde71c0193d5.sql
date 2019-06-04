
with date_dpid as (
select c.date, dp.dpid, dp.name, dp.tableau_secret as dpsk
from fact.d_cal_date c
cross join (
  select distinct dpid, tableau_secret, name from dealer_partners) dp
--  where dpid not like '%demo%')dp
LEFT JOIN public.custom_dealer_grouping cdg ON dp.dpid = cdg.dpid
where c.date >= (date_trunc('day', now()) - INTERVAL '61 days')
AND c.date <  (date_trunc('day',now()) - INTERVAL '1 days')
AND dp.name = '{{ dealer_name }}'
group by 1,2,3,4
)

,online_express_traffic as (
select
  date
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
  date
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
  date
, dpid
, dpsk
, sum(count) as online_express_vdp_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express VDP Traffic'
AND date >= (date_trunc('day', now()) - INTERVAL '61 days')
group by 1,2,3)

,online_prospects as (
select
  date
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
SELECT sold_date, dpid,
COUNT (DISTINCT CASE WHEN item_type = 'Sale' THEN vin ELSE NULL END) AS "ALL SALES",
COUNT (DISTINCT CASE WHEN item_type = 'Matched Sale' AND days_to_close_from_last_lead < 91 THEN vin ELSE NULL END) AS "MATCHED SALE"
FROM raw_sale_data
GROUP BY sold_date, dpid
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
SELECT cohort_date_utc "Date",
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
GROUP BY cohort_date_utc, dpid
)


select
  dd.date::date as "Date"
, dd.name as "Dealership"

,       CASE
           WHEN dd.name like '%Baierl%' THEN 'Baierl'
           ELSE 'Day'
       END AS "Brand"


, COALESCE(sdd."MATCHED SALE", 0) "Matched Sales w/i 90 Days"
, COALESCE(sdd."ALL SALES", 0) "All Sales"
, COALESCE(dt.visitors, 0) as "Dealer Visitors"
, COALESCE(et.online_express_visitors, 0) as "Online Express Visitors"
, COALESCE(online_express_srp_visitors, 0) as "Online Express SRP Visitors"
, COALESCE(online_express_vdp_visitors, 0) as "Online Express VDP Visitors"
, COALESCE(op.online_prospects, 0) as "Online Prospects"
, COALESCE((et.online_express_visitors::numeric/dt.visitors::numeric), 0) as "Online Express Ratio"
, COALESCE(ROUND((op.online_prospects::numeric/et.online_express_visitors::numeric), 2), 0) as "Conversion to Online Prospect"
, COALESCE("Service Plans Completed", 0) AS "Service Plans Completed"
, COALESCE("Credit Completed", 0) AS "Credit Completed"
, COALESCE("Trade-In Attached", 0) AS "Trade-In Attached"
, COALESCE("Service Plans Attached", 0) AS "Service Plans Attached"
, COALESCE("Deal Sheet Accepted", 0) AS "Deal Sheet Accepted"
, COALESCE("Order Submitted", 0) AS "Order Submitted"
, COALESCE("Trade-In Completed", 0) AS "Trade-In Completed"
, COALESCE("Accessories Completed", 0) AS "Accessories Completed"
, COALESCE("Accessories Attached", 0) AS "Accessories Attached"
, COALESCE("Final Deal Sent", 0) AS "Final Deal Sent"
from date_dpid dd
left join online_express_traffic et on et.date = dd.date and et.dpid = dd.dpid
left join fact.agg_daily_dealer_traffic dt on dt.dpid = dd.dpid and dt.date = dd.date
left join online_express_vdp_traffic vdp on vdp.date = dd.date and vdp.dpid = dd.dpid
left join online_express_srp_traffic srp on srp.date = dd.date and srp.dpid = dd.dpid
left join online_prospects op on op.dpid = dd.dpid and op.date = dd.date
LEFT JOIN sale_data_daily sdd ON dd.date = sdd.sold_date AND dd.dpid = sdd.dpid
LEFT JOIN pivot_orders_agg poa ON dd.date = poa."Date" AND dd.dpid = poa.dpid
---WHERE dd.date < ((SELECT MAX(date) FROM fact.d_cal_date) - INTERVAL '2 days')
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22
ORDER BY dd.date::date desc, dd.name desc
