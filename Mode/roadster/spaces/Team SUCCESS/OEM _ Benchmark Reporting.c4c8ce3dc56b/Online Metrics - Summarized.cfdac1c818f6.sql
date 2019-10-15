
WITH dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE (primary_make in ({{ primary_make }})
AND dp.state IN ({{ state }}))
OR
(dp.dpid IN ( {{ dpid }} ))
), 


custom_group as (
    SELECT
    initcap(name) dealer,
    CASE WHEN dpid IN ({{ dpid }}) THEN 'Custom Group' ELSE '' END grouper
    FROM dealer_partners 
),

base_online_data as (
SELECT 
CASE WHEN "Dealership" ILIKE '%Percentile%' THEN 'Top Rooftops' ELSE custom_group.grouper END custom_grouper, mm.*
FROM report_layer.dg_online_metrics_monthly mm 
LEFT JOIN custom_group ON mm."Dealership" = custom_group.dealer
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
AND "Date" IN ({{choose_your_date_range}})
)
----


SELECT 
COALESCE(NULLIF(custom_grouper, ''), 'OEM Rooftop') custom_grouper, 
"Dealership", 
'Measures' "Measures",
SUM("Dealer Visitors CLEANED") "Dealer Visitors",
SUM("Express Visitors CLEANED") "Express Visitors", 
SUM("Online Express Visitors") / NULLIF(SUM("Dealer Visitors"), 0) "Online Express Ratio",
SUM("Online Prospects")/NULLIF(SUM("Online Express Visitors"), 0) "Prospect Conversion",
SUM("Online Prospects") "Online Prospects",
SUM("online_shares") "Online Shares",
SUM("online_orders") "Online Orders", 
SUM(online_sales) "Roadster Matched Sales", 
SUM(online_sales) / NULLIF(SUM("Online Prospects"), 0) "Close Rate",
SUM("Online Express SRP Visitors") "SRP Visitors",
SUM("Online Express VDP Visitors") "VDP Visitors"
FROM base_online_data bod

GROUP BY 1,2, 3
ORDER BY "Dealership"

