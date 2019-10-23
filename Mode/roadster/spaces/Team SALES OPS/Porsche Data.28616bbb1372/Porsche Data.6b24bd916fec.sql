
SELECT fs.dpid "Dealer",
       (fs.month_year + '1 day'::interval) "Month & Year",
       fs.in_store "In-Store Flag", --ct_total_forms_submitted,
       'Measures' "Measures",
 ct_unique_users_form_submissions "Form Submissions", --ct_total_deals_built,
 ct_unique_users_deals_built "Deals Built", --ct_total_deals_submitted,
 ct_unique_users_deals_submitted "Deals Submitted" , --ct_credit_apps_submitted,
 ct_unique_users_credit_app_submitted "Credit App Submitted",
 ct_sales_matched "Sales Matched", --ct_orders_completed,
 ct_unique_users_orders_completed "Orders Completed", --ct_trade_in_valuation_events,
 ct_unique_users_trade_in_valuation_events "Trade-In Evaluations", --ct_service_plan_events,
 ct_unique_users_serviceplanadded_events "Service Plans Added",
 ct_unique_users_serviceplanremoved_events "Service Plans Removed",
 ct_unique_users_accessories_added "Accessories Added",
 ct_vehicle_reservations "Vehicle Reservations",
 ct_vehicle_deposits "Vehicle Deposits",
 ct_orders_completed_fully "Order Completed in Roadster",
 ct_trade_info_attached_to_order "Trade-In Info Attached to Completed Order",
 ct_unique_vdp_views "VDP Views",
 ct_dealer_visitors "Dealer Website Visitors"
FROM
    (SELECT dpid,
            date_trunc('month', timestamp) month_year,
            in_store,
            COUNT(*) ct_total_forms_submitted,
            COUNT(DISTINCT user_id) ct_unique_users_form_submissions
   FROM lead_submitted ls
   LEFT JOIN dealer_partners dp
     ON ls.dealer_partner_id = dp.id
   WHERE timestamp >= '2019-09-01'
   GROUP BY 1,
            2,
            3) fs
LEFT JOIN (
  SELECT 
  dpid,
  date_trunc('month', date) month_year,
  is_in_store in_store,
  COUNT(DISTINCT distinct_id) ct_unique_vdp_views
  FROM fact.f_traffic ft
  WHERE page_path IN ('/New VDP', '/Used VDP')
  GROUP BY 1,2,3
) vdp_views ON fs.dpid = vdp_views.dpid AND fs.in_store = vdp_views.in_store AND fs.month_year = vdp_views.month_year
LEFT JOIN (
  SELECT
  dpid, 
  false in_store,
  "Date" month_year,
  "Dealer Visitors" ct_dealer_visitors
  FROM report_layer.dg_online_metrics_monthly dgo
  LEFT JOIN dealer_partners dp ON dgo."Dealership" = dp.name
) dwv ON fs.dpid = dwv.dpid AND fs.month_year = dwv.month_year AND fs.in_store = dwv.in_store
LEFT JOIN
  (SELECT dpid,
          month_year,
          in_store,
          COUNT(user_id) ct_unique_users_deals_built
   FROM
     (SELECT DISTINCT dpid,
                      date_trunc('month', timestamp) month_year,
                      in_store,
                      user_id
      FROM user_events ue
      LEFT JOIN dealer_partners dp
        ON ue.dealer_partner_id = dp.id
        WHERE ue.name = 'Deal Built'
          AND timestamp >= '2019-09-01'
          AND primary_make = 'Porsche' ) t
   GROUP BY 1,
            2,
            3) p
  ON fs.dpid = p.dpid
  AND fs.month_year = p.month_year
  AND fs.in_store = p.in_store
LEFT JOIN
    (SELECT dpid,
            month_year,
            in_store,
            COUNT(distinct_id) ct_unique_users_deals_submitted
   FROM
     (SELECT DISTINCT gs.dpid,
                      date_trunc('month', gs.timestamp) month_year,
                      in_store,
                      gs.distinct_id
      FROM ga2_pageviews gp
      LEFT JOIN ga2_sessions gs
      LEFT JOIN dealer_partners dp
        ON gs.dpid = dp.dpid
          ON gp.ga2_session_id = gs.id
          WHERE gp.timestamp >= '2019-09-01'
            AND gs.timestamp >= '2019-09-01'
            AND page_path = '/virtual/order-steps'
            AND property = 'Express Sites'
            AND gs.dpid IN
              (SELECT dpid
             FROM dealer_partners
             WHERE primary_make = 'Porsche'
               AND status = 'Live') ) t
   GROUP BY 1,
            2,
            3) ds
  ON fs.dpid = ds.dpid
  AND fs.month_year = ds.month_year
  AND fs.in_store = ds.in_store
LEFT JOIN
    (--- Have multiple different credit related items
 SELECT dpid,
        date_trunc('month', timestamp) month_year,
        o.in_store,
        COUNT(*) ct_credit_apps_submitted,
        COUNT(DISTINCT user_id) ct_unique_users_credit_app_submitted
     FROM credit_completed cc
     LEFT JOIN dealer_partners dp
       ON cc.dealer_partner_id = dp.id
     LEFT JOIN orders o
       ON cc.order_id = o.id
     WHERE timestamp >= '2019-09-01'
     GROUP BY 1,
              2,
              3) cas
  ON fs.dpid = cas.dpid
  AND fs.month_year = cas.month_year
  AND fs.in_store = cas.in_store
