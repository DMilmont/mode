WITH min_session_id AS
( SELECT distinct_id
        ,min(session_id) as min_session_id
  FROM fact.f_sessions
  WHERE date_local >= '{{ start_date }}'  
and date_local <= '{{ end_date }}'  
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
WHERE date_local >= '{{ start_date }}'  
and date_local <= '{{ end_date }}'  
AND ga.dpid='{{ dpid }}'
and COALESCE(session_type,'x')<>'Dealer Admin'
 and COALESCE(new_used,'x')<>'Did Not Visit Inventory on Express'
and  coalesce(srp_vdp,'x')<>'Did Not Visit Inventory on Express'
group by 1,2,3,4,5,6,7,8,9,10
),
detail_breakout as (SELECT 'Day' as type
      ,* 
FROM details     

UNION 
select 'Week' as type
      ,dpid
      ,medium
      ,source
      ,channel_grouping
      ,session_type
      ,prospect_flag
      ,new_used
      ,srp_vdp
      ,in_store_flag
      ,date_trunc('week',date)
      ,sum(bounce)
      ,sum(sessions)
      ,sum(users)
      ,sum(new_users)
      ,sum(pageviews)
      ,sum(duration)
      ,title
FROM details
GROUP by 2,3,4,5,6,7,8,9,10,11,title

UNION
select 'Month' as type
      ,dpid
      ,medium
      ,source
      ,channel_grouping
      ,session_type
      ,prospect_flag  
      ,new_used
      ,srp_vdp
      ,in_store_flag
      ,date_trunc('month',date)
      ,sum(bounce)
      ,sum(sessions)
      ,sum(users)
      ,sum(new_users)
      ,sum(pageviews)
      ,sum(duration)
      ,title
FROM details
GROUP by 2,3,4,5,6,7,8,9,10,11,title
)
SELECT * 
FROM detail_breakout
WHERE TYPE= '{{ type }}' 
  
{% form %}


type:
    type: select
    default: Day
    options: [Day, Week,Month]


start_date:
  type: date
  default: '2019-08-09'
  description: Data available starting May 10th (GA Limitation)

end_date: 
  type: date
  default: '2019-09-09'
  description: Data available until July 20th (Testing Reasons)

{% endform %}