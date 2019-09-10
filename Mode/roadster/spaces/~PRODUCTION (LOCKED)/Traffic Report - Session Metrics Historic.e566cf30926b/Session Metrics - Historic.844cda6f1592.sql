select month_year
      ,dpid
      ,session_type
      ,type
      ,case when session_type='Dealer + Express Site' then null else bounce_rate end as bounce_rate
      ,duration
      ,avg_session_duration_seconds
      ,round(pageviews_per_session,1) as pageviews_per_session
from fact.agg_monthly_session_metrics
where dpid='{{ dpid }}'
and session_type <> 'Dealer Admin'


