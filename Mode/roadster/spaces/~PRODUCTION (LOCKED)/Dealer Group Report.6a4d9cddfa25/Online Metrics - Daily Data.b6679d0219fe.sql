WITH filter_for_dpids as (
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

base_online_data as (
  SELECT *
  FROM report_layer.dg_online_metrics_monthly
  WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
  OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
)
----
SELECT 
"Dealership",
"Date"::text,
"Dealer Visitors CLEANED" "Rooftop Website Visitors",
"Express Visitors CLEANED" "Express Store Visitors", 
"Online Prospects" "Prospects",
online_orders "Orders", 
online_shares "Shares"
FROM base_online_data