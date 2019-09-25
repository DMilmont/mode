
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
       COALESCE(pa.department, '<MISSING>') as "Department",
       COALESCE(to_char(pa.last_login_at, 'Dy Mon DD, YYYY - HH12:MIAM'), '<NEVER>') as "Last Login",
       date_part('day' , now() - pa.last_login_at) as "days ago",
       activity.count AS "Activity(events) past 30d" ,
       sc.count AS "Shares past 30d" ,
       print.count AS "Prints/Copies past 30d" ,
       pa.first_name as "First Name",
       pa.last_name as "Last Name",
       pa.email,
       COALESCE(pa.job_title,'<MISSING>') as "Job Title",
       pa.created_at,
       sf.account_executive as "Sales Director",
       sf.success_manager as "Success Manager",
       sf.dealer_group,
       case when pa.last_login_at > now() - '30 days':: interval then 'Past 30 Days'
            when pa.last_login_at > now() - '90 days':: interval then '31 - 90 Days Ago'
            when pa.last_login_at > now() - '365 days':: interval then '91 - 365 Days Ago'
            when pa.last_login_at is null then 'Never'
       else '>365 days' end as "Login within"
       
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