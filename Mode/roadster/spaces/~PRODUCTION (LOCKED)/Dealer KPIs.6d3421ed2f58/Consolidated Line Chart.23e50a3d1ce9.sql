with order_status as (
  SELECT order_id, 'canceled' status
  FROM order_cancelled
  UNION 
  SELECT order_id, 'completed' status
  FROM order_completed

),

tab2 as (

SELECT 
'Prospects' title,
dpid,
name,
ls.timestamp ts_prospects,
extract(DAY from ls.timestamp) day_of_month,
to_char(ls.timestamp, 'Month YYYY') mth_yr,
to_char(ls.timestamp, 'DD Month YYYY') dt,
to_char(ls.timestamp, 'HH') hr,
ls.type,
ls.in_store,
ls.user_contact_dbid,
user_id,
u.first_name,
u.last_name,
u.email,
1 "exists",
a.first_name || ' ' || a.last_name agent_name,
regexp_replace(type, '([a-z])([A-Z])', '\1 \2','g') type_to_use,
CASE WHEN os.status IS NULL AND ls.order_id IS NOT NULL THEN 'Open'
ELSE initcap(os.status) END as order_status, 
CASE 
  WHEN ls.in_store = true THEN 'In-Store'
  ELSE 'Online' END AS instore_name,
  
'https://dealers.roadster.com/' || dpid || '/user_contacts/' || user_contact_dbid link_lead,

'https://dealers.roadster.com/' || dpid || '/orders/' || o.order_dbid  link_order
  
FROM lead_submitted ls
LEFT JOIN dealer_partners dp ON ls.dealer_partner_id = dp.id
LEFT JOIN users u ON ls.user_id = u.id
LEFT JOIN agents a ON ls.agent_id = a.id
LEFT JOIN orders o ON ls.order_id = o.id
LEFT JOIN order_status os ON ls.order_id = os.order_id
WHERE timestamp >= (date_trunc('month', now()) - '6 months'::interval)
AND dpid = '{{ dpid }}'

),

