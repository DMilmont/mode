with orders as (
SELECT
date_trunc('month', step_date_utc) dt,
dpid,
COUNT(
DISTINCT
CASE WHEN is_in_store iS TRUE THEN customer_email ELSE NULL END
) "In-Store Orders" ,
COUNT(
DISTINCT
CASE WHEN is_in_store <> TRUE THEN customer_email ELSE NULL END
) "Online Orders",
COUNT(
DISTINCT
CASE WHEN is_in_store iS TRUE THEN customer_email ELSE NULL END
) + 
COUNT(
DISTINCT
CASE WHEN is_in_store <> TRUE THEN customer_email ELSE NULL END
) "Total Orders"

FROM fact.f_prospect
WHERE item_type = 'Order Submitted'
AND dpid = '{{ dpid }}'
AND EXTRACT(DAY FROM step_date_utc) <= EXTRACT(DAY FROM NOW())
GROUP BY
date_trunc('month', step_date_utc),
dpid
ORDER BY 2,1
)

,prospects as (

  SELECT
  dpid,
  date_trunc('month', timestamp) dt,
  COUNT(
  DISTINCT
  CASE WHEN ls.in_store IS TRUE THEN u.email ELSE NULL END
  ) "In-Store Prospects",
  COUNT(
  DISTINCT
  CASE WHEN ls.in_store IS False THEN u.email ELSE NULL END
  ) "Online Prospects"
  FROM lead_submitted ls
  LEFT JOIN users u ON ls.user_id = u.id
  LEFT JOIN dealer_partners dp ON ls.dealer_partner_id = dp.id
  WHERE EXTRACT(DAY FROM timestamp) <= EXTRACT(DAY FROM NOW())
  AND dpid = '{{ dpid }}'
  GROUP BY 1,2

)

SELECT o.*,
"Online Prospects",
ROUND("Online Orders"::decimal / "Online Prospects", 3) "Order Ratio"
FROM orders o
LEFT JOIN prospects p ON o.dt = p.dt AND o.dpid = p.dpid











