
where traffic as (
select *
from fact.mode_agg_daily_traffic_and_prospects
where date between current_date-14 and current_date-1
and type in ('Dealer Visitors','Online Express Traffic','Online Express SRP Traffic','Online Express VDP Traffic')
)

,dealer_visitors as (
select 
  dpid
, dpsk
, sum(count) dealer_visitors
from traffic
where type = 'Dealer Visitors'
group by 1,2)

,online_express_traffic as (
select 
  dpid
, dpsk
, sum(count) online_express_visitors
from traffic
where type = 'Online Express Traffic'
group by 1,2)



select 
dd.dpid
, dealer_visitors as "Dealer Visitors"
, et.online_express_visitors as "Online ES Visitors"

from date_dpid dd 
left join online_express_traffic et on et.dpid = dd.dpid 
left join dealer_visitors dt on dt.dpid = dd.dpid 

group by 1,2,3