LEFT JOIN
    (SELECT dpid,
            date_trunc('month', sold_date) month_year,
            COUNT(*) ct_sales_matched
     FROM fact.f_sale fs
     WHERE sold_date >= '2019-09-01'
       AND first_lead_id IS NOT NULL
     GROUP BY 1,
              2) sm
  ON fs.dpid = sm.dpid
  AND fs.month_year = sm.month_year
LEFT JOIN
    (SELECT dpid,
            date_trunc('month', timestamp) month_year,
            o.in_store,
            COUNT(*) ct_orders_completed,
            COUNT(DISTINCT user_id) ct_unique_users_orders_completed
     FROM order_completed oc
     LEFT JOIN dealer_partners dp
       ON oc.dealer_partner_id = dp.id
     LEFT JOIN orders o
       ON oc.order_id = o.id
     WHERE timestamp > '2019-09-01'
     GROUP BY 1,
              2,
              3) os
  ON fs.dpid = os.dpid
  AND fs.month_year = os.month_year
  AND fs.in_store = os.in_store
LEFT JOIN
    (SELECT dpid,
            month_year,
            in_store,
            COUNT(user_id) ct_unique_users_trade_in_valuation_events
     FROM
       (SELECT DISTINCT dpid,
                        date_trunc('month', timestamp) month_year,
                        in_store,
                        user_id
        FROM user_events ue
        LEFT JOIN dealer_partners dp
          ON ue.dealer_partner_id = dp.id
          WHERE timestamp >= '2019-09-01'
            AND ue.name = 'Trade-In Valuation'
            AND primary_make = 'Porsche' ) t
     GROUP BY 1,
              2,
              3) ti
  ON fs.dpid = ti.dpid
  AND fs.month_year = ti.month_year
  AND fs.in_store = ti.in_store
LEFT JOIN
      (SELECT dpid,
              month_year,
              in_store,
              SUM(CASE
                      WHEN name = 'Service Plan Added' THEN 1
                      ELSE 0
                  END) ct_unique_users_serviceplanadded_events,
              SUM(CASE
                      WHEN name = 'Service Plan Removed' THEN 1
                      ELSE 0
                  END) ct_unique_users_serviceplanremoved_events
     FROM
       (SELECT DISTINCT dp.dpid,
                        date_trunc('month', timestamp) month_year,
                        ue.in_store,
                        user_id,
                        ue.name
        FROM user_events ue
        LEFT JOIN dealer_partners dp
          ON ue.dealer_partner_id = dp.id
          WHERE timestamp >= '2019-09-01'
            AND primary_make = 'Porsche'
            AND ue.name IN ('Service Plan Added',
                            'Service Plan Removed') ) t
     GROUP BY 1,
              2,
              3
              ) spp
  ON fs.dpid = spp.dpid
  AND fs.month_year = spp.month_year
  AND fs.in_store = spp.in_store
LEFT JOIN
      (SELECT dpid,
              month_year,
              in_store,
              COUNT(distinct_id) ct_unique_users_accessories_added
     FROM
       ( SELECT DISTINCT gs.dpid,
                         date_trunc('month', gs.timestamp) month_year,
                         in_store,
                         gs.distinct_id
        FROM ga2_pageviews gp
        LEFT JOIN ga2_sessions gs
        LEFT JOIN dealer_partners dp
          ON gs.dpid = dp.dpid
            ON gp.ga2_session_id = gs.id
            WHERE gp.timestamp >= '2019-09-01'
              AND gs.timestamp >= '2019-09-01'
              AND page_path = '/modal/accessories-modal'
              AND property = 'Express Sites'
              AND gs.dpid IN
                (SELECT dpid
               FROM dealer_partners
               WHERE primary_make = 'Porsche'
                 AND status = 'Live') ) t
     GROUP BY 1,
              2,
              3) a
  ON fs.dpid = a.dpid
  AND fs.month_year = a.month_year
  AND fs.in_store = a.in_store
LEFT JOIN
      (SELECT dpid,
              date_trunc('month', vr.created_at) month_year,
              COUNT(vr.*) ct_vehicle_reservations,
              COUNT(vrc.amount) ct_vehicle_deposits
       FROM vehicle_reservation vr
       LEFT JOIN vehicle_reservation_charged vrc
         ON vr.id = vrc.vehicle_reservation_id
       LEFT JOIN dealer_partners dp
         ON vr.dealer_partner_id = dp.id
       WHERE vr.created_at >= '2019-09-01'
       GROUP BY 1,
                2) r
  ON fs.dpid = r.dpid
  AND fs.month_year = r.month_year
INNER JOIN dealer_partners dps
  ON fs.dpid = dps.dpid
  
LEFT JOIN (
 SELECT
dpid,
date_trunc('month', oc.timestamp) "Month & Year",
o.in_store,
COUNT(o.*) ct_orders_completed_fully,
COUNT(ti.status) ct_trade_info_attached_to_order
--COUNT(*) ct_comleted_orders
FROM orders o
INNER JOIN order_completed oc ON o.id = oc.order_id
LEFT JOIN dealer_partners dp ON oc.dealer_partner_id = dp.id
LEFT JOIN trade_ins ti ON o.id = ti.order_id
WHERE
order_type = 'Purchase' AND
primary_make = 'Porsche'
GROUP BY 1,2, 3
) til ON fs.dpid = til.dpid AND fs.in_store = til.in_store AND fs.month_year = til."Month & Year"
WHERE dps.dpid IN (
SELECT dpid
FROM dealer_partners dp
WHERE primary_make = 'Porsche'
AND dpid != 'loeberporsche'
)