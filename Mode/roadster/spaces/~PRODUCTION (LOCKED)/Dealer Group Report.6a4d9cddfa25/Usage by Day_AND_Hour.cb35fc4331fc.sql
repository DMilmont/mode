WITH filter_for_dpids as (
  SELECT DISTINCT CASE WHEN di.dealer_group IS NULL THEN dealer_name ELSE di.dealer_group END dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid IN ({{ dpid }})
)

,dpids as (
SELECT DISTINCT dp.dpid
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE CASE WHEN dealer_group IS NULL THEN dealer_name ELSE dealer_group END IN (SELECT * FROM filter_for_dpids)
--and dealer_group <> dp.name
)

SELECT dp.dpid, timestamp AT TIME ZONE dp.timezone date,
       EXTRACT(hour FROM timestamp AT TIME ZONE dp.timezone)::text hour_of_day,
       day_of_week,
       1 ct
FROM ga2_sessions gs
LEFT JOIN dealer_partners dp ON gs.dpid = dp.dpid
LEFT JOIN fact.day_of_week_conversion dow ON EXTRACT(dow from gs.timestamp AT TIME ZONE dp.timezone) = dow.number
INNER JOIN dpids d ON gs.dpid = d.dpid
WHERE (timestamp AT TIME ZONE dp.timezone) < (Current_date - '1 day'::interval)
AND (timestamp AT TIME ZONE dp.timezone) >= (CURRENT_DATE - '15 days'::interval)

