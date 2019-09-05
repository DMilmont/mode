
with date_dpid as (
        select DISTINCT date(c.date) as date,dp.id ,dp.dpid, dp.name, primary_make
        ,CASE WHEN  c.date >= (date_trunc('day', now()) - interval '7 days') then 'Current 7 Days'
              WHEN  c.date >= (date_trunc('day', now()) - interval '14 days') then 'Past 7 Days'
              END as time_frame
        from fact.d_cal_date c
               cross join (
          select distinct dps.id,dps.dpid, dps.tableau_secret, dps.name, primary_make
          from dealer_partners dps
          where status in ( 'Live','Pending')
            AND dpid='{{ dpid }}'
        ) dp
             --  where dpid not like '%demo%')dp
        where c.date <= (date_trunc('day', now()) - interval '1 days')
           and c.date >= (date_trunc('day', now()) - interval '14 days')  
        group by 1, 2, 3, 4, 5, c.date 
      ),
     agent as (
       select first_name||' ' ||substr(last_name,1,1) as agent_name
              ,first_name||' ' || last_name as agent_full_name
              ,a.*
       from agents a
       WHERE  status='Active'
       and email not like '%roadster%'
     ),
    leads_submitted as (
      select *
      from lead_submitted
      where timestamp >= (date_trunc('day', now()) - interval '14 days')
        and type='SharedExpressVehicle'
        and sent_at is not null
    ),
    detail as (SELECT dd.date
                    , dd.dpid
                    , dd.name
                    , dd.time_frame
                    ,a.agent_name
                    ,a.email
                    ,a.agent_full_name
                    ,a.job_title
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
agent_detail as (select time_frame 
                ,agent_name 
                ,agent_full_name
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
      
agent_email as(  SELECT ad.time_frame
            ,ad.dpid
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
agent_metrics as ( 
        SELECT ae.time_frame
            ,ae.dpid
            ,ae.name
            ,ae.agent_full_name
            ,ae.job_title || ' - ' || ae.agent  as "Agent"
            ,ae.job_title as "Title"
            ,CASE WHEN ae.email_event='Sent' then '1. Invalid Email' 
                  WHEN ae.email_event='Delivered' then '2. Delivered - Not Opened'
                  WHEN ae.email_event='Opened' then '3. Opened - Not Clicked'
                  WHEN ae.email_event='Clicked' then '4. Clicked' end as "E-Mail Status"
            ,case when ae.email_event='Sent' then ae.cnt-aed.cnt
                  when ae.email_event='Delivered' then ae.cnt-aeo.cnt
                  when ae.email_event='Opened' then ae.cnt-aec.cnt
                  else ae.cnt end as net_cnt
            
      FROM agent_email ae
      LEFT JOIN (select * from agent_email where email_event='Clicked') aec on ae.agent_full_name=aec.agent_full_name and ae.time_frame=aec.time_frame
       LEFT JOIN (select * from agent_email where email_event='Opened') aeo on ae.agent_full_name=aeo.agent_full_name and ae.time_frame=aeo.time_frame
       LEFT JOIN (select * from agent_email where email_event='Delivered') aed on ae.agent_full_name=aed.agent_full_name and ae.time_frame=aed.time_frame
),
totals as (
            SELECT time_frame
                  ,sum(net_cnt) as Total_shares
                  ,sum(case when "E-Mail Status"='4. Clicked' or "E-Mail Status"='3. Opened - Not Clicked' then net_cnt else 0 end) as Total_Opened
                  ,sum(case when "E-Mail Status"='4. Clicked' then net_cnt else 0 end) as Total_Clicked
            FROM agent_metrics
            GROUP BY 1
),

output as (select t.time_frame as "Time Frame"
      ,sum(total_shares) as "Total Shares"

FROM totals t
group by 1
  )
select * from output
union 
select 'Current 7 Days', 0
where case when 'Current 7 Days' in (select "Time Frame" from output) then 0 else 1 end =1
union
select 'Past 7 Days', 0
where case when 'Past 7 Days' in (select "Time Frame" from output) then 0 else 1 end =1


      


