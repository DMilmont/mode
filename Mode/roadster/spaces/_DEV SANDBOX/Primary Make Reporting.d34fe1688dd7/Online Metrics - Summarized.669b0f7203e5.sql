
WITH dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE (primary_make in ({{ primary_make }})
AND dp.state IN ({{ state }}))
OR
(dp.dpid IN ( {{ dpid }} ))
), 

base_online_data as (
  SELECT *
  FROM report_layer.dg_online_metrics_monthly
  WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
  OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
  AND "Date" IN ({{choose_your_date_range}})
)
----


SELECT "Dealership", 
SUM("Dealer Visitors CLEANED") "Dealer Visitors",
SUM("Express Visitors CLEANED") "Express Visitors", 
SUM("Online Express Visitors") / NULLIF(SUM("Dealer Visitors"), 0) "Online Express Ratio",
SUM("Online Prospects")/NULLIF(SUM("Online Express Visitors"), 0) "Prospect Conversion",
SUM("Online Prospects") "Online Prospects",
SUM("online_shares") "Online Shares",
SUM("online_orders") "Online Orders", 
SUM(online_sales) "Roadster Matched Sales", 
SUM(online_sales) / NULLIF(SUM("Online Prospects"), 0) "Close Rate"
FROM base_online_data
GROUP BY 1
ORDER BY "Dealership"

