





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

,online_express_traffic_ya as (
select 
  date + '52 weeks'::interval as date
, dpid
, count(distinct distinct_id)  express_visitors
from fact.f_traffic 
where date >= ('{{ start_date }}'::date - '52 weeks'::interval)
and date <= ('{{ end_date }}'::date - '52 weeks'::interval)
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


,prospects_ya as (
select 
  step_date_utc + '52 weeks'::interval  as date
, dpid
, count(distinct distinct_id) prospects
from fact.f_prospect
where step_date_utc >= ('{{ start_date }}'::date - '52 weeks'::interval)
and step_date_utc <= ('{{ end_date }}'::date - '52 weeks'::interval)
group by 1,2)


select 
  dd.date::date as "Date"
, dd.dpid
, et.express_visitors as "Express Visitors"
, et_ya.express_visitors as "Express Visitors - year ago"
, op.prospects as "Prospects"
, op_ya.prospects as "Prospects - year ago"
, sum(case when et.express_visitors >0 then 1 else 0 end) as "DPID_OEV"
, sum(case when et_ya.express_visitors >0 then 1 else 0 end) as "DPID_OEV_YA"
, sum(case when op.prospects >0 then 1 else 0 end) as "DPID_OP"
, sum(case when op_ya.prospects >0 then 1 else 0 end) as "DPID_OP_YA"

from date_dpid dd 
left join online_express_traffic et on et.date = dd.date and et.dpid = dd.dpid 
left join online_express_traffic_ya et_ya on et_ya.date = dd.date and et_ya.dpid = dd.dpid 
left join prospects op on op.dpid = dd.dpid and op.date = dd.date 
left join prospects_ya op_ya on op_ya.dpid = dd.dpid and op_ya.date = dd.date 

--where et.express_visitors > 0  

group by 1,2,3,4,5,6

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