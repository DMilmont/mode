with agent_detail as (select time_frame 
                ,agent_name 
                ,agent_full_name
                ,COALESCE(job_title,'Job Title Missing') as job_title
                ,dpid
                ,name
                ,COUNT(distinct id) as EmailSent
                ,sum(Deliver_Check) as EmailDeliver
                ,sum(Open_Check) as EmailOpen
                ,sum(Click_Check)  as EmailClick
          from fact.zdemo_shares_detail
          where dpid='{{ dpid }}'
          and time_frame='Current 30 Days'
            GROUP BY 1,2,3,4,5,6
            HAVING COUNT(distinct id)<>0
      ),
      
agent_email as(  SELECT ad.dpid
            ,ad.name
            ,ad.agent_name as agent
            ,ad.agent_full_name
            ,ad.job_title
            ,e.*
      FROM agent_detail ad
          , LATERAL (
          VALUES
          ('Sent', ad.EmailSent)
          ,('Delivered', ad.EmailDeliver)
          ,('Opened', ad.EmailOpen)
          ,('Clicked', ad.EmailClick)
          ) e (email_event, cnt )
      ),

agent_metrics   as     (SELECT ae.dpid
            ,ae.name
            ,ae.agent_full_name
            ,ae.job_title || ' - ' || ae.agent  as "Agent"
            ,ae.job_title as "Title"
            ,ae.agent as agent_name
            ,CASE WHEN ae.email_event='Sent' then '1. Invalid Email' 
                  WHEN ae.email_event='Delivered' then '2. Delivered - Not Opened'
                  WHEN ae.email_event='Opened' then '3. Opened - Not Clicked'
                  WHEN ae.email_event='Clicked' then '4. Clicked' end as "E-Mail Status"
            ,case when ae.email_event='Sent' then ae.cnt-aed.cnt
                  when ae.email_event='Delivered' then ae.cnt-aeo.cnt
                  when ae.email_event='Opened' then ae.cnt-aec.cnt
                  else ae.cnt end as net_cnt
            
      FROM agent_email ae
      LEFT JOIN (select * from agent_email where email_event='Clicked') aec on ae.agent_full_name=aec.agent_full_name
       LEFT JOIN (select * from agent_email where email_event='Opened') aeo on ae.agent_full_name=aeo.agent_full_name
       LEFT JOIN (select * from agent_email where email_event='Delivered') aed on ae.agent_full_name=aed.agent_full_name
) ,
totals as (
            SELECT sum(net_cnt) as Total_shares
                  ,sum(case when "E-Mail Status"='4. Clicked' or "E-Mail Status"='3. Opened - Not Clicked' then net_cnt else 0 end) as Total_Opened
                  ,sum(case when "E-Mail Status"='4. Clicked' then net_cnt else 0 end) as Total_Clicked
            FROM agent_metrics
            
),
agent_score as (select agent_full_name
      ,sum(case when "E-Mail Status"='4. Clicked' or "E-Mail Status"='3. Opened - Not Clicked' or "E-Mail Status"='2. Delivered - Not Opened' then net_cnt end)::decimal/Total_shares as Shares_Contributed
      ,sum(case when "E-Mail Status"='4. Clicked' then net_cnt else 0 end)::decimal /Total_Clicked as Clicks_Contributed
      ,sum(case when "E-Mail Status"='4. Clicked' then net_cnt else 0 end)::decimal /sum(net_cnt) as Click_Rate
      ,sum(case when "E-Mail Status"='4. Clicked' or "E-Mail Status"='3. Opened - Not Clicked' or "E-Mail Status"='2. Delivered - Not Opened' then net_cnt end)::decimal/Total_shares + 2*sum(case when "E-Mail Status"='4. Clicked' then net_cnt else 0 end)::decimal /Total_Clicked + sum(case when "E-Mail Status"='4. Clicked' then net_cnt else 0 end)::decimal /sum(net_cnt) as Agent_Score
from agent_metrics am
left JOIN totals t on 1=1
group by 1,Total_shares,Total_Clicked
),
agent_ranks as (select agent_full_name
                       ,to_char(row_number () over (order by agent_score desc),'00') as rnk
                from agent_score       
                  )
select am.*
      ,am."Title" ||' - ' || am.agent_name as "Agent Ranked" -- ar.rnk || '.
from agent_metrics am
left join agent_ranks ar on am.agent_full_name=ar.agent_full_name

      

