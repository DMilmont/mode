with filter_for_dpids as (
  -- Generate the Dealer Group associated with the dpid param filter
  SELECT DISTINCT di.dealer_group
  FROM fact.salesforce_dealer_info di
  INNER JOIN public.dealer_partners dp on di.dpid = dp.dpid
  WHERE di.dpid = '{{ dpid }}' AND dp.tableau_secret = {{ dpsk }}
),

filter_for_dealer_group  as (
SELECT DISTINCT di.dpid, dealer_group, dp.tableau_secret
FROM fact.salesforce_dealer_info di
LEFT JOIN public.dealer_partners dp ON di.dpid = dp.dpid
WHERE dealer_group = (SELECT * FROM filter_for_dpids)
),

date_dpid as (
select c.date, dp.dpid,dp.name, dp.tableau_secret as dpsk, primary_make, dealer_group
from fact.d_cal_date c
cross join (
  select distinct dps.dpid, dps.tableau_secret, dps.name, primary_make, dealer_group
  from dealer_partners dps
  INNER JOIN filter_for_dealer_group fdg ON dps.dpid = fdg.dpid AND dps.tableau_secret = fdg.tableau_secret
  ) dp 
--  where dpid not like '%demo%')dp 
where c.date >= (NOW() - INTERVAL'3 months')  
and c.date <= (NOW() - INTERVAL'1 day')
group by 1,2,3,4,5,6)

,online_express_traffic as (
select 
  a.date
, a.dpid
, dpsk
, 'Online Express Visitors' metric_type
, sum(count) as value
from fact.mode_agg_daily_traffic_and_prospects a
INNER JOIN filter_for_dealer_group fdg ON a.dpid = fdg.dpid
where type = 'Online Express Traffic'
and date >= (NOW() - INTERVAL'3 months') 
and date <= (NOW() - INTERVAL'1 day')
AND dealer_group IS NOT NULL
group by 1,2,3, 4)

,online_express_srp_traffic as (
select 
  b.date
, b.dpid
, dpsk
, 'Online Express SRP' metric_type
, sum(count) as value
from fact.mode_agg_daily_traffic_and_prospects b
INNER JOIN filter_for_dealer_group fdg ON b.dpid = fdg.dpid
where type = 'Online Express SRP Traffic'
and date >= (NOW() - INTERVAL'3 months') 
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3, 4)


,online_express_vdp_traffic as (
select 
  c.date
, c.dpid
, dpsk
, 'Online Express VDP' metric_type
, sum(count) as value
from fact.mode_agg_daily_traffic_and_prospects c
INNER JOIN filter_for_dealer_group fdg ON c.dpid = fdg.dpid
where type = 'Online Express VDP Traffic'
and date >= (NOW() - INTERVAL'3 months') 
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3, 4)

,online_prospects as (
select 
  d.date
, d.dpid
, dpsk
, 'Online Prospects' metric_type
, sum(count) as value
from fact.mode_agg_daily_traffic_and_prospects d
INNER JOIN filter_for_dealer_group fdg ON d.dpid = fdg.dpid
where type = 'Online Prospects'
and date >= (NOW() - INTERVAL'3 months') 
and date <= (NOW() - INTERVAL'1 day')
and dealer_group IS NOT NULL
group by 1,2,3, 4),

final_data as (
SELECT * 
FROM online_express_traffic
UNION ALL
SELECT *
FROM online_express_srp_traffic
UNION ALL 
SELECT *
FROM online_express_vdp_traffic
UNION ALL
SELECT *
FROM online_prospects
UNION ALL
SELECT dt.date, dt.dpid, 0 as dpsk,'Dealer Visitors' metric_type, visitors as value
FROM fact.agg_daily_dealer_traffic dt
INNER JOIN filter_for_dealer_group fdg ON dt.dpid = fdg.dpid
WHERE date >= (NOW() - INTERVAL'3 months') 
and date <= (NOW() - INTERVAL'1 day')
AND dealer_group = '{{ dealer_group }}'
)

SELECT fd.date, fd.dpid, dd.dealer_group, dd.primary_make, fd.metric_type, fd.value
FROM final_data fd
LEFT JOIN date_dpid dd ON dd.dpid = fd.dpid AND dd.date = fd.date