WITH base_data as (

  SELECT
  dpid,
  date_trunc('month', timestamp) month_date,
  in_store,
  COUNT(DISTINCT distinct_id) ct_orders_mtd
  FROM order_steps os
  LEFT JOIN dealer_partners dp ON os.dealer_partner_id = dp.id
  LEFT JOIN (
    SELECT
    order_id,
    MIN(timestamp) min_timestamp
    FROM order_steps
    WHERE timestamp > date_trunc('month', now()) - '2 months'::interval
    GROUP BY 1
  ) t ON os.order_id = t.order_id
  LEFT JOIN orders o ON os.order_id = o.id
  WHERE timestamp > date_trunc('month', now()) - '2 months'::interval
  AND extract(day from timestamp) <= extract(day from now() AT time zone 'UTC')
  AND EXTRACT(month from min_timestamp) = EXTRACT(month from timestamp)
  AND dp.status = 'Live'
  AND dp.dpid = '{{ dpid }}'
  AND  tableau_secret = '{{ dpsk }}'
  GROUP BY 1, 2, 3
)

SELECT DISTINCT
bd.dpid,
bd.month_date,
COALESCE(SUM(CASE WHEN in_store = true THEN ct_orders_mtd ELSE NULL END), 0) "In-Store Orders",
COALESCE(SUM(CASE WHEN in_store = false THEN ct_orders_mtd ELSE NULL END), 0) "Online Orders",
COALESCE(SUM(ct_online_prospects), 0) "Online Prospects",
COALESCE(COALESCE(SUM(CASE WHEN in_store = true THEN ct_orders_mtd ELSE NULL END), 0) + COALESCE(SUM(CASE WHEN in_store = false THEN ct_orders_mtd ELSE NULL END), 0), 0) "Total Orders",
SUM(CASE WHEN in_store = false THEN ct_orders_mtd ELSE NULL END)::decimal / SUM(ct_online_prospects) "Order Ratio"
FROM base_data bd

LEFT JOIN (
      SELECT
      dpid,
      date_trunc('month', timestamp) month_date,
      COUNT(DISTINCT user_id) ct_online_prospects
      FROM lead_submitted ls
      LEFT JOIN dealer_partners dp ON ls.dealer_partner_id = dp.id
      WHERE
        in_store = false AND
        timestamp > date_trunc('month', now()) - '2 months'::interval
        AND extract(day from timestamp) <= extract(day from now() AT time zone 'UTC')
        AND dp.status = 'Live'
        AND dp.dpid = '{{ dpid }}'
        AND  tableau_secret = '{{ dpsk }}'
      GROUP BY 1, 2
) op ON bd.dpid = op.dpid AND bd.month_date = op.month_date
GROUP BY 1,2
