with details as (select distinct 'Past 30 days' AS month_year
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
where   date_local>= current_date-31
and  dpid='{{ dpid }}'
and session_type <> 'Dealer Admin'
group by 1,2,3
)


select month_year
      ,dpid
      ,session_type
      ,type
      ,sessions
      ,bounce
      ,bounce_rate
      ,new_user
      ,all_users
      ,new_user_ratio
      ,duration
      ,case when left(avg_session_duration_time,1)='0' then substr(avg_session_duration_time,2) else avg_session_duration_time end as avg_session_duration_time
      ,avg_session_duration_seconds
      ,pageviews
      ,round(pageviews_per_session,1) as pageviews_per_session
      ,round(bounce_rate*100) || '%' as bounce_rate_perc
from details

