WITH min_session_id AS
( SELECT distinct_id
        ,min(session_id) as min_session_id
  FROM fact.f_sessions
  WHERE date_local >= (date_trunc('day', now()) - INTERVAL '31 Days')
and date_local< (date_trunc('day', now()))
AND dpid='{{ dpid }}'
GROUP BY distinct_id
),
details as (SELECT dpid
      ,medium
      ,source
      ,channel_grouping
      ,session_type
      ,prospect_flag
      ,new_used
      ,srp_vdp
      ,case when in_store is true then 'In-Store' else 'Online' end as in_store_flag
      ,date_local::date as date
      ,sum(case when bounce=true then 1 else 0 end ) as bounce
      ,count(1) as sessions
      ,sum(case when msi.min_session_id is not null then 1 else 0 end) as users
      ,sum(case when msi.min_session_id is not null and session_count=1 then 1 else 0 end) as new_users
      ,sum(pageviews) as pageviews
      ,sum(duration) as duration
      ,'Summary' as title
from fact.f_sessions ga
LEFT JOIN min_session_id msi on ga.session_id=msi.min_session_id
WHERE date_local >= (date_trunc('day', now()) - INTERVAL '31 Days')
and date_local::date<  date(now()::date AT TIME ZONE 'PST')
AND ga.dpid='{{ dpid }}'
group by 1,2,3,4,5,6,7,8,9,10
),
detail_breakout as (SELECT 'Day' as type
      ,* 
FROM details     


)
SELECT * 
FROM detail_breakout
where  COALESCE(session_type,'x')<>'Dealer Admin'
 and COALESCE(new_used,'x')<>'Did Not Visit Inventory on Express'
and  coalesce(srp_vdp,'x')<>'Did Not Visit Inventory on Express'


  