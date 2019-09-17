
SELECT fs.dpid,
       fs.month_year,
       ct_total_forms_submitted,
       ct_unique_users_form_submissions,
       ct_total_deals_built,
       ct_unique_users_deals_built,
       ct_total_deals_submitted,
       ct_unique_users_deals_submitted,
       ct_credit_apps_submitted,
       ct_unique_users_credit_app_submitted,
       ct_sales_matched,
       ct_orders_completed,
       ct_unique_users_orders_completed,
       ct_trade_in_valuation_events,
       ct_unique_users_trade_in_valuation_events,
       ct_service_plan_events,
       ct_unique_users_service_plan_events,
       ct_total_accessories_added,
       ct_unique_users_accessories_added,
       ct_vehicle_reservations,
       ct_vehicle_deposits
FROM (
    SELECT dpid,
           date_trunc('month', timestamp) month_year,
           COUNT(*)                                                                   ct_total_forms_submitted,
           COUNT(DISTINCT user_id)                                                    ct_unique_users_form_submissions
    FROM lead_submitted ls
           LEFT JOIN dealer_partners dp ON ls.dealer_partner_id = dp.id
    WHERE timestamp >= '2019-09-01'
    GROUP BY 1, 2) fs
       LEFT JOIN
         (
    SELECT dpid,
           date_trunc('month', timestamp) month_year,
           COUNT(*)                                                                   ct_total_deals_built,
           COUNT(DISTINCT user_id)                                                    ct_unique_users_deals_built
    FROM user_events ue
           LEFT JOIN dealer_partners dp ON ue.dealer_partner_id = dp.id
    WHERE ue.name = 'Deal Built'
      AND timestamp >= '2019-09-01'
    GROUP BY 1, 2) p ON fs.dpid = p.dpid AND fs.month_year = p.month_year
       LEFT JOIN
         (
    SELECT dpid,
           date_trunc('month', gp.timestamp) month_year,
           COUNT(gp.*)                       ct_total_deals_submitted,
           COUNT(DISTINCT gp.distinct_id)    ct_unique_users_deals_submitted
    FROM ga2_pageviews gp
           LEFT JOIN ga2_sessions gs ON gp.ga2_session_id = gs.id
    WHERE gp.timestamp >= '2019-09-01'
      AND gs.timestamp >= '2019-09-01'
      AND page_path ILIKE '%order-steps'
    GROUP BY 1, 2) ds ON fs.dpid = ds.dpid AND fs.month_year = ds.month_year
       LEFT JOIN (
                 --- Have multiple different credit related items
    SELECT dpid,
           date_trunc('month', timestamp) month_year,
           COUNT(*)                       ct_credit_apps_submitted,
           COUNT(DISTINCT user_id)        ct_unique_users_credit_app_submitted
    FROM credit_completed cc
           LEFT JOIN dealer_partners dp ON cc.dealer_partner_id = dp.id
    WHERE timestamp >= '2019-09-01'
    GROUP BY 1, 2) cas ON fs.dpid = cas.dpid AND fs.month_year = cas.month_year
       LEFT JOIN
         (
    SELECT dpid, date_trunc('month', sold_date) month_year, COUNT(*) ct_sales_matched
    FROM fact.f_sale fs
    WHERE sold_date >= '2018-09-01'
      AND first_lead_id IS NOT NULL
    GROUP BY 1, 2) sm ON fs.dpid = sm.dpid AND fs.month_year = sm.month_year
       LEFT JOIN
         (
    SELECT dpid,
           date_trunc('month', timestamp) month_year,
           COUNT(*)                       ct_orders_completed,
           COUNT(DISTINCT user_id)        ct_unique_users_orders_completed
    FROM order_completed oc
           LEFT JOIN dealer_partners dp ON oc.dealer_partner_id = dp.id
    WHERE timestamp > '2019-09-01'
    GROUP BY 1, 2) os ON fs.dpid = os.dpid AND fs.month_year = os.month_year
       LEFT JOIN (SELECT dpid,
                         date_trunc('month', timestamp) month_year,
                         COUNT(*)                       ct_trade_in_valuation_events,
                         COUNT(DISTINCT user_id)        ct_unique_users_trade_in_valuation_events
                  FROM user_events ue
                         LEFT JOIN dealer_partners dp ON ue.dealer_partner_id = dp.id
                  WHERE timestamp >= '2019-09-01'
                    and ue.name = 'Trade-In Valuation'
                  GROUP BY 1, 2) ti ON fs.dpid = ti.dpid AND fs.month_year = ti.month_year
       LEFT JOIN (SELECT dpid,
                         date_trunc('month', timestamp) month_year,
                         COUNT(*)                       ct_service_plan_events,
                         COUNT(DISTINCT user_id)        ct_unique_users_service_plan_events
                  FROM user_events ue
                         LEFT JOIN dealer_partners dp ON ue.dealer_partner_id = dp.id
                  WHERE timestamp >= '2019-09-01'
                    and ue.name IN ('Service Plan Added', 'Service Plan Removed')
                  GROUP BY 1, 2) spp ON fs.dpid = spp.dpid AND fs.month_year = spp.month_year
       LEFT JOIN (SELECT dpid,
                         date_trunc('month', gp.timestamp) month_year,
                         COUNT(gp.*)                       ct_total_accessories_added,
                         COUNT(DISTINCT gp.distinct_id)    ct_unique_users_accessories_added
                  FROM ga2_pageviews gp
                         LEFT JOIN ga2_sessions gs ON gp.ga2_session_id = gs.id
                  WHERE gp.timestamp >= '2019-09-01'
                    AND gs.timestamp >= '2019-09-01'
                    AND property = 'Express Sites'
                    AND page_path ILIKE '%purchase-accessories'
                  GROUP BY 1, 2) a ON fs.dpid = a.dpid AND fs.month_year = a.month_year
       LEFT JOIN (SELECT dpid,
                         date_trunc('month', vr.created_at) month_year,
                         COUNT(vr.*)                        ct_vehicle_reservations,
                         COUNT(vrc.amount)                  ct_vehicle_deposits
                  FROM vehicle_reservation vr
                         LEFT JOIN vehicle_reservation_charged vrc ON vr.id = vrc.vehicle_reservation_id
                         LEFT JOIN dealer_partners dp ON vr.dealer_partner_id = dp.id
                  WHERE vr.created_at >= '2019-09-01'
                  GROUP BY 1, 2) r ON fs.dpid = r.dpid AND fs.month_year = r.month_year
       INNER JOIN dealer_partners dps ON fs.dpid = dps.dpid
WHERE dps.primary_make = 'Porsche'