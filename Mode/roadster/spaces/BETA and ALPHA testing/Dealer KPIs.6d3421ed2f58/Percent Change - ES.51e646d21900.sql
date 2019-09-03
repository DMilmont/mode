with weekly_count as (SELECT case when date_local>= (date_trunc('day', now()) - INTERVAL '7 Days') and date_local< (date_trunc('day', now())) then 'Current 7 Days'
            when date_local>= (date_trunc('day', now()) - INTERVAL '14 Days') then 'Past 7 Days' end as timeframe
      ,count(distinct distinct_id)
FROM fact.f_traffic_weekly
where  date_local>= (date_trunc('day', now()) - INTERVAL '14 Days')
and dpid='{{ dpid }}'
group by 1,CASE 
  WHEN is_in_store = true THEN 'In-Store'
  ELSE 'Online' END)
  
  select timeframe
  ,sum(count) as count
from weekly_count
group by 1