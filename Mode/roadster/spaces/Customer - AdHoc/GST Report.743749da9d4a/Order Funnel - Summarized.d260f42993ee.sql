with dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dp.dpid IN ('toyotaofplano','gregleblanctoyota','jimnortontoyota','sanmarcostoyota','gullotoyota','longotoyotaprosper','toyotaofboerne','atkinsondallas','atkinsonmadisonville','atkinsonbryan','lakesidetoyota','toyotaofirving')
), 

base_order_data as (
  SELECT *
  FROM report_layer.dg_order_step_metrics
  WHERE "Dealership" IN (SELECT initcap(name) FROM dpids)
)

SELECT *
FROM base_order_data
WHERE "Date" IN ({{choose_your_date_range}})




