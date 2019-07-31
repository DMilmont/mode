with order_status as (
  SELECT order_id, 'canceled' status
  FROM order_cancelled
  UNION 
  SELECT order_id, 'completed' status
  FROM order_completed

),

tab2 as (

SELECT 
'Prospects' title,
dpid,
name,
ls.timestamp ts_prospects,
extract(DAY from ls.timestamp) day_of_month,
to_char(ls.timestamp, 'Month YYYY') mth_yr,
to_char(ls.timestamp, 'DD Month YYYY') dt,
to_char(ls.timestamp, 'HH') hr,
ls.type,
ls.in_store,
ls.user_contact_dbid,
user_id,
u.first_name,
u.last_name,
u.email,
1 "exists",
a.first_name || ' ' || a.last_name agent_name,
regexp_replace(type, '([a-z])([A-Z])', '\1 \2','g') type_to_use,
CASE WHEN os.status IS NULL AND ls.order_id IS NOT NULL THEN 'Open'
ELSE initcap(os.status) END as order_status, 
CASE 
  WHEN ls.in_store = true THEN 'In-Store'
  ELSE 'Online' END AS instore_name,
  
'https://dealers.roadster.com/' || dpid || '/user_contacts/' || user_contact_dbid link_lead,

'https://dealers.roadster.com/' || dpid || '/orders/' || o.order_dbid  link_order
  
FROM lead_submitted ls
LEFT JOIN dealer_partners dp ON ls.dealer_partner_id = dp.id
LEFT JOIN users u ON ls.user_id = u.id
LEFT JOIN agents a ON ls.agent_id = a.id
LEFT JOIN orders o ON ls.order_id = o.id
LEFT JOIN order_status os ON ls.order_id = os.order_id
WHERE timestamp >= (date_trunc('month', now()) - '6 months'::interval)
AND dpid = '{{ dpid }}'
)

SELECT date_trunc('month', ts_prospects) dt,
SUM(CASE WHEN in_store = True THEN exists END) online,
SUM(CASE WHEN in_store <> True THEN exists END) in_store,
ROUND((SUM(CASE WHEN in_store = True THEN exists END)::decimal / SUM(exists))*100, 1)|| ' %' online_perc,
SUM(exists) total

FROM tab2
WHERE day_of_month <= EXTRACT(DAY FROM NOW())
GROUP BY date_trunc('month', ts_prospects)
ORDER BY date_trunc('month', ts_prospects)