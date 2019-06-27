with filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid IN ({{ dpid }})
)


,dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END IN (SELECT * FROM filter_for_dpids)
AND dp.status = 'Live'
--and dealer_group <> dp.name
), 

base_order_data as (
  SELECT *
  FROM report_layer.dg_order_step_metrics
  WHERE "Dealership" IN (SELECT initcap(name) FROM dpids)
  AND "Date" IN (select generate_series(date_trunc('month', now()) - '6 mons'::interval, date_trunc('month', now()), '1 month'))
  AND "Date"  >= (date_trunc('month', now()) - '2 months'::interval)
)

SELECT "Dealership", "Date"::text, 'Total Orders Submitted' metric, 1 value_order_steps, 1 step FROM base_order_data UNION
SELECT "Dealership", "Date"::text, 'Deal Sheet Accepted Rate' metric, CASE WHEN "Deal Sheet Accepted Rate" IS NOT NULL THEN ROUND("Deal Sheet Accepted Rate"::decimal, 2) ELSE 0 END AS value_order_steps, 2 step FROM base_order_data UNION
SELECT "Dealership", "Date"::text, 'Trade-In Completed Rate' metric, CASE WHEN "Trade-In Completed Rate" IS NOT NULL THEN ROUND("Trade-In Completed Rate"::decimal, 2) ELSE 0 END AS value_order_steps, 3 step FROM base_order_data UNION
SELECT "Dealership", "Date"::text, 'Credit Completed Rate' metric, CASE WHEN "Credit Completed Rate" IS NOT NULL THEN ROUND("Credit Completed Rate"::decimal, 2) ELSE 0 END value_order_steps, 4 step FROM base_order_data UNION
SELECT "Dealership", "Date"::text, 'Service Plans Completed Rate' metric, CASE WHEN "Service Plans Completed Rate" IS NOT NULL THEN ROUND("Service Plans Completed Rate"::decimal, 2) ELSE 0 END AS value_order_steps, 5 step FROM base_order_data
ORDER BY "Dealership", step DESC