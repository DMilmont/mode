WITH dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dp.dpid IN ('toyotaofplano','gregleblanctoyota','jimnortontoyota','sanmarcostoyota','gullotoyota','longotoyotaprosper','toyotaofboerne','atkinsondallas','atkinsonmadisonville','atkinsonbryan','lakesidetoyota','toyotaofirving')
)

,instore_data as (
SELECT *
FROM report_layer.dg_in_store_metrics_monthly
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups', 'Gst Dealers'))
AND "Date" IN ({{choose_your_date_range}})
)

SELECT
CASE WHEN "Dealership" = 'Gst Dealers' THEN '00 GST Dealers' ELSE "Dealership" END AS "Dealership",
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