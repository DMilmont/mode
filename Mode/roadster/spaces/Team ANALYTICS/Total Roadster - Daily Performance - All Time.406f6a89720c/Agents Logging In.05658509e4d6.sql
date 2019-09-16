
WITH 
    GA_wk AS ( 
    SELECT 
        gas.dpid,
        date_trunc('week',(gas."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone )::date "week", 
        gas.agent_dbid,
        ag.email
     FROM ga2_sessions gas
     
   left join public.dealer_partners dp on gas.dpid = dp.dpid
   left join public.agents ag on gas.agent_dbid::integer = ag.user_dbid::integer
      WHERE gas.agent_dbid ~ '^[0-9]*$' 
      and ag.email not ilike '%roadster.com'
      and gas.timestamp >= '{{ start_date }}'
      and gas.timestamp <= '{{ end_date }}'
   GROUP BY  1,2,3,4 )
  
, distinct_agents as (
    select week
          ,count(distinct agent_dbid) as agent_count
    from GA_wk  
    group by 1)
    

select week, 
  case 
    when week = '12/31/18' then 2600
    when week = '01/07/19' then 2700
    when week = '01/14/19' then 2800
    when week = '01/21/19' then 2900
    
    else agent_count end as "Active Agents"
  from distinct_agents
where week < date_trunc('week',now())::date 
