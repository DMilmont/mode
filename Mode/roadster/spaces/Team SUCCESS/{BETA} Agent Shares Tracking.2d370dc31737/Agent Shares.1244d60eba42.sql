with date_dpid as (
        select DISTINCT date(c.date) as date,dp.id ,dp.dpid, dp.name, primary_make
        from fact.d_cal_date c
               cross join (
          select distinct dps.id,dps.dpid, dps.tableau_secret, dps.name, primary_make
          from dealer_partners dps
          where status = 'Live'

            AND dpid='{{ dpid }}'
        ) dp
             --  where dpid not like '%demo%')dp
        where c.date <= (date_trunc('day', now()) - interval '1 days')
          and CASE WHEN '{{ DateR }}'='Past 7 Days' and  c.date >= (date_trunc('day', now()) - interval '7 days') then 1
                  WHEN  '{{ DateR }}'='Past 30 Days' and  c.date >= (date_trunc('day', now()) - interval '31 days') then 1   
                  WHEN  '{{ DateR }}'='Past 60 Days' and  c.date >= (date_trunc('day', now()) - interval '61 days') then 1 
                  WHEN  '{{ DateR }}'='Past 90 Days' and  c.date >= (date_trunc('day', now()) - interval '91 days') then 1 
                  ELSE 0 END = 1
        group by 1, 2, 3, 4, 5
      ),
     agent as (
       select first_name||' ' ||substr(last_name,1,1) as agent_name
              ,first_name||' ' || last_name as agent_full_name
              ,a.*
       from agents a
       WHERE    status='Active'
       and email not like '%roadster%'
     ),
    leads_submitted as (
      select *
      from lead_submitted
      where timestamp >= (date_trunc('day', now()) - interval '91 days')
        and type='SharedExpressVehicle'
        and sent_at is not null
    ),
    detail as (SELECT dd.date
                    , dd.dpid
                    , dd.name
                    ,a.agent_name
                    ,a.email
                    ,a.agent_full_name
                    ,a.job_title
                    ,ls.agent_id
                    , ls.id
                    ,ls.crm_record_id
                    ,ls.vin
                    ,ls.make
                    ,ls.model
                    ,ls.year
                    ,ls.grade
                    ,ls.deal_type
                    ,ls.referral_coupon
                    ,ls.details
                    ,ls.order_id
                    ,case when ls.delivered_at is not  null 
                          then 1 else 0 end as Deliver_Check
                    ,case when ls.clicked_at is not  null or ls.opened_at is not null
                          then 1 else 0 end as Open_Check
                   ,case when ls.clicked_at is not null
                          then 1 else 0 end as Click_Check
               FROM date_dpid dd
                      left join leads_submitted ls on dd.id = ls.dealer_partner_id and date(dd.date) = date(ls.sent_at)
                      left join agent a on ls.agent_id=a.id
              where a.agent_name is not null        
    ),
agent_detail as (select agent_name 
                ,agent_full_name
                ,email
                ,COALESCE(job_title,'Job Title Missing') as job_title
                ,dpid
                ,name
                ,COUNT(distinct id) as EmailSent
                ,sum(Deliver_Check) as EmailDeliver
                ,sum(Open_Check) as EmailOpen
                ,sum(Click_Check)  as EmailClick
          from detail
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
) 
select am.*
      ,am."Title" ||' - ' || am.agent_name as "Agent Ranked" -- ar.rnk || '.
from agent_metrics am


      
      
{% form %}

DateR:
    type: select
    default: "Past 7 Days"
    label: Date Range
    options: ["Past 7 Days", "Past 30 Days","Past 60 Days","Past 90 Days"]
    
{% endform %}

