with details as (select distinct date_trunc('month'::text, date_local) AS month_year
                ,dpid
                ,session_type
                ,'Main Site or Express Site' as type
                ,count(1) as sessions
                ,sum(case when bounce=true then 1 else 0 end ) as bounce
                ,round(sum(case when bounce=true then 1 else 0 end )::numeric/count(1),2) as bounce_rate
                ,sum(case when session_count=1 then 1 else 0 end) new_user
                ,count (distinct distinct_id) all_users
                ,round(sum(case when session_count=1 then 1 else 0 end)::numeric / count (distinct distinct_id),2) new_user_ratio
                ,sum(duration) as duration
              ,to_char((round(sum(duration)::numeric/count(1),2)|| ' second')::interval,'MI:SS') as avg_session_duration_time
                ,round(sum(duration)::numeric/count(1),2) avg_session_duration_seconds
                ,sum(pageviews) as pageviews
                ,round(sum(pageviews)::numeric/count(1),2) as pageviews_per_session
from fact.f_sessions
where    case when extract( day from current_date)>=5 then 1
              when date_trunc('month'::text, current_date)>date_local then 1
              else 0 end =1
and dpid='{{ dpid }}'
and session_type <> 'Dealer Admin'
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


