with date_dpid as (
select c.date, dp.dpid, dp.name, dp.tableau_secret as dpsk
from fact.d_cal_date c
cross join (
  select distinct dpid, tableau_secret, name from dealer_partners 
  where  dpid = 'lhmnissan104' ) dp 
where date >= '2019-08-01' 
and date <= '2019-09-10'
group by 1,2,3,4)

,dealer_visitors as (
select 
  date
, dpid
, dpsk
, sum(count) dealer_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Dealer Visitors'
and date >= '2019-08-01' 
and date <= '2019-09-10'
and dpid = 'lhmnissan104'
group by 1,2,3)

,online_express_traffic as (
select 
  date
, dpid
, dpsk
, sum(count) online_express_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express Traffic'
and date >= '2019-08-01' 
and date <= '2019-09-10'
and dpid = 'lhmnissan104'
group by 1,2,3)



,online_express_srp_traffic as (
select 
  date
, dpid
, dpsk
, sum(count) as online_express_srp_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express SRP Traffic'
and date >= '2019-08-01' 
and date <= '2019-09-10'
and dpid = 'lhmnissan104'
group by 1,2,3)


,online_express_vdp_traffic as (
select 
  date
, dpid
, dpsk
, sum(count) as online_express_vdp_visitors
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Express VDP Traffic'
and date >= '2019-08-01' 
and date <= '2019-09-10'
and dpid = 'lhmnissan104'
group by 1,2,3)

,online_prospects as (
select 
  date
, dpid
, dpsk
, sum(count) online_prospects
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Prospects'
and date >= '2019-08-01' 
and date <= '2019-09-10'
and dpid = 'lhmnissan104'
group by 1,2,3)

,online_orders as (
select 
  date
, dpid
, dpsk
, sum(count) online_orders
from fact.mode_agg_daily_traffic_and_prospects
where type = 'Online Orders'
and date >= '2019-08-01' 
and date <= '2019-09-10'
and dpid = 'lhmnissan104'
group by 1,2,3)

,instore_shares as (
select 
  date
, dpid
, dpsk
, sum(count) instore_shares
from fact.mode_agg_daily_traffic_and_prospects
where type = 'In-Store Shares'
and date >= '2019-08-01' 
and date <= '2019-09-10'
and dpid = 'lhmnissan104'
group by 1,2,3),

detail as (
select 
  dd.date::date as "Date"
, dd.dpid
, dd.dpsk
, dd.name as "Dealership"
, dt.dealer_visitors as "Dealer Visitors"
, et.online_express_visitors as "Online Express Visitors"
, online_express_srp_visitors as "Online Express SRP Visitors"
, online_express_vdp_visitors as "Online Express VDP Visitors"
, op.online_prospects as "Online Prospects"
, oo.online_orders as "Online Orders"
, iss.instore_shares as "In-Store Shares"
, (et.online_express_visitors::numeric/dt.dealer_visitors::numeric) as "Online Express Ratio"
, (op.online_prospects::numeric/et.online_express_visitors::numeric) as "Conversion to Online Prospect"
, round(((et.online_express_visitors::numeric/dt.dealer_visitors::numeric)*100),1) as "Online Express Ratio %"
, round(((op.online_prospects::numeric/et.online_express_visitors::numeric)*100),1) as "Conversion to Online Prospect %"
from date_dpid dd 
left join online_express_traffic et on et.date = dd.date and et.dpid = dd.dpid 
left join dealer_visitors dt on dt.dpid = dd.dpid and dt.date = dd.date
left join online_express_vdp_traffic vdp on vdp.date = dd.date and vdp.dpid = dd.dpid
left join online_express_srp_traffic srp on srp.date = dd.date and srp.dpid = dd.dpid
left join online_prospects op on op.dpid = dd.dpid and op.date = dd.date 
left join online_orders oo on oo.dpid = dd.dpid and oo.date = dd.date 
left join instore_shares iss on iss.dpid = dd.dpid and iss.date = dd.date 
where dd.dpid='lhmnissan104'
and  dd.date::date>='2019-08-01'
group by 1,2,3,4,5,6,7,8,9,10,11

)

select case when "Date"<='2019-08-17' and "Date">='2019-08-01'then 'Native Site SRP'
            else 'Express Store SRP' end as timeframe
      ,sum("Online Express Visitors") as "Online Express Visitors"
      ,sum("Online Prospects") as "Online Prospects"
      ,sum("Online Orders") as "Online Orders"
from detail
group by 1