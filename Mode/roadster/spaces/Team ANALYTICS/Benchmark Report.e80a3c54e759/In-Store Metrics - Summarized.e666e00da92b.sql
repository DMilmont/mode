
WITH dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE (primary_make in ({{ primary_make }})
AND dp.state IN ({{ state }}))
OR 
(dp.dpid IN ( {{ dpid }} ))
--and dealer_group <> dp.name
),

custom_group as (
    SELECT
    initcap(name) dealer,
    CASE WHEN dpid IN ({{ dpid }}) THEN 'Custom Group' ELSE '' END grouper
    FROM dealer_partners 
)

,instore_data as (
SELECT CASE WHEN "Dealership" ILIKE '%Percentile%' THEN 'Top Rooftops' ELSE custom_group.grouper END custom_grouper, mm.*
FROM report_layer.dg_in_store_metrics_monthly mm 
LEFT JOIN custom_group ON mm."Dealership" = custom_group.dealer
WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids)
OR "Dealership" IN ('50th Percentile Dealer Groups', '75th Percentile Dealer Groups', '90th Percentile Dealer Groups'))
AND "Date" IN ({{choose_your_date_range}})
)

SELECT
COALESCE(NULLIF(custom_grouper, ''), 'OEM Rooftop') custom_grouper, 
"Dealership", 
'Measures' "Measures",
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
GROUP BY 1,2, 3

