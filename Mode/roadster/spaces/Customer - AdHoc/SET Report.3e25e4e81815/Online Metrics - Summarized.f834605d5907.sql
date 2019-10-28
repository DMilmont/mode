WITH filter_for_dpids as (
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
), 

base_online_data as (
  SELECT *
  FROM report_layer.dg_online_metrics_monthly
  WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
  OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
  AND "Date" IN (select generate_series(date_trunc('month', now()) - '6 mons'::interval, date_trunc('month', now()), '1 month'))
)
----

,almost_final as (
SELECT "Dealership", 
"Date"::text,
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
WHERE "Date"  >= (date_trunc('month', now()) - '2 months'::interval)
GROUP BY 1,2
ORDER BY "Dealership", "Date"::text
)

SELECT
CASE WHEN "Dealership" ILIKE '%Percentile%' THEN 'Top Dealers' ELSE 'Your Rooftops' END as "Title",
"Dealership", 
"Date"::text, 
CASE WHEN "Dealer Visitors" = 0 OR "Dealer Visitors" IS NULL THEN 'Traffic Unavailable' ELSE "Dealer Visitors"::text END "Dealer Visitors (text)", 
"Dealer Visitors",
"Express Visitors",
"Online Express Ratio",
"Prospect Conversion", 
"Online Prospects",
"Online Shares", 
"Online Orders",
"Roadster Matched Sales",
"Close Rate"
FROM almost_final
WHERE "Dealership" <> 'Lexus Of Pleasanton'
