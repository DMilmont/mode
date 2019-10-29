WITH filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info_SET di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
)

,dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END IN (SELECT * FROM filter_for_dpids)
AND dp.status = 'Live'
--and dealer_group <> dp.name
)

SELECT 
im."Dealership",
im."Date" date_sparkline,
im."In-Store Prospects",
im."In-Store Shares",
im."In-Store Orders",
im."Copies",
im."Prints",
im."In-Store Sales",
im."Active Agents",
im."Certified Agents",
im."Activity w/n 3 Days",
im."sorting"
FROM report_layer.dg_in_store_metrics_monthly im
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
AND "Dealership" <> 'Lexus Of Pleasanton'

