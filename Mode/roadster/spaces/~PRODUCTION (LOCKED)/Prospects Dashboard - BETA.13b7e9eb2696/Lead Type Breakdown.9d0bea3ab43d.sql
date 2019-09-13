with order_status as (
  SELECT order_id, 'canceled' status
  FROM order_cancelled
  UNION 
  SELECT order_id, 'completed' status
  FROM order_completed

)

SELECT 
'Prospects' title,
dpid,
name,
ls.timestamp ts_prospects,
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
1 "Count",
a.first_name || ' ' || a.last_name agent_name,
CASE WHEN regexp_replace(type, '([a-z])([A-Z])', '\1 \2','g') = 'SATrade Started' THEN 'Stand Along Trade Started' ELSE regexp_replace(type, '([a-z])([A-Z])', '\1 \2','g') END type_to_use,
CASE WHEN os.status IS NULL AND ls.order_id IS NOT NULL THEN 'Open'
ELSE initcap(os.status) END as order_status, 
CASE 
  WHEN ls.in_store = true THEN 'In-Store'
  ELSE 'Online' END AS instore_name,
  
'https://dealers.roadster.com/' || dpid || '/user_contacts/' || user_contact_dbid link_lead,

'https://dealers.roadster.com/' || dpid || '/orders/' || o.order_dbid  link_order,

CASE WHEN 
to_char(date_trunc('month', ls.timestamp), 'Month YYYY') = '{{ Before }}' THEN 'Before'
ELSE 'After' END AS legend
  
FROM lead_submitted ls
LEFT JOIN dealer_partners dp ON ls.dealer_partner_id = dp.id
LEFT JOIN users u ON ls.user_id = u.id
LEFT JOIN agents a ON ls.agent_id = a.id
LEFT JOIN orders o ON ls.order_id = o.id
LEFT JOIN order_status os ON ls.order_id = os.order_id
WHERE 
(
date_trunc('month', ls.timestamp) = (date_trunc('month', now()) - '1 month'::interval)
)
AND 
dpid = '{{ dpid }}'
AND  tableau_secret = '{{ dpsk }}'
ORDER BY ls.timestamp desc
