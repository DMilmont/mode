with dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE primary_make in ({{ primary_make }})
)

-- Daily Query for past 3 months of data
SELECT 
  date,
  name "Dealership",
  type, 
  COUNT
FROM fact.mode_agg_daily_traffic_and_prospects ft
LEFT JOIN dealer_partners dp ON ft.dpid = dp.dpid
WHERE  name IN (SELECT initcap(name) FROM dpids)
AND type in ('Online Express SRP Traffic', 'Online Express VDP Traffic')
ORDER BY date