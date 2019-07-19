 WITH date_dpid AS (
      SELECT * FROM (
      SELECT date, t.dpid, t.name, t.primary_make,
      'Current' interval_time
      FROM fact.d_cal_date
      CROSS JOIN (
      SELECT DISTINCT dps.dpid, dps.tableau_secret, dps.name, dps.primary_make FROM dealer_partners dps
      WHERE status = 'Live'          
      AND dps.dpid IN ({{ dpid }})
      ) t
      WHERE
      date >= '{{ start_date }}'
      AND
      date < '{{ end_date }}'
      ) v

      UNION

      SELECT * FROM (
      SELECT date, t.dpid, t.name, t.primary_make,
      '52 weeks ago' interval_time
      FROM fact.d_cal_date
      CROSS JOIN (
      SELECT DISTINCT dps.dpid, dps.tableau_secret, dps.name, dps.primary_make FROM dealer_partners dps
      WHERE status = 'Live'         
      AND dps.dpid IN ({{ dpid }})) t
      WHERE
      date >= ('{{ start_date }}'::date - '52 weeks'::interval)
      AND
      date < ('{{ end_date }}'::date - '52 weeks'::interval)
      ) z

  ), 
  
  base_interval as (
    SELECT DISTINCT dpid, name, primary_make, interval_time
    FROM date_dpid
  ),
  
  online_express_traffic AS (
      SELECT interval_time,
             f_traffic.dpid,
             f_traffic.dpsk,
             count(DISTINCT f_traffic.distinct_id)                                     AS online_express_visitors
      FROM fact.f_traffic
      INNER JOIN date_dpid dd ON fact.f_traffic.dpid = dd.dpid and fact.f_traffic.date = dd.date
      WHERE
             (f_traffic.is_in_store IS FALSE) AND
             ((f_traffic.dpid) :: text IN (SELECT DISTINCT date_dpid.dpid FROM date_dpid))
      GROUP BY interval_time,
               f_traffic.dpid,
               f_traffic.dpsk
  ), online_express_srp_traffic AS (
      SELECT interval_time,
             f_traffic.dpid,
             f_traffic.dpsk,
             count(DISTINCT f_traffic.distinct_id)                                     AS online_express_srp_visitors
      FROM fact.f_traffic
      INNER JOIN date_dpid dd ON fact.f_traffic.dpid = dd.dpid and fact.f_traffic.date = dd.date
      WHERE (
             (f_traffic.is_in_store IS FALSE) AND
             ((f_traffic.page_path) :: text = ANY
              (ARRAY[('/New Inventory'::character varying)::text, ('/Used Inventory'::character varying)::text])))
      GROUP BY interval_time,
               f_traffic.dpid,
               f_traffic.dpsk
  ), online_prospects AS (
      SELECT dd.interval_time,
             f_prospect.dpid,
             f_prospect.dpsk,
             count(DISTINCT f_prospect.customer_email)                                             AS online_prospects
      FROM fact.f_prospect
      INNER JOIN date_dpid dd ON fact.f_prospect.dpid = dd.dpid and fact.f_prospect.cohort_date_utc::date = dd.date
      WHERE (f_prospect.is_in_store IS FALSE)
      GROUP BY interval_time,
             f_prospect.dpid,
               f_prospect.dpsk
  ), online_shares AS (
      SELECT f_prospect.dpid,
             interval_time,
             count(DISTINCT f_prospect.customer_email)                                             AS count_shares
      FROM fact.f_prospect
      INNER JOIN date_dpid dd ON fact.f_prospect.dpid = dd.dpid and fact.f_prospect.cohort_date_utc = dd.date
      WHERE ((f_prospect.source = 'Lead Type' :: text) AND (f_prospect.item_type = 'SharedExpressVehicle' :: text) AND
             (f_prospect.is_in_store = false))
      GROUP BY f_prospect.dpid, interval_time
  ), online_orders AS (
      SELECT interval_time,
             f_prospect.dpid,
             f_prospect.dpsk,
             count(DISTINCT f_prospect.customer_email)                                             AS online_orders
      FROM fact.f_prospect
      INNER JOIN date_dpid dd ON fact.f_prospect.dpid = dd.dpid and fact.f_prospect.cohort_date_utc = dd.date
      WHERE ((f_prospect.is_in_store IS FALSE) AND
             (f_prospect.item_type = 'OrderStarted' :: text) AND (f_prospect.source = 'Lead Type' :: text))
      GROUP BY interval_time, f_prospect.dpid,
               f_prospect.dpsk
  ), online_sales AS (
      SELECT f_prospect.dpid,
             interval_time,
             count(DISTINCT f_prospect.customer_email)                                             AS count_sales
      FROM fact.f_prospect
      INNER JOIN date_dpid dd ON fact.f_prospect.dpid = dd.dpid and fact.f_prospect.cohort_date_utc = dd.date
      WHERE ((f_prospect.source = 'Lead Type' :: text) AND (f_prospect.is_in_store = false) AND
             (f_prospect.is_prospect_close_sale = true))
      GROUP BY f_prospect.dpid,
               interval_time
  ),

  -- online_traffic as (

  --   SELECT gs.dpid, interval_time, count(gp.distinct_id) visitors
  --   FROM ga2_pageviews gp
  --   LEFT JOIN ga2_sessions gs ON gp.ga2_session_id = gs.id
  --   INNER JOIN date_dpid dd ON date_trunc('day', gp.timestamp) = dd.date AND
  --   gs.dpid = dd.dpid
  --   WHERE gp.property = 'Main Sites' and
  --   gs.dpid IN ({{ dpid }})
  --   AND 
  --   (gp.timestamp >= '{{ start_date }}'
  --     AND
  --   gp.timestamp < '{{ end_date }}' )
  --   OR
  --   (
  --   gp.timestamp >= ('{{ start_date }}'::date - '52 weeks'::interval)
  --     AND
  --   gp.timestamp < ('{{ end_date }}'::date - '52 weeks'::interval)
  --   )
  --       GROUP BY gs.dpid, interval_time

  -- ),
  final_data AS (
      SELECT dd.interval_time,
             initcap((dd.name) :: text)                                                                                   AS "Dealership",
            -- percentile_cont(
            --   (0.5) :: double precision) WITHIN GROUP (ORDER BY ((dt.visitors) :: double precision))                     AS "Dealer Visitors",
             percentile_cont(
               (0.5) :: double precision) WITHIN GROUP (ORDER BY ((et.online_express_visitors) :: double precision))      AS "Online Express Visitors",
             percentile_cont(
               (0.5) :: double precision) WITHIN GROUP (ORDER BY ((srp.online_express_srp_visitors) :: double precision)) AS "Online Express SRP Visitors",
             percentile_cont(
               (0.5) :: double precision) WITHIN GROUP (ORDER BY ((op.online_prospects) :: double precision))             AS "Online Prospects",
             percentile_cont(
               (0.5) :: double precision) WITHIN GROUP (ORDER BY ((oo.online_orders) :: double precision))                AS online_orders,
             percentile_cont(
               (0.5) :: double precision) WITHIN GROUP (ORDER BY ((os.count_shares) :: double precision))                 AS online_shares,
             percentile_cont(
               (0.5) :: double precision) WITHIN GROUP (ORDER BY ((oss.count_sales) :: double precision))                 AS online_sales
      FROM (((((((base_interval dd
          LEFT JOIN online_express_traffic et ON (((et.interval_time = dd.interval_time) AND ((et.dpid) :: text = (dd.dpid) :: text))))
          -- LEFT JOIN online_traffic dt ON (((dt.dpid = (dd.dpid) :: text) AND (dt.interval_time = dd.interval_time))))
          LEFT JOIN online_express_srp_traffic srp ON (((srp.interval_time = dd.interval_time) AND
                                                        ((srp.dpid) :: text = (dd.dpid) :: text))))
          LEFT JOIN online_prospects op ON ((((op.dpid) :: text = (dd.dpid) :: text) AND (op.interval_time = dd.interval_time))))
          LEFT JOIN online_orders oo ON ((((op.dpid) :: text = (oo.dpid) :: text) AND (op.interval_time = oo.interval_time))))
          LEFT JOIN online_shares os ON ((((op.dpid) :: text = (os.dpid) :: text) AND (op.interval_time = os.interval_time))))
          LEFT JOIN online_sales oss ON ((((op.dpid) :: text = (oss.dpid) :: text) AND (op.interval_time = oss.interval_time)))))
      GROUP BY (dd.interval_time, (initcap((dd.name) :: text)))
  )

  SELECT interval_time,
         final_data."Dealership",
        -- final_data."Dealer Visitors",
         final_data."Online Express Visitors",
         final_data."Online Express SRP Visitors",
         final_data."Online Prospects",
         final_data.online_orders,
         final_data.online_shares,
         final_data.online_sales,
        -- CASE
        --   WHEN (final_data."Dealership" !~~* '%Percentile%' :: text) THEN final_data."Dealer Visitors"
        --   ELSE (0.0) :: double precision
        --     END AS "Dealer Visitors CLEANED",
         CASE
           WHEN (final_data."Dealership" !~~* '%Percentile%' :: text) THEN final_data."Online Express Visitors"
           ELSE (0.0) :: double precision
             END AS "Express Visitors CLEANED"
  FROM final_data
  ORDER BY interval_time desc
