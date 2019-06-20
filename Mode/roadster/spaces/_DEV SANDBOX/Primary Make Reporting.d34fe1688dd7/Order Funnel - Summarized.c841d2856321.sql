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
--and dealer_group <> dp.name
), 

base_order_data as (
  SELECT *
  FROM report_layer.dg_order_step_metrics
  WHERE "Dealership" IN (SELECT initcap(name) FROM dpids)
)

SELECT *
FROM base_order_data
WHERE "Date" IN ({{choose_your_date_range}})




