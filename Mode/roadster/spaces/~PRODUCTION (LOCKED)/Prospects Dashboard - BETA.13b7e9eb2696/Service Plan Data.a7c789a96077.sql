with data as (
SELECT
DISTINCT
date_trunc('month' :: text, (po.cohort_date_utc) :: timestamp with time zone) AS month_year,
po.dpid,
order_dbid,
po.is_in_store,
a.name,
a.category,
a.price,
'Accessory' "Type",
customer_email
FROM fact.f_prospect po
LEFT JOIN accessories a ON ((a.order_id = po.order_id))
LEFT JOIN orders o ON po.order_id = o.id
WHERE dpid = '{{ dpid }}'
 AND dpsk = '{{ dpsk }}'
AND a.price IS NOT NULL
AND po.item_type = 'Order Submitted'
AND po.source = 'Order Step'
AND cohort_date_utc >= (date_trunc('month', now()) - '6 months'::interval)

UNION

SELECT
DISTINCT
date_trunc('month' :: text, (po.cohort_date_utc) :: timestamp with time zone) AS month_year,
po.dpid,
order_dbid,
po.is_in_store,
sp.name,
sp.category,
sp.price,
'Service Plan' "Type",
customer_email
FROM (fact.f_prospect po
JOIN plans sp ON ((sp.order_id = po.order_id)))
LEFT JOIN orders o ON po.order_id = o.id
WHERE dpid = '{{ dpid }}'
 AND dpsk = '{{ dpsk }}'
AND category IS NOT NULL
AND po.item_type = 'Order Submitted'
AND po.source = 'Order Step'
AND cohort_date_utc >= (date_trunc('month', now()) - '6 months'::interval)
)

SELECT data.*, 
(month_year + '1 day'::interval) mth_yr,
1 exists_now,
CASE WHEN is_in_store = true THEN 'In-Store' ELSE 'Online' END "Order Location",
'https://dealers.roadster.com/' || dpid || '/orders/' || order_dbid "Order"

FROM data
ORDER BY month_year desc