with base_order_ids as (
  
    SELECT dpid, customer_email, MAX(order_id) order_id
    FROM fact.f_prospect
    WHERE cohort_date_utc <= '{{ end_date }}'
      AND cohort_date_utc >= '{{ start_date}}'
      AND source = 'Order Step'
    GROUP BY dpid, customer_email

), 

base_orders as (
SELECT DISTINCT fp.cohort_date_utc, fp.dpid, fp.customer_email, fp.order_id, 1 "Order Submitted"
FROM fact.f_prospect fp
INNER JOIN base_order_ids ON fp.order_id = base_order_ids.order_id
            
),

order_details as (
SELECT *
FROM crosstab(
'SELECT order_id, item_type, 1 "value"
        FROM fact.f_prospect
        WHERE source = ''Order Step'' and item_type <> ''Order Submitted''
        AND cohort_date_utc <= ''{{ end_date }}''
      AND cohort_date_utc >= ''{{ start_date}}''
        ORDER BY order_id, item_type',
$$VALUES ('Accessories Attached'::text),	('Accessories Completed'::text),	('Credit Completed'::text),
    ('Deal Sheet Accepted'::text),	('Final Deal Sent'::text),	('Service Plans Attached'::text),
    ('Service Plans Completed'::text),	('Trade-In Attached'::text),	('Trade-In Completed'::text)$$
) as ct("order_id_details" int, "Accessories Attached" int, "Accessories Completed" int, "Credit Completed" int,
"Deal Sheet Accepted" int, "Final Deal Sent" int, "Service Plans Attached" int,
"Service Plans Completed" int, "Trade-In Attached" int, "Trade-In Completed" int)
),

final_data_summed as (
SELECT
cohort_date_utc,
dpid,
COALESCE(SUM("Order Submitted"),0) "Order Submitted",
COALESCE(SUM("Accessories Attached"),0) "Accessories Attached",
COALESCE(SUM("Accessories Completed"),0) "Accessories Completed",
COALESCE(SUM("Credit Completed"),0) "Credit Completed",
COALESCE(SUM("Deal Sheet Accepted"),0) "Deal Sheet Accepted",
COALESCE(SUM("Final Deal Sent"),0) "Final Deal Sent",
COALESCE(SUM("Service Plans Attached"),0) "Service Plans Attached",
COALESCE(SUM("Service Plans Completed"),0) "Service Plans Completed",
COALESCE(SUM("Trade-In Attached"),0) "Trade-In Attached",
COALESCE(SUM("Trade-In Completed"),0) "Trade-In Completed",
COALESCE(ROUND( SUM("Accessories Attached") ::decimal / SUM("Order Submitted"), 2),0) "Accessories Attached Rate",
COALESCE(ROUND( SUM("Accessories Completed") ::decimal / SUM("Order Submitted"), 2),0) "Accessories Completed Rate",
COALESCE(ROUND( SUM("Credit Completed") ::decimal / SUM("Order Submitted"), 2),0) "Credit Completed Rate",
COALESCE(ROUND( SUM("Deal Sheet Accepted") ::decimal / SUM("Order Submitted"), 2),0) "Deal Sheet Accepted Rate",
COALESCE(ROUND( SUM("Final Deal Sent") ::decimal / SUM("Order Submitted"), 2),0) "Final Deal Sent Rate",
COALESCE(ROUND( SUM("Service Plans Attached") ::decimal / SUM("Order Submitted"), 2),0) "Service Plans Attached Rate",
COALESCE(ROUND( SUM("Service Plans Completed") ::decimal / SUM("Order Submitted"), 2),0) "Service Plans Completed Rate",
COALESCE(ROUND( SUM("Trade-In Attached") ::decimal / SUM("Order Submitted"), 2),0) "Trade-In Attached Rate",
COALESCE(ROUND( SUM("Trade-In Completed") ::decimal / SUM("Order Submitted"), 2),0) "Trade-In Completed Rate"
FROM base_orders
LEFT JOIN order_details ON base_orders.order_id = order_details.order_id_details
GROUP BY cohort_date_utc, dpid
ORDER BY cohort_date_utc, dpid
),

filter_for_dpids as (
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
and dealer_group <> dp.name
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
where c.date <= '{{ end_date }}'
      AND c.date >= '{{ start_date}}'
group by 1,2,3,4,5),


almost_final_data as (
SELECT
dd.name "Dealership", 
dd.date::date ,
COALESCE("Order Submitted",0) "Order Submitted",
COALESCE("Accessories Attached",0) "Accessories Attached",
COALESCE("Accessories Completed",0) "Accessories Completed",
COALESCE("Credit Completed",0) "Credit Completed",
COALESCE("Deal Sheet Accepted",0) "Deal Sheet Accepted",
COALESCE("Final Deal Sent",0) "Final Deal Sent",
COALESCE("Service Plans Attached",0) "Service Plans Attached",
COALESCE("Service Plans Completed",0) "Service Plans Completed",
COALESCE("Trade-In Attached",0) "Trade-In Attached",
COALESCE("Trade-In Completed",0) "Trade-In Completed",
COALESCE("Accessories Attached Rate", 0) "Accessories Attached Rate",
COALESCE("Accessories Completed Rate", 0) "Accessories Completed Rate",
COALESCE("Credit Completed Rate", 0) "Credit Completed Rate",
COALESCE("Deal Sheet Accepted Rate", 0) "Deal Sheet Accepted Rate",
COALESCE("Final Deal Sent Rate", 0) "Final Deal Sent Rate",
COALESCE("Service Plans Attached Rate", 0) "Service Plans Attached Rate",
COALESCE("Service Plans Completed Rate", 0) "Service Plans Completed Rate",
COALESCE("Trade-In Attached Rate", 0) "Trade-In Attached Rate",
COALESCE("Trade-In Completed Rate", 0) "Trade-In Completed Rate"
FROM date_dpid dd
LEFT JOIN final_data_summed fds ON dd.dpid = fds.dpid AND dd.date = fds.cohort_date_utc
)

SELECT 
"Dealership", 
AVG("Deal Sheet Accepted") "Deal Sheet Accepted", 
AVG("Trade-In Completed") "Trade-In Completed",
AVG("Credit Completed") "Credit Completed" ,
AVG("Service Plans Completed") "Service Plans Completed", 
AVG("Accessories Completed Rate") "Accessories Completed Rate", 
AVG("Final Deal Sent Rate") "Final Deal Sent Rate" 
FROM almost_final_data
GROUP BY 1
