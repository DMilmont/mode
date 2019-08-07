WITH plans_attach as (

SELECT
order_id,
sp.name,
sp.category,
price,
'Service Plan' "Type"
FROM plans sp

UNION

SELECT
order_id,
name,
category,
price,
'Accessory' "Type"
FROM accessories a

),

order_status as (
  SELECT order_id, 'canceled' status
  FROM order_cancelled
  UNION
  SELECT order_id, 'completed' status
  FROM order_completed

),

almost as (



SELECT
dpid,
CASE WHEN os.status IS NULL THEN 'Order Open' ELSE os.status END status,
o.id,
o.created_at,
o.in_store,
o.price car_price,
order_type,
SUM(
CASE WHEN "Type" = 'Service Plan' THEN 1 ELSE 0 END
) "Service Plan Attached",
SUM(
CASE WHEN "Type" = 'Accessory' THEN 1 ELSE 0 END
) "Accessory Attached"
FROM orders o
LEFT JOIN plans_attach pa ON o.id = pa.order_id
LEFT JOIN order_status os ON o.id = os.order_id
LEFT JOIN
(
SELECT DISTINCT order_id, dpid
FROM fact.f_prospect
WHERE cohort_date_utc > DATE_TRUNC('month', (now() - '3 months'::interval))

) t ON o.id = t.order_id

WHERE date_trunc('month', created_at) > date_trunc('month', (now() - '3 months'::interval))

GROUP BY
dpid,
CASE WHEN os.status IS NULL THEN 'Order Open' ELSE os.status END,
o.id,
o.created_at,
o.in_store,
o.price,
order_type

)
,almost_2 as (
SELECT
date_trunc('month', created_at) mth_yr, status, in_store, order_type,
AVG("Service Plan Attached")::decimal "Mean # of Service Plans",
AVG("Accessory Attached")::decimal "Mean # of Accessories"
FROM almost
GROUP BY date_trunc('month', created_at), status, in_store, order_type
ORDER BY mth_yr, status, in_store, order_type
)

SELECT
LEFT(mth_yr::text, 10) "Month & Year", 
CASE 
  WHEN status = 'canceled' THEN 'Order Canceled'
  WHEN status = 'completed' THEN 'Order Completed'
  ELSE status END as "Current Order Status", 
CASE WHEN in_store = false THEN 'In-Store'
ELSE 'Online' END AS "Order Location", 
'Accessories' "Type",
--ROUND("Mean # of Service Plans", 3) "Mean # of Service Plans",
ROUND("Mean # of Accessories", 3)  "Mean Value"
FROM almost_2
WHERE order_type <> 'StandaloneTrade'

UNION

SELECT
LEFT(mth_yr::text, 10) "Month & Year", 
CASE 
  WHEN status = 'canceled' THEN 'Order Canceled'
  WHEN status = 'completed' THEN 'Order Completed'
  ELSE status END as "Current Order Status", 
CASE WHEN in_store = false THEN 'In-Store'
ELSE 'Online' END AS "Order Location", 
'Service Plans' "Type",
ROUND("Mean # of Service Plans", 3) "Mean Value"
--ROUND("Mean # of Accessories", 3)  "Mean # of Accessories"
FROM almost_2
WHERE order_type <> 'StandaloneTrade'

