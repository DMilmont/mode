with details as (select distinct 'Past 30 days' AS month_year
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
where   date_local >= (date_trunc('day', now()) - INTERVAL '31 Days')
and date_local::date<  date(now()::date AT TIME ZONE 'PST')
and  dpid='{{ dpid }}'
-- and COALESCE(new_used,'x')<>'Did Not Visit Inventory on Express'
-- and  coalesce(srp_vdp,'x')<>'Did Not Visit Inventory on Express'
group by 1,2,3
)


select month_year
      ,dpid
      ,session_type
      ,type
      ,sessions
      ,bounce
      ,bounce_rate

      ,duration
      ,case when left(avg_session_duration_time,1)='0' then substr(avg_session_duration_time,2) else avg_session_duration_time end as avg_session_duration_time
      ,avg_session_duration_seconds
      ,pageviews
      ,round(pageviews_per_session,1) as pageviews_per_session
      ,round(bounce_rate*100) || '%' as bounce_rate_perc
from details
--- Ability to handle when Dealer Traffic is not captured
union
select distinct month_year
      ,dpid
      ,'Dealer + Express Site'
      ,type
      ,0
      ,0
      ,0
      ,0
      ,'0'
      ,0
      ,0
      ,0
      ,'0'
from details
where case when 'Dealer + Express Site' in (select session_type from details) then 0 else 1 end =1
union
select distinct month_year
      ,dpid
      ,'Dealer Main Site Only'
      ,type
      ,0
        ,0
      ,0
      ,0
      ,'0'
      ,0
      ,0
      ,0
      ,'0'
from details
where case when 'Dealer Main Site Only' in (select session_type from details) then 0 else 1 end =1