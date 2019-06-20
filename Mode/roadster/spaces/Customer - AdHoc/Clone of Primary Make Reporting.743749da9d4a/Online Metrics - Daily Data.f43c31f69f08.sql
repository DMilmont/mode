WITH dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dp.dpid IN ('toyotaofplano','gregleblanctoyota','jimnortontoyota','sanmarcostoyota','gullotoyota','longotoyotaprosper','toyotaofboerne','atkinsondallas','atkinsonmadisonville','atkinsonbryan','lakesidetoyota','toyotaofirving')
), 

base_online_data as (
  SELECT *
  FROM report_layer.dg_online_metrics_monthly
  WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
  OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
)
----
SELECT 
"Dealership",
"Date",
"Dealer Visitors CLEANED" "Rooftop Website Visitors",
"Express Visitors CLEANED" "Express Store Visitors", 
"Online Prospects" "Prospects",
online_orders "Orders", 
online_shares "Shares"
FROM base_online_data