order_steps as (
 SELECT (order_submitted.order_step_dbid) :: text AS order_step_id,
         'Order Submitted' :: text                 AS "Item Type",
         order_submitted."timestamp",
         order_submitted.order_id,
         order_submitted.user_id,
         order_submitted.dealer_partner_id,
         order_submitted.duration,
         order_submitted.is_final

  FROM order_submitted order_submitted

  UNION ALL
  SELECT (deal_sheet_sent.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Sent' :: text                 AS "Item Type",
         deal_sheet_sent."timestamp",
         deal_sheet_sent.order_id,
         deal_sheet_sent.user_id,
         deal_sheet_sent.dealer_partner_id,
         deal_sheet_sent.duration,
         deal_sheet_sent.is_final

  FROM deal_sheet_sent deal_sheet_sent

  UNION ALL
  SELECT (deal_sheet_accepted.order_step_dbid) :: text AS order_step_id,
         'Deal Sheet Accepted' :: text                 AS "Item Type",
         deal_sheet_accepted."timestamp",
         deal_sheet_accepted.order_id,
         deal_sheet_accepted.user_id,
         deal_sheet_accepted.dealer_partner_id,
         deal_sheet_accepted.duration,
         deal_sheet_accepted.is_final

  FROM deal_sheet_accepted
    
  UNION ALL
  SELECT (credit_completed.order_step_dbid) :: text AS order_step_id,
         'Credit Completed' :: text                 AS "Item Type",
         credit_completed."timestamp",
         credit_completed.order_id,
         credit_completed.user_id,
         credit_completed.dealer_partner_id,
         credit_completed.duration,
         credit_completed.is_final

  FROM credit_completed

  UNION ALL
  SELECT (service_plans_completed.order_step_dbid) :: text AS order_step_id,
         'Service Plans Completed' :: text                 AS "Item Type",
         service_plans_completed."timestamp",
         service_plans_completed.order_id,
         service_plans_completed.user_id,
         service_plans_completed.dealer_partner_id,
         service_plans_completed.duration,
         service_plans_completed.is_final

  FROM service_plans_completed

  UNION ALL
  SELECT (accessories_completed.order_step_dbid) :: text AS order_step_id,
         'Accessories Completed' :: text                 AS "Item Type",
         accessories_completed."timestamp",
         accessories_completed.order_id,
         accessories_completed.user_id,
         accessories_completed.dealer_partner_id,
         accessories_completed.duration,
         accessories_completed.is_final

  FROM accessories_completed

  UNION ALL
  SELECT (final_deal_sent.order_step_dbid) :: text AS order_step_id,
         'Final Deal Sent' :: text                 AS "Item Type",
         final_deal_sent."timestamp",
         final_deal_sent.order_id,
         final_deal_sent.user_id,
         final_deal_sent.dealer_partner_id,
         final_deal_sent.duration,
         final_deal_sent.is_final

  FROM final_deal_sent

  UNION ALL
  SELECT (final_deal_accepted.order_step_dbid) :: text AS order_step_id,
         'Final Deal Accepted' :: text                 AS "Item Type",
         final_deal_accepted."timestamp",
         final_deal_accepted.order_id,
         final_deal_accepted.user_id,
         final_deal_accepted.dealer_partner_id,
         final_deal_accepted.duration,
         final_deal_accepted.is_final

  FROM final_deal_accepted

  UNION ALL
  SELECT ('order-' :: text || order_completed.order_id) AS order_step_id,
         'Order Completed' :: text                      AS "Item Type",
         order_completed."timestamp",
         order_completed.order_id,
         order_completed.user_id,
         order_completed.dealer_partner_id,
         order_completed.duration,
         order_completed.is_final

  FROM order_completed

  UNION ALL
  SELECT ('order-' :: text || order_cancelled.order_id) AS order_step_id,
         'Order Cancelled' :: text                      AS "Item Type",
         order_cancelled."timestamp",
         order_cancelled.order_id,
         order_cancelled.user_id,
         order_cancelled.dealer_partner_id,
         order_cancelled.duration,
         order_cancelled.is_final

  FROM order_cancelled


)

,almost as (

SELECT order_steps.*,
CASE WHEN order_status.status IS NULL THEN 'Open' ELSE initcap(order_status.status) END current_order_status,
dpid,

CASE WHEN o.in_store = True THEN 'In-Store' ELSE 'Online' END in_store_type

FROM order_steps
LEFT JOIN order_status ON order_steps.order_id = order_status.order_id
LEFT JOIN dealer_partners dp ON order_steps.dealer_partner_id = dp.id
LEFT JOIN orders o ON order_steps.order_id = o.id
WHERE dpid = '{{ dpid }}'
and timestamp >= (date_trunc('day', now()) - INTERVAL '14 Days')
and date(timestamp)< (date_trunc('day', now()))
and  CASE WHEN order_status.status IS NULL THEN 'Open' ELSE initcap(order_status.status) END in ('Open','Completed')
),
date_dpid as (
        select DISTINCT date(c.date) as date,dp.id ,dp.dpid, dp.name, primary_make
        ,CASE WHEN  c.date >= (date_trunc('day', now()) - interval '7 days') then 'Current 7 Days'
              WHEN  c.date >= (date_trunc('day', now()) - interval '14 days') then 'Previous 14 Days'
              END as time_frame
        from fact.d_cal_date c
               cross join (
          select distinct dps.id,dps.dpid, dps.tableau_secret, dps.name, primary_make
          from dealer_partners dps
          where status in ( 'Live','Pending')
            AND dpid='{{ dpid }}'
        ) dp
             --  where dpid not like '%demo%')dp
        where c.date <= (date_trunc('day', now()) - interval '0 days')
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
agent_detail as (select date 
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
      
agent_email as(  SELECT ad.date
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
        SELECT ae.date
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
      LEFT JOIN (select * from agent_email where email_event='Clicked') aec on ae.agent_full_name=aec.agent_full_name and ae.date=aec.date
       LEFT JOIN (select * from agent_email where email_event='Opened') aeo on ae.agent_full_name=aeo.agent_full_name and ae.date=aeo.date
       LEFT JOIN (select * from agent_email where email_event='Delivered') aed on ae.agent_full_name=aed.agent_full_name and ae.date=aed.date
),
totals as (
            SELECT date
                  ,sum(net_cnt) as Total_shares
  
            FROM agent_metrics
            GROUP BY 1
)

select 'Shares' as type
      ,date 
      ,sum(total_shares) as "Total Shares"

FROM totals t
where date< (date_trunc('day', now()))
and date>= (date_trunc('day', now()) - INTERVAL '14 Days')
group by 2
      
      
union

SELECT 'Orders'
  ,date(timestamp)
,count(1) order_count

FROM almost
WHERE current_order_status in ('Open','Completed')
and date(timestamp)< (date_trunc('day', now()))
and date(timestamp)>= (date_trunc('day', now()) - INTERVAL '14 Days')


GROUP BY 2
union 
SELECT 'Prospects' 
,date(ts_prospects) as date
,SUM(exists ) prospect_Count
FROM tab2
WHERE   ts_prospects>= (date_trunc('day', now()) - INTERVAL '14 Days')
and ts_prospects< (date_trunc('day', now()))
GROUP BY 2

union
SELECT  'Express Store Visits' as type
        ,date_local  
      ,count(distinct distinct_id)
FROM fact.f_traffic_weekly
where dpid='{{ dpid }}'
and date_local< (date_trunc('day', now()))
and date_local>= (date_trunc('day', now()) - INTERVAL '14 Days')
GROUP BY 2