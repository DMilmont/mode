with details as (select date_trunc('month'::text, date_local) AS month_year
                ,dpid
                ,session_type
                ,'Main Site or Express Site' as type
                ,sum(sessions) as sessions
                ,sum(bounce) as bounce
                ,round(sum(bounce)::numeric/sum(sessions),2) as bounce_rate
                ,sum(duration) as duration
              ,to_char((round(sum(duration)::numeric/sum(sessions),2)|| ' second')::interval,'MI:SS') as avg_session_duration_time
                ,round(sum(duration)::numeric/sum(sessions),2) avg_session_duration_seconds
                ,sum(pageviews) as pageviews
                ,round(sum(pageviews)::numeric/sum(sessions),2) as pageviews_per_session
from fact.agg_session_metrics
where    dpid='{{ dpid }}'
and  case when extract( day from current_date)>=5 then 1
              when date_trunc('month'::text, current_date)>date_local then 1
              else 0 end =1
group by 1,2,3
)

select month_year
      ,dpid
      ,session_type
      ,type
      ,case when session_type='Dealer + Express Site' then null else bounce_rate end as bounce_rate
      ,duration
      ,avg_session_duration_seconds
      ,round(pageviews_per_session,1) as pageviews_per_session
from details
where dpid='{{ dpid }}'
AND month_year>= (date_trunc('day', now()) - INTERVAL '5 Months')

