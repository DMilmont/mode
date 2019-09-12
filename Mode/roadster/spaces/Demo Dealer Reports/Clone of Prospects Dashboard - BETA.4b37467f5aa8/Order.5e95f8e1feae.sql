with order_status as (
  SELECT order_id, 'canceled' status
  FROM order_cancelled
  UNION 
  SELECT order_id, 'completed' status
  FROM order_completed

),

order_steps as (
 SELECT (order_submitted.order_step_dbid) :: text AS order_step_id,
         'Order Submitted' :: text                 AS "Item Type",
         order_submitted."timestamp",
         order_submitted.order_id,
         order_submitted.user_id,
         order_submitted.dealer_partner_id,
         order_submitted.duration,
         order_submitted.is_final
         ,agent_id,
         100                                       AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((order_submitted order_submitted
      JOIN users b ON ((order_submitted.user_id = b.id)))
      JOIN orders c ON ((order_submitted.order_id = c.id)))
  UNION ALL
  SELECT (deal_sheet_sent.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Sent' :: text                 AS "Item Type",
         deal_sheet_sent."timestamp",
         deal_sheet_sent.order_id,
         deal_sheet_sent.user_id,
         deal_sheet_sent.dealer_partner_id,
         deal_sheet_sent.duration,
         deal_sheet_sent.is_final
         ,agent_id,
         200                                       AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((deal_sheet_sent deal_sheet_sent
      JOIN users b ON ((deal_sheet_sent.user_id = b.id)))
      JOIN orders c ON ((deal_sheet_sent.order_id = c.id)))
  UNION ALL
  SELECT (deal_sheet_accepted.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Accepted' :: text                 AS "Item Type",
         deal_sheet_accepted."timestamp",
         deal_sheet_accepted.order_id,
         deal_sheet_accepted.user_id,
         deal_sheet_accepted.dealer_partner_id,
         deal_sheet_accepted.duration,
         deal_sheet_accepted.is_final
         ,agent_id,
         300                                           AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((deal_sheet_accepted
      JOIN users b ON ((deal_sheet_accepted.user_id = b.id)))
      JOIN orders c ON ((deal_sheet_accepted.order_id = c.id)))
  UNION ALL
  SELECT (credit_completed.order_step_dbid) :: text AS order_step_id,
         'Credit Completed' :: text                 AS "Item Type",
         credit_completed."timestamp",
         credit_completed.order_id,
         credit_completed.user_id,
         credit_completed.dealer_partner_id,
         credit_completed.duration,
         credit_completed.is_final
         ,agent_id,
         400                                        AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((credit_completed
      JOIN users b ON ((credit_completed.user_id = b.id)))
      JOIN orders c ON ((credit_completed.order_id = c.id)))
  UNION ALL
  SELECT (service_plans_completed.order_step_dbid) :: text AS order_step_id,
         'Service Plans Completed' :: text                 AS "Item Type",
         service_plans_completed."timestamp",
         service_plans_completed.order_id,
         service_plans_completed.user_id,
         service_plans_completed.dealer_partner_id,
         service_plans_completed.duration,
         service_plans_completed.is_final
         ,agent_id,
         500                                               AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((service_plans_completed
      JOIN users b ON ((service_plans_completed.user_id = b.id)))
      JOIN orders c ON ((service_plans_completed.order_id = c.id)))
  UNION ALL
  SELECT (accessories_completed.order_step_dbid) :: text AS order_step_id,
         'Accessories Completed' :: text                 AS "Item Type",
         accessories_completed."timestamp",
         accessories_completed.order_id,
         accessories_completed.user_id,
         accessories_completed.dealer_partner_id,
         accessories_completed.duration,
         accessories_completed.is_final
         ,agent_id,
         501                                             AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((accessories_completed
      JOIN users b ON ((accessories_completed.user_id = b.id)))
      JOIN orders c ON ((accessories_completed.order_id = c.id)))
  UNION ALL
  SELECT (final_deal_sent.order_step_dbid) :: text AS order_step_id,
         'Final Deal Sent' :: text                 AS "Item Type",
         final_deal_sent."timestamp",
         final_deal_sent.order_id,
         final_deal_sent.user_id,
         final_deal_sent.dealer_partner_id,
         final_deal_sent.duration,
         final_deal_sent.is_final
         ,agent_id,
         600                                       AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((final_deal_sent
      JOIN users b ON ((final_deal_sent.user_id = b.id)))
      JOIN orders c ON ((final_deal_sent.order_id = c.id)))
  UNION ALL
  SELECT (final_deal_accepted.order_step_dbid) :: text AS order_step_id,
         'Final Deal Accepted' :: text                 AS "Item Type",
         final_deal_accepted."timestamp",
         final_deal_accepted.order_id,
         final_deal_accepted.user_id,
         final_deal_accepted.dealer_partner_id,
         final_deal_accepted.duration,
         final_deal_accepted.is_final
         ,agent_id,
         700                                           AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((final_deal_accepted
      JOIN users b ON ((final_deal_accepted.user_id = b.id)))
      JOIN orders c ON ((final_deal_accepted.order_id = c.id)))
  UNION ALL
  SELECT ('order-' :: text || order_completed.order_id) AS order_step_id,
         'Order Completed' :: text                      AS "Item Type",
         order_completed."timestamp",
         order_completed.order_id,
         order_completed.user_id,
         order_completed.dealer_partner_id,
         order_completed.duration,
         order_completed.is_final
         ,agent_id,
         800                                            AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((order_completed
      JOIN users b ON ((order_completed.user_id = b.id)))
      JOIN orders c ON ((order_completed.order_id = c.id)))
  UNION ALL
  SELECT ('order-' :: text || order_cancelled.order_id) AS order_step_id,
         'Order Cancelled' :: text                      AS "Item Type",
         order_cancelled."timestamp",
         order_cancelled.order_id,
         order_cancelled.user_id,
         order_cancelled.dealer_partner_id,
         order_cancelled.duration,
         order_cancelled.is_final
         ,agent_id,
         801                                            AS "Step Rank",
         b.distinct_id,
         c.order_type
  FROM ((order_cancelled
      JOIN users b ON ((order_cancelled.user_id = b.id)))
      JOIN orders c ON ((order_cancelled.order_id = c.id)))

)

,almost as (

SELECT order_steps.*,
CASE WHEN order_status.status IS NULL THEN 'Open' ELSE initcap(order_status.status) END current_order_status,
o.order_dbid,
dpid,
initcap(a.first_name) || ' ' || initcap(a.last_name) "Agent",
u.email "Customer Email", 
initcap(u.first_name || ' ' || u.last_name) "Customer Name",
CASE WHEN o.in_store = True THEN 'In-Store' ELSE 'Online' END in_store_type,
row_number() OVER(PARTITION BY order_steps.order_id ORDER BY "Step Rank" DESC) pick_most_recent
FROM order_steps
LEFT JOIN order_status ON order_steps.order_id = order_status.order_id
LEFT JOIN dealer_partners dp ON order_steps.dealer_partner_id = dp.id
LEFT JOIN orders o ON order_steps.order_id = o.id
LEFT JOIN agents a ON order_steps.agent_id = a.id
LEFT JOIN users u ON order_steps.user_id = u.id
WHERE dpid = '{{ dpid }}'
AND  tableau_secret = '{{ dpsk }}'
)

SELECT 
timestamp,
to_char(timestamp, 'Month YYYY') mth_yr,
--almost."Item Type",
LEFT("Step Rank"::text, 1) || '. ' || "Item Type" "Item Type", 
current_order_status "Order Status",
dpid, 
in_store_type,
order_type "Order Type",
"Customer Email",
"Customer Name",
"Agent",
'https://dealers.roadster.com/' || dpid || '/orders/' || order_dbid "Order",
1 exists_now

FROM almost
WHERE pick_most_recent = 1
and timestamp >= (date_trunc('month', now()) - '6 months'::interval)
ORDER BY timestamp desc
