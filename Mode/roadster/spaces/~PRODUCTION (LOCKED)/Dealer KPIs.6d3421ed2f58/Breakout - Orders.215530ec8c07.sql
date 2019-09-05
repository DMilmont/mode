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

  FROM order_submitted order_submitted

  UNION ALL
  SELECT (deal_sheet_sent.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Sent' :: text                 AS "Item Type",
         deal_sheet_sent."timestamp",
         deal_sheet_sent.order_id,
         deal_sheet_sent.user_id,
         deal_sheet_sent.dealer_partner_id,
         deal_sheet_sent.duration,
         deal_sheet_sent.is_final

  FROM deal_sheet_sent deal_sheet_sent

  UNION ALL
  SELECT (deal_sheet_accepted.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Accepted' :: text                 AS "Item Type",
         deal_sheet_accepted."timestamp",
         deal_sheet_accepted.order_id,
         deal_sheet_accepted.user_id,
         deal_sheet_accepted.dealer_partner_id,
         deal_sheet_accepted.duration,
         deal_sheet_accepted.is_final

  FROM deal_sheet_accepted
    
  UNION ALL
  SELECT (credit_completed.order_step_dbid) :: text AS order_step_id,
         'Credit Completed' :: text                 AS "Item Type",
         credit_completed."timestamp",
         credit_completed.order_id,
         credit_completed.user_id,
         credit_completed.dealer_partner_id,
         credit_completed.duration,
         credit_completed.is_final

  FROM credit_completed

  UNION ALL
  SELECT (service_plans_completed.order_step_dbid) :: text AS order_step_id,
         'Service Plans Completed' :: text                 AS "Item Type",
         service_plans_completed."timestamp",
         service_plans_completed.order_id,
         service_plans_completed.user_id,
         service_plans_completed.dealer_partner_id,
         service_plans_completed.duration,
         service_plans_completed.is_final

  FROM service_plans_completed

  UNION ALL
  SELECT (accessories_completed.order_step_dbid) :: text AS order_step_id,
         'Accessories Completed' :: text                 AS "Item Type",
         accessories_completed."timestamp",
         accessories_completed.order_id,
         accessories_completed.user_id,
         accessories_completed.dealer_partner_id,
         accessories_completed.duration,
         accessories_completed.is_final

  FROM accessories_completed

  UNION ALL
  SELECT (final_deal_sent.order_step_dbid) :: text AS order_step_id,
         'Final Deal Sent' :: text                 AS "Item Type",
         final_deal_sent."timestamp",
         final_deal_sent.order_id,
         final_deal_sent.user_id,
         final_deal_sent.dealer_partner_id,
         final_deal_sent.duration,
         final_deal_sent.is_final

  FROM final_deal_sent

  UNION ALL
  SELECT (final_deal_accepted.order_step_dbid) :: text AS order_step_id,
         'Final Deal Accepted' :: text                 AS "Item Type",
         final_deal_accepted."timestamp",
         final_deal_accepted.order_id,
         final_deal_accepted.user_id,
         final_deal_accepted.dealer_partner_id,
         final_deal_accepted.duration,
         final_deal_accepted.is_final

  FROM final_deal_accepted

  UNION ALL
  SELECT ('order-' :: text || order_completed.order_id) AS order_step_id,
         'Order Completed' :: text                      AS "Item Type",
         order_completed."timestamp",
         order_completed.order_id,
         order_completed.user_id,
         order_completed.dealer_partner_id,
         order_completed.duration,
         order_completed.is_final

  FROM order_completed

  UNION ALL
  SELECT ('order-' :: text || order_cancelled.order_id) AS order_step_id,
         'Order Cancelled' :: text                      AS "Item Type",
         order_cancelled."timestamp",
         order_cancelled.order_id,
         order_cancelled.user_id,
         order_cancelled.dealer_partner_id,
         order_cancelled.duration,
         order_cancelled.is_final

  FROM order_cancelled


)

,almost as (

SELECT order_steps.*,
CASE WHEN order_status.status IS NULL THEN 'Open' ELSE initcap(order_status.status) END current_order_status,
dpid,

CASE WHEN o.in_store = True THEN 'In-Store' ELSE 'Online' END in_store_type

FROM order_steps
LEFT JOIN order_status ON order_steps.order_id = order_status.order_id
LEFT JOIN dealer_partners dp ON order_steps.dealer_partner_id = dp.id
LEFT JOIN orders o ON order_steps.order_id = o.id
WHERE dpid = '{{ dpid }}'
and date(timestamp) >= (date_trunc('day', now()) - INTERVAL '7 Days')
and date(timestamp)< (date_trunc('day', now()))
and  CASE WHEN order_status.status IS NULL THEN 'Open' ELSE initcap(order_status.status) END in ('Open','Completed')
)


SELECT in_store_type
,count(1) order_count
, in_store_type || '<br> ('|| count(1) ||')' as label

FROM almost

GROUP BY 1

