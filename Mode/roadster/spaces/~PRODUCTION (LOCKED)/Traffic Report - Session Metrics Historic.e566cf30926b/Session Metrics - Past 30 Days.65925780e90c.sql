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
from report_layer.session_metrics_past30days
where  dpid='{{ dpid }}'
and session_type <> 'Dealer Admin'



