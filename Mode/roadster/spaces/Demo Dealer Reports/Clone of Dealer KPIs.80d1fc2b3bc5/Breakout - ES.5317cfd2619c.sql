SELECT CASE 
  WHEN is_in_store = true THEN 'In-Store'
  ELSE 'Online' END AS instore_name
      ,count(distinct distinct_id)
      , CASE 
  WHEN is_in_store = true THEN 'In-Store'
  ELSE 'Online' END  || '<br> ('|| count(distinct distinct_id) ||')' as label
FROM fact.f_traffic_weekly
where  date_local>= (date_trunc('day', now()) - INTERVAL '7 Days')
and date_local< (date_trunc('day', now()))
and dpid='{{ dpid }}'
group by 1