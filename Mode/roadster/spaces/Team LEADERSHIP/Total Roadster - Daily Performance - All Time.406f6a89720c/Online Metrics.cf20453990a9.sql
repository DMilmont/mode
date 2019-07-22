

with date_dpid as (
select c.date, dp.dpid, dp.name, dp.tableau_secret as dpsk
from fact.d_cal_date as c
cross join (
  select distinct dpid, tableau_secret, name from dealer_partners  ) dp
--  where dpid not like '%demo%')dp 
where c.date >= '{{ start_date }}'  
and c.date <= '{{ end_date }}'
group by 1,2,3,4)


,online_express_traffic as (
select 
  date
, dpid
, count(distinct distinct_id)  express_visitors
from fact.f_traffic 
where date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
group by 1,2)


,prospects as (
select 
  step_date_utc as date
, dpid
, count(distinct distinct_id) prospects
from fact.f_prospect
where step_date_utc >= '{{ start_date }}'
and step_date_utc <= '{{ end_date }}'
group by 1,2)




, agtbl as (
select 
  dd.date::date as "date"
, sum(case when et.express_visitors > 1 then 1 else 0 end) as dpids
, sum(et.express_visitors) as "Express Visitors"
, sum(op.prospects) as "Prospects"

from date_dpid dd 
left join online_express_traffic et on et.date = dd.date and et.dpid = dd.dpid 
left join prospects op on op.dpid = dd.dpid and op.date = dd.date 

group by 1)

select 
  date,
  dpids, 
  case when date >= '2018-07-16' and date <= '2018-12-10' then "Express Visitors" / 2 else "Express Visitors" end as "Express Visitors",
  "Prospects",
  "Prospects" * .02134 "Estimated Roadster Sales",
  case when date >= '2018-07-16' and date <= '2018-12-10' then round("Express Visitors" / dpids / 2,1) else round("Express Visitors" / dpids,2) end as "AVG Express Visitors",
  round("Prospects" / dpids,2) "Prospects per DP"
  
  from agtbl



{% form %}

start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}
  description: Data available for previous 3 months

end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  description: Data available for previous 3 months

{% endform %}