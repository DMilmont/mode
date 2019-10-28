WITH filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE set_dealer IS TRUE and name <> 'Lexus Of Pleasanton'
)

,dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END IN (SELECT * FROM filter_for_dpids)
AND dp.status = 'Live'
--and dealer_group <> dp.name
)

,instore_data as (
SELECT *
FROM report_layer.dg_in_store_metrics_monthly
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
AND "Date" IN (select generate_series(date_trunc('month', now()) - '6 mons'::interval, date_trunc('month', now()), '1 month'))
AND "Date"  >= (date_trunc('month', now()) - '2 months'::interval)
)

SELECT
CASE WHEN "Dealership" ILIKE '%Percentile%' THEN 'Top Dealers' ELSE 'Your Rooftops' END as "Title",
"Dealership", 
"Date"::text,
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
WHERE "Dealership" <> 'Lexus Of Pleasanton'
GROUP BY 1,2,3
ORDER BY 2,3