
with date_dpid as (
select c.date, dp.dealer_group, dp.dpid, l1, l2,dp.name, dp.tableau_secret as dpsk, primary_make
from fact.d_cal_date c
cross join (
  select distinct dps.dpid, dealer_group, l1, l2,tableau_secret, dps.name, primary_make
  from dealer_partners dps
  INNER JOIN public.custom_dealer_grouping cdg ON cdg.dpid = dps.dpid
  where cdg.dealer_group = 'Lithia'
  
  ) dp 
--  where dpid not like '%demo%')dp 
where c.date >= '{{ start_date }}'  
and c.date <= '{{ end_date }}'
group by 1,2,3,4,5,6,7,8),

filter_for_dealer_group as (
  SELECT *
  FROM public.custom_dealer_grouping
  WHERE dealer_group = 'Lithia'
)

,online_express_traffic as (
select 
  a.date
, a.dpid
, dpsk
, sum(count) online_express_visitors
from fact.mode_agg_daily_traffic_and_prospects a
INNER JOIN filter_for_dealer_group fdg ON a.dpid = fdg.dpid
where type = 'Online Express Traffic'
and date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
AND dealer_group IS NOT NULL
group by 1,2,3)

,online_express_srp_traffic as (
select 
  b.date
, b.dpid
, dpsk
, sum(count) as online_express_srp_visitors
from fact.mode_agg_daily_traffic_and_prospects b
INNER JOIN filter_for_dealer_group fdg ON b.dpid = fdg.dpid
where type = 'Online Express SRP Traffic'
and date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
and dealer_group IS NOT NULL
group by 1,2,3)


,online_express_vdp_traffic as (
select 
  c.date
, c.dpid
, dpsk
, sum(count) as online_express_vdp_visitors
from fact.mode_agg_daily_traffic_and_prospects c
INNER JOIN filter_for_dealer_group fdg ON c.dpid = fdg.dpid
where type = 'Online Express VDP Traffic'
and date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
and dealer_group IS NOT NULL
group by 1,2,3)

,online_prospects as (
select 
  d.date
, d.dpid
, dpsk
, sum(count) online_prospects
from fact.mode_agg_daily_traffic_and_prospects d
INNER JOIN filter_for_dealer_group fdg ON d.dpid = fdg.dpid
where type = 'Online Prospects'
and date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
and dealer_group IS NOT NULL
group by 1,2,3)

, 

final_data as (
select 
  dd.date::date as "Date"
, dd.dealer_group
, dd.dpid
, dd.primary_make
, dd.dpsk
, dd.l1
, dd.l2
, dd.name as "Dealership"
, dt.visitors as "Dealer Visitors"
, et.online_express_visitors as "Online Express Visitors"
, online_express_srp_visitors as "Online Express SRP Visitors"
, online_express_vdp_visitors as "Online Express VDP Visitors"
, op.online_prospects as "Online Prospects"
, ROUND((et.online_express_visitors::numeric/dt.visitors::numeric), 2) as "Online Express Ratio"
, ROUND((op.online_prospects::numeric/et.online_express_visitors::numeric), 2) as "Conversion to Online Prospect"
from date_dpid dd 
left join online_express_traffic et on et.date = dd.date and et.dpid = dd.dpid 
left join fact.agg_daily_dealer_traffic dt on dt.dpid = dd.dpid and dt.date = dd.date
left join online_express_vdp_traffic vdp on vdp.date = dd.date and vdp.dpid = dd.dpid
left join online_express_srp_traffic srp on srp.date = dd.date and srp.dpid = dd.dpid
left join online_prospects op on op.dpid = dd.dpid and op.date = dd.date 
group by 1,2,3,4,5,6,7,8,9,10,11,12,13)

SELECT "Date",
dealer_group "Dealer Group", 
primary_make "Primary Make",
"Dealership",
l1 "Dealer Subgrouop 1",
l2 "Dealer Subgroup 2",
COALESCE("Dealer Visitors", 0.0) "Dealer Visitors", 
COALESCE("Online Express Visitors", 0.0) "Online Express Visitors", 
COALESCE("Online Express SRP Visitors", 0.0) "Online Express SRP Visitors", 
COALESCE("Online Express VDP Visitors", 0.0) "Online Express VDP Visitors", 
COALESCE("Online Prospects", 0.0) "Online Prospects", 
COALESCE("Online Express Ratio", 0.0) "Online Express Ratio", 
COALESCE("Conversion to Online Prospect", 0.0) "Conversion to Online Prospect"
FROM final_data
ORDER BY "Date" DESC, dpid DESC


{% form %}

start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}
  description: Select a start date up to previous 3 months

end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  description: Select an end date up to yesterday

{% endform %}