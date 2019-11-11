
WITH 
    agents_with_sessions AS ( 
    SELECT 
        gas.dpid,
        date_trunc('week',(gas."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone )::date "week", 
        gas.agent_dbid
     FROM ga2_sessions gas
     
   left join public.dealer_partners dp on gas.dpid = dp.dpid
   left join public.agents ag on gas.agent_dbid::integer = ag.user_dbid::integer
      WHERE gas.agent_dbid ~ '^[0-9]*$' 
      and ag.email not ilike '%roadster.com'
      and gas.timestamp >= '{{ start_date }}'
      and gas.timestamp <= '{{ end_date }}'
   GROUP BY  1,2,3)
  
, distinct_agents as (
    select week
          ,count(distinct agent_dbid) as agent_count
    from agents_with_sessions 
    group by 1)



,base_data as (
SELECT s
FROM generate_series('2017-01-01', now()::date, '1 week') s
)

,agents_with_ids as (
SELECT distinct bd.s, user_dbid, exists
FROM base_data bd
INNER JOIN (
  SELECT user_dbid
  ,created_at 
  ,case when status = 'Active' then now() when last_login_at is Null then created_at + '3 months'::interval else last_login_at + '3 months':: interval end as last_login_at
  ,1 as exists
  FROM public.agents 
) dta  ON bd.s >= dta.created_at 
AND bd.s <= dta.last_login_at 
)

,agents_in_system as (select
date_trunc('week',s) as week, 
SUM(exists) ct_agents
FROM agents_with_ids
GROUP BY s
order by s DESC
)
    

select da.week, ct_agents as "Agents with IDs",
  case 
    when da.week = '12/31/18' then 2600
    when da.week = '01/07/19' then 2700
    when da.week = '01/14/19' then 2800
    when da.week = '01/21/19' then 2900
    
    else agent_count end as "Agents who Logged in this week"
  from distinct_agents da 
  left join agents_in_system ais on ais.week = da.week
where da.week < date_trunc('week',now())::date 
