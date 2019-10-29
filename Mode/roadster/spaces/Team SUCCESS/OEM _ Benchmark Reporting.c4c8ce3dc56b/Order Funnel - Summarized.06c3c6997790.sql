
with dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE (primary_make in ({{ primary_make }})
AND dp.state IN ({{ state }}))
OR 
dp.dpid IN ( {{ dpid }} )
), 

base_order_data as (
  SELECT rr.*,
  dp.dpid,
  dp.primary_make
  FROM report_layer.dg_order_step_metrics rr
  LEFT JOIN dealer_partners dp ON rr."Dealership" = initcap(dp.name)
  WHERE ("Dealership" IN (SELECT initcap(name) FROM dpids))
)

SELECT 
'Measures' "Measures",
CASE 
  WHEN dpid IN ({{ dpid }}) THEN 'Custom Group' 
  WHEN primary_make IN ({{ primary_make }}) THEN 'OEM Rooftop'
  ELSE '' END grouper,
b.*
FROM base_order_data b
WHERE "Date" IN ({{choose_your_date_range}})





