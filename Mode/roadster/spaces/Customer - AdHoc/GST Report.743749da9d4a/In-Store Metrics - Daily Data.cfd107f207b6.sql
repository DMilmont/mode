WITH dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dp.dpid IN ('toyotaofplano','gregleblanctoyota','jimnortontoyota','sanmarcostoyota','gullotoyota','longotoyotaprosper','toyotaofboerne','atkinsondallas','atkinsonmadisonville','atkinsonbryan','lakesidetoyota','toyotaofirving')
)

SELECT CASE WHEN "Dealership" = 'Gst Dealers' THEN '00 GST Dealers' ELSE "Dealership" END AS "Dealership",
"Date",
"In-Store Prospects",
"In-Store Shares",
"In-Store Orders", 
"Copies", 
"Prints",
"In-Store Sales",
"Active Agents",
"Certified Agents", 
"Activity w/n 3 Days",
sorting

FROM report_layer.dg_in_store_metrics_monthly
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups', 'Gst Dealers'))

