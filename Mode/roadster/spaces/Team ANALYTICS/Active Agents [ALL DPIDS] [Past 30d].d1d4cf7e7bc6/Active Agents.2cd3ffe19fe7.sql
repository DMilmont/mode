
with sharecount AS
  (SELECT agent_id,
          count(1)
   FROM public.shared_express_vehicle
   WHERE timestamp > now() - '30 days'::interval
   GROUP BY 1) 

, activitycount as (
    SELECT 
      agent_id
      ,count(1)
      FROM public.user_events 
      where 
            agent_id is not null 
        and in_store = true 
        and timestamp > now() - '30 days'::interval 
      group by 1
)

   
/*   , sessioncount AS
  (SELECT agent_dbid,*
          --count(1) "days30",
          --max(session_count) "ever"
          
   FROM public.ga2_sessions
   WHERE agent_dbid is not null
     AND in_store = true
     AND timestamp > now() - '30 days'::interval
     --AND agent_dbid ~ '^[0-9]*$'
   GROUP BY 1) */
   
   ,printcopycount AS
  (SELECT agent_id,
          count(1)
   FROM public.user_events
   WHERE timestamp > now()- '30 days'::interval
     AND agent_id is not null
     AND name in('Print Share Details','Copy To Clipboard')
   GROUP BY 1)
   
   
SELECT dp.dpid,
       pa.department,
       pa.last_login_at ,
       activity.count AS "Activity(events) past 30d" ,
       sc.count AS "Shares past 30d" ,
       print.count AS "Prints/Copies past 30d" ,
       pa.first_name,
       pa.last_name,
       pa.email,
       pa.job_title,
       pa.created_at,
       sf.account_executive,
       sf.success_manager
FROM public.agents pa
left join public.dealer_partners dp  ON dp.id = pa.dealer_partner_id
left join fact.salesforce_dealer_info sf  ON sf.dpid = dp.dpid
left join sharecount sc  ON sc.agent_id = pa.id
left join activitycount activity  ON activity.agent_id = pa.id
left join printcopycount print   ON print.agent_id = pa.id
WHERE pa.status = 'Active'
  AND sf.status = 'Live'
  OR dp.status = 'Live'
ORDER BY dpid,pa.department ASC, last_login_at DESC