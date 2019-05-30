WITH filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid = '{{ dpid }}' 
)

,dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END = (SELECT * FROM filter_for_dpids)
--and dealer_group <> dp.name
)

,instore_data as (
SELECT *
FROM report_layer.dg_in_store_metrics_monthly
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
AND "Date" IN ({{choose_your_date_range}})
)

SELECT
"Dealership", 
SUM("In-Store Prospects") "In-Store Prospects",
SUM("In-Store Shares") "In-Store Shares", 
SUM("In-Store Orders") "In-Store Orders", 
SUM("Copies") "Copies",
SUM("Prints") "Prints", 
SUM("In-Store Sales") "In-Store Sales",
SUM("In-Store Sales") / NULLIF(SUM("In-Store Prospects"), 0) "Close Rate", 
MIN("Active Agents") "Active Agents", 
MIN("Certified Agents") "Certified Agents", 
MIN("Activity w/n 3 Days") "Activity w/n 3 Days"
FROM instore_data
GROUP BY 1