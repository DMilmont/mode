
SELECT
dp.dpid,
"Dealer Trade Type",
o.id, o.order_dbid, o.created_at, o.in_store, o.order_type,
order_status.*,
ti.status "Trade-In Status",
ti.source "Trade-In Source",
CASE WHEN status_ts IS NOT NULL then status_ts ELSE created_at END timing
from orders o
LEFT JOIN (
  SELECT order_id, is_final, 'Completed' status, timestamp status_ts
  FROM order_completed oc
  UNION
  SELECT order_id, is_final, 'Canceled' status, timestamp status_ts
  FROM order_cancelled oca
) order_status ON o.id = order_status.order_id
LEFT JOIN trade_ins ti ON o.id = ti.order_id
LEFT JOIN order_submitted osub ON o.id = osub.order_id
LEFT JOIN dealer_partners dp ON osub.dealer_partner_id = dp.id
-- Basically Completed Orders
INNER JOIN (
  SELECT DISTINCT order_id
  FROM order_steps
  WHERE "Item Type" IN ('Final Deal Sent', 'Final Deal Accepted', 'Order Completed')
) oid ON o.id = oid.order_id
LEFT JOIN (
  SELECT
  dpid,
  CASE WHEN properties ->> 'purchase_page_valuation' = 'roadster'
      THEN 'Express Trade Dealer'
      ELSE 'Non-Express Trade Dealer' END "Dealer Trade Type"
  FROM dealer_partner_properties dpp
  LEFT JOIN dealer_partners dp ON dpp.dealer_partner_id = dp.id
  WHERE date = current_date - '1 day'::interval
) exp ON dp.dpid = exp.dpid
WHERE o.created_at >= '2019-01-01'
