SELECT
v.*,
t.ct_unique_users_sell_your_car,
z.ct_unique_users_trade_in_wizard_seen,
x.ct_standalone_trades_completed
FROM (
  SELECT
  dpid,
  COUNT(DISTINCT gs.distinct_id) ct_unique_users_total
  FROM ga2_pageviews gp
  LEFT JOIN ga2_sessions gs ON gp.ga2_session_id = gs.id
  WHERE
  property = 'Express Sites'
  and gs.timestamp >= '2019-01-01'
  AND gp.timestamp >='2019-01-01'
  GROUP BY 1
) v
LEFT JOIN (
    SELECT
    dpid,
    COUNT(DISTINCT gs.distinct_id) ct_unique_users_sell_your_car
    FROM ga2_pageviews gp
    LEFT JOIN ga2_sessions gs ON gp.ga2_session_id = gs.id
    WHERE page_path = '/sell_your_car'
    and property = 'Express Sites'
    AND gs.timestamp >='2019-01-01'
    AND gp.timestamp >='2019-01-01'
    GROUP BY 1
) t ON t.dpid = v.dpid
LEFT JOIN (
    SELECT
    dpid,
    COUNT(DISTINCT gs.distinct_id) ct_unique_users_trade_in_wizard_seen
    FROM ga2_pageviews gp
    LEFT JOIN ga2_sessions gs ON gp.ga2_session_id = gs.id
    WHERE page_path = '/Trade-In Wizard'
    and previous_page_path = '/sell_your_car'
    and property = 'Express Sites'
    AND gs.timestamp >='2019-01-01'
    AND gp.timestamp >='2019-01-01'
    GROUP BY 1
) z ON z.dpid = v.dpid
LEFT JOIN (
SELECT
    dpid,
    COUNT(DISTINCT os.user_id) ct_standalone_trades_completed
    FROM orders o
    LEFT JOIN order_submitted os ON o.id = os.order_id
    LEFT JOIN dealer_partners dp ON os.dealer_partner_id = dp.id
    WHERE order_type = 'StandaloneTrade' AND created_at >= '2019-01-01'
    GROUP BY 1
) x ON v.dpid = x.dpid

