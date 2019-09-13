with order_status as (
  SELECT order_id, 'canceled' status
  FROM order_cancelled
  UNION
  SELECT order_id, 'completed' status
  FROM order_completed

),

max_order_steps as (
 SELECT os.*
 FROM order_steps os
 INNER JOIN (
     SELECT order_id, user_id, max(timestamp) mx
     FROM order_steps
     GROUP BY 1, 2
  ) t ON os.order_id = t.order_id AND os.user_id = t.user_id AND os.timestamp = t.mx
)

, base_orders as (
 SELECT max_order_steps.*,
 date_trunc('month', max_order_steps.timestamp) month_date,
 EXTRACT(day from max_order_steps.timestamp) day_of_month,
 dpid,
 o.in_store,
 CASE WHEN order_status.status IS NULL THEN 'Open' ELSE initcap(order_status.status) END current_order_status
 FROM max_order_steps
 LEFT JOIN order_status ON max_order_steps.order_id = order_status.order_id
 LEFT JOIN dealer_partners dp ON max_order_steps.dealer_partner_id = dp.id
 LEFT JOIN orders o ON max_order_steps.order_id = o.id
 WHERE dpid = '{{ dpid }}'
 AND   tableau_secret = '{{ dpsk }}'
 ORDER BY timestamp desc
)


,prospect_base as (
    SELECT
    'Prospects' title,
    dpid,
    tableau_secret,
    name,
    ls.timestamp ts_prospects,
    extract(DAY from ls.timestamp) day_of_month,
    ls.in_store,
    u.distinct_id,
    1 "exists"
    FROM lead_submitted ls
    LEFT JOIN dealer_partners dp ON ls.dealer_partner_id = dp.id
    LEFT JOIN orders o ON ls.order_id = o.id
    LEFT JOIN users u ON ls.user_id = u.id
    WHERE timestamp >= (date_trunc('month', now()) - '6 months'::interval)
    AND dpid = '{{ dpid }}'
    AND tableau_secret = '{{ dpsk }}'
)

, prospect_ct as (
    SELECT date_trunc('month', ts_prospects) dt,
    dpid,
    COUNT(CASE WHEN in_store = True THEN distinct_id END) in_store,
    COUNT(CASE WHEN in_store <> True THEN distinct_id END) online,
    ROUND((COUNT(CASE WHEN in_store = True THEN distinct_id END)::decimal / COUNT(distinct_id))*100, 1)|| ' %' online_perc,
    COUNT(distinct_id) total
    FROM prospect_base
    WHERE day_of_month <= EXTRACT(DAY FROM NOW())
    AND dpid = '{{ dpid }}'
    AND tableau_secret = '{{ dpsk }}'
    GROUP BY date_trunc('month', ts_prospects), dpid
    ORDER BY date_trunc('month', ts_prospects)
)



SELECT
o.dpid,
o.month_date,
o."In-Store Orders",
o."Online Orders",
p.online "Online Prospects",
o."Online Orders" + o."In-Store Orders" "Total Orders",
COALESCE(COALESCE(o."Online Orders", 0)::decimal/ p.online, 0) "Order Ratio"
FROM (
    SELECT
    bo.dpid,
    bo.month_date,
    COALESCE(COUNT(CASE WHEN bo.in_store = true THEN distinct_id ELSE NULL END), 0) "In-Store Orders",
    COALESCE(COUNT(CASE WHEN bo.in_store = false THEN distinct_id ELSE NULL END), 0) "Online Orders"
    FROM base_orders bo
    LEFT JOIN prospect_ct pct ON bo.month_date = pct.dt AND bo.dpid = pct.dpid
    WHERE day_of_month <= EXTRACT(day from now() AT TIME ZONE 'UTC')
    AND current_order_status <> 'Canceled'
    GROUP BY 1,2
) o
LEFT JOIN (
  SELECT
  dt,
  dpid,
  online
  FROM prospect_ct
) p ON o.dpid = p.dpid AND o.month_date = p.dt
ORDER BY o.month_date

