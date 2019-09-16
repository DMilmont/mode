
/*
with date_dpid as (
select c.date, dp.dpid, dp.name, dp.tableau_secret as dpsk
from fact.d_cal_date as c
cross join (
  select distinct dpid, tableau_secret, name from dealer_partners  ) dp
--  where dpid not like '%demo%')dp 
where c.date >= '{{ start_date }}'  
and c.date <= '{{ end_date }}'
group by 1,2,3,4)
*/

with date_dpid as (
select distinct date
,dpid
from fact.f_traffic
where date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
and dpid not ilike '%demo%'
)


,online_express_traffic as (
select 
  date
, dpid
, count(distinct distinct_id)  express_visitors
from fact.f_traffic 
where date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
and is_in_store = false
group by 1,2)

,instore_express_traffic as (
select 
  date
, dpid
, count(distinct distinct_id)  express_visitors
from fact.f_traffic 
where date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
and is_in_store = true
group by 1,2)


,online_prospects as (
select 
  step_date_utc as date
, dpid
, count(distinct distinct_id) prospects
from fact.f_prospect
where step_date_utc >= '{{ start_date }}'
and step_date_utc <= '{{ end_date }}'
and is_in_store = false
group by 1,2)

,instore_prospects as (
select 
  step_date_utc as date
, dpid
, count(distinct distinct_id) prospects
from fact.f_prospect
where step_date_utc >= '{{ start_date }}'
and step_date_utc <= '{{ end_date }}'
and is_in_store = true
group by 1,2)



, agtbl as (
select 
  dd.date::date as "date"
, sum(case when oet.express_visitors > 1 then 1 else 0 end) as dpids
, sum(oet.express_visitors) as "Online Express Visitors"
, sum(iet.express_visitors) as "Instore Express Visitors"
, sum(opro.prospects) as "Online Prospects"
, sum(ipro.prospects) as "Instore Prospects"

from date_dpid dd 
left join online_express_traffic oet on oet.date = dd.date and oet.dpid = dd.dpid 
left join instore_express_traffic iet on iet.date = dd.date and iet.dpid = dd.dpid 
left join online_prospects opro on opro.dpid = dd.dpid and opro.date = dd.date 
left join instore_prospects ipro on ipro.dpid = dd.dpid and ipro.date = dd.date 

group by 1)

select 
  date,
  dpids, 
  case when date >= '2018-07-16' and date <= '2018-12-10' then "Online Express Visitors" / 2 else "Online Express Visitors" end as "Online Express Visitors",
  "Instore Express Visitors",
  "Online Prospects",
  "Instore Prospects",
  case when date >= '2018-07-16' and date <= '2018-12-10' then round("Online Express Visitors" / dpids / 2,1) else round("Online Express Visitors" / dpids,2) end as "AVG Online Express Visitors",
  round("Instore Express Visitors" / dpids,2) "Instore Express Visitors per DP",
  round("Instore Prospects" / dpids,2) "Instore Prospects per DP",
  round("Online Prospects" / dpids,2) "Online Prospects per DP"
  
  from agtbl

