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
)

SELECT bod."Dealership", 
bod."Date"::text,
bod."Total Orders Submitted",
bod."Accessories Completed",
bod."Credit Completed",
bod."Accessories Attached Rate",
bod."Accessories Completed Rate",
bod."Credit Completed Rate",
bod."Deal Sheet Accepted Rate",
bod."Final Deal Sent Rate",
bod."Service Plans Attached Rate", 
bod."Service Plans Completed Rate",
bod."Trade-In Attached Rate", 
bod."Trade-In Completed Rate"
FROM base_order_data bod
WHERE "Date" IN (select generate_series(date_trunc('month', now()) - '6 mons'::interval, date_trunc('month', now()), '1 month'))
AND "Date"  >= (date_trunc('month', now()) - '2 months'::interval)




