WITH dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dp.dpid IN ('toyotaofplano','gregleblanctoyota','jimnortontoyota','sanmarcostoyota','gullotoyota','longotoyotaprosper','toyotaofboerne','atkinsondallas','atkinsonmadisonville','atkinsonbryan','lakesidetoyota','toyotaofirving')
)

SELECT *
FROM report_layer.dg_in_store_metrics_monthly
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))

