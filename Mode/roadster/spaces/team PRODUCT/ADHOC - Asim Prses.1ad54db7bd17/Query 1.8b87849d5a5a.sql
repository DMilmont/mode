with tab1 as (
SELECT timestamp, order_id, dealer_partner_id, user_id, agent_id, 'Sent' message_type
FROM public.message_sent ms
UNION 
SELECT timestamp, order_id, dealer_partner_id, user_id, agent_id, 'Received' message_type
FROM public.message_received
)

SELECT 
dpid, 
order_id, 
timestamp, 
a.email agent_email, 
u.first_name customer_first_name, 
u.last_name customer_last_name, 
message_type
FROM tab1 
LEFT JOIN dealer_partners dp ON tab1.dealer_partner_id = dp.id
LEFT JOIN agents a ON tab1.agent_id = a.id
LEFT JOIN users u ON tab1.user_id = u.id
WHERE timestamp >= DATE'2019-01-01'
ORDER BY dpid, order_id, timestamp

