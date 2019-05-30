with traffic as ( select *
from fact.mode_agg_daily_traffic_and_prospects
where date between current_date-8 and current_date-1
and type in ('Dealer Visitors','Online Express Traffic')
)

,dealer_visitors as (
select  dpid, sum(count) dealer_visitors "Dealer Website Visitors"
from traffic
where type = 'Dealer Visitors'
group by 1)

,online_express_traffic as (
select   dpid, sum(count) online_express_visitors "Online ES Visitors"
from traffic
where type = 'Online Express Traffic'
group by 1)

,dpids as (
select distinct dpid
from traffic
group by 1)

select 
dpids.dpid
, dealer_visitors as "Dealer Visitors"
, et.online_express_visitors as "Online ES Visitors"

from  dpids 
left join online_express_traffic et on et.dpid = dpids.dpid 
left join dealer_visitors dt on dt.dpid = dpids.dpid 

group by 1,2,3
