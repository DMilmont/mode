  with filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  -- Sets up the entire query. Needs the dpsk and the dpid from params to work
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info_SET di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
)


,dpids as (
SELECT DISTINCT name
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END IN (SELECT * FROM filter_for_dpids)
AND dp.status = 'Live'
--and dealer_group <> dp.name
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
AND name != '' and name <> 'Lexus Of Pleasanton'
ORDER BY date