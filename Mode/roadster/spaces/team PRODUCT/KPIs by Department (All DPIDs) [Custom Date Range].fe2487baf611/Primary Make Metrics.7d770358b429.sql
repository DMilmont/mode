
with cdk_api as (
SELECT dp.dpid,
       case when properties -> 'cdk_extract_id' <> 'null' then 'CDK API' else '' end AS "cdk_api"
FROM public.dealer_partner_properties dpp
left join public.dealer_partners dp ON dp.id = dpp.dealer_partner_id
WHERE date > (date_trunc('day', now()) - INTERVAL '1 day')
)
,active_agents as (
select agent_id
      ,count(1)
from user_events
where agent_id is not null
and timestamp::date >= '{{ start_date }}'  
and timestamp::date <= '{{ end_date }}' 
group by 1
having count(1) > 2
)

,date_dpid as (
select distinct dp.dpid, sf.status, dp.id,
dp.status dp_status, sf.success_manager, sf.actual_live_date, sf.dealer_group, dp.name, dp.tableau_secret as dpsk,a.id as agent_id,a.email,a.department,primary_make
FROM dealer_partners dp
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
left join agents a on dp.id=a.dealer_partner_id
join active_agents aa on a.id=aa.agent_id 
where
(sf.status = 'Live' or dp.status = 'Live')

)

,in_store_shares as (
SELECT d.dpid,
      a.department,
      a.email,
      a.id as agent_id
        ,sum(case when sent_at is not null then 1 else 0 end )as share_cnt     
        ,sum(case when clicked_at is not null then 1 else 0 end) as clicked_cnt
        ,sum(case when opened_at is not null then 1 else 0 end) as opened_cnt
 
FROM public.lead_submitted p
left join agents a on p.agent_id=a.id
left join (select distinct id,dpid from date_dpid ) d on p.dealer_partner_id=d.id
WHERE type = 'SharedExpressVehicle'
 and timestamp::date >= '{{ start_date }}'  
and timestamp::date <= '{{ end_date }}' 

GROUP BY 1,2,3,4
)
,in_store_prospects as (
  SELECT p.dpid,
              a.department,
              a.email,
              a.id as agent_id,
        'In-Store Prospects' :: text                AS type,
        count(DISTINCT p.customer_email) AS sum_in_store_prospects
 FROM fact.f_prospect p
 left join agents a on p.agent_email=a.email
 WHERE  p.is_in_store IS TRUE
 and cohort_date_utc >= '{{ start_date }}'  
and cohort_date_utc <= '{{ end_date }}'



        
 GROUP BY 1,2,3,4,5
),

raw_sale_data as (
SELECT DISTINCT sold_date::date, item_type, dpid, vin, days_to_close_from_last_lead,last_lead_id,crm_record_id
FROM fact.f_sale
WHERE sold_date::date >= '{{ start_date }}'  
and sold_date::date <= '{{ end_date }}' 
)

,matched_sales as (
SELECT dpid
      ,l.agent_id
      ,a.department
      ,a.email
      ,count(distinct s.vin) as sales_count
FROM raw_sale_data s
left join lead_submitted l on s.last_lead_id=l.id 
left join agents a on a.id=l.agent_id
where item_type='Matched Sale'
GROUP BY 1,2,3,4
)
,unmatched_sales as (
SELECT dpid
      ,a.id as agent_id
      ,a.department
      ,a.email
      ,count(distinct s.vin) as sales_count
FROM raw_sale_data s
LEFT JOIN crm_records crm ON s.crm_record_id = crm.id
LEFT JOIN agents a ON (((lower((a.first_name)::text) = lower(split_part((crm.agent1)::text, ' '::text, 1))) AND
                        (lower((a.last_name)::text) = lower(split_part((crm.agent1)::text, ' '::text, 2)))))
where item_type='Sale'
GROUP BY 1,2,3,4
)


,base_order_data as (
    SELECT cohort_date_utc, dpid, item_type, order_step_id, is_in_store,              a.department,a.email,a.id as agent_id
    FROM fact.f_prospect p
 left join agents a on p.agent_email=a.email
    WHERE source in ( 'Order Step','Lead Type')
    and cohort_date_utc >= '{{ start_date }}'  
    and cohort_date_utc <= '{{ end_date }}'   
)

,pivot_orders as (
      SELECT base_order_data.*,
             CASE WHEN item_type = 'Service Plans Completed' THEN 1 ELSE 0 END AS "Service Plans Completed",
             CASE WHEN item_type = 'Credit Completed' THEN 1 ELSE 0 END        AS "Credit Completed",
             CASE WHEN item_type = 'TradeEstimate' THEN 1 ELSE 0 END       AS "Trade-In Attached",
             CASE WHEN item_type = 'Service Plans Attached' THEN 1 ELSE 0 END  AS "Service Plans Attached",
             CASE WHEN item_type = 'Deal Sheet Accepted' THEN 1 ELSE 0 END     AS "Deal Sheet Accepted",
             CASE WHEN item_type = 'OrderStarted' THEN 1 ELSE 0 END         AS "Order Submitted",
             CASE WHEN item_type = 'Trade-In Completed' THEN 1 ELSE 0 END      AS "Trade-In Completed",
             CASE WHEN item_type = 'Accessories Completed' THEN 1 ELSE 0 END   AS "Accessories Completed",
             CASE WHEN item_type = 'Accessories Attached' THEN 1 ELSE 0 END    AS "Accessories Attached",
             CASE WHEN item_type = 'Final Deal Sent' THEN 1 ELSE 0 END         AS "Final Deal Sent"
      FROM base_order_data
  ), 
  
pivot_orders_agg as (
SELECT dpid,a.department,a.email,a.agent_id ,
       SUM("Service Plans Completed") AS "Service Plans Completed",
        SUM("Credit Completed") AS "Credit Completed",
        SUM("Trade-In Attached") AS "Trade-In Attached",
        SUM("Service Plans Attached") AS "Service Plans Attached",
        SUM("Deal Sheet Accepted") AS "Deal Sheet Accepted",
        SUM(case when is_in_store = true then "Order Submitted" else null end ) AS "Online Orders Submitted",
        SUM(case when is_in_store = false then "Order Submitted" else null end ) AS "InStore Orders Submitted",
        SUM("Trade-In Completed") AS "Trade-In Completed",
        SUM("Accessories Completed") AS "Accessories Completed",
        SUM("Accessories Attached") AS "Accessories Attached",
        SUM("Final Deal Sent") AS "Final Deal Sent"
FROM pivot_orders a
GROUP BY 1,2,3,4

),
detail as (select
DISTINCT 
dd.name as "Dealership"
, dd.dealer_group as "Dealer Group"
, dd.status as "SF Status"
, dd.dp_status as "DA Status"
, dd.success_manager
,dd.agent_id
,dd.department
,dd.email
, dd.primary_make as "Primary Make"
, to_char(dd.actual_live_date,'yyyy_mm_dd') as "SF Go Live"
, cdk_api
--, dpp.properties ->> 'crm_vendor' "Dealer Admin CRM"
, COALESCE(ms.sales_count, 0) "Matched Sales"
, COALESCE(us.sales_count, 0) "UnMatched Sales"
, COALESCE(isp.sum_in_store_prospects, 0) as "In-Store Prospects"
--, COALESCE(iss."In-Store Shares", 0) AS "In-Store Shares"
,COALESCE(iss.share_cnt,0) as "Agent Shares"
,COALESCE(iss.opened_cnt,0) as "Shares Opened"
, case when COALESCE(iss.share_cnt,0)=0 then 0 else iss.opened_cnt / COALESCE(iss.share_cnt,0)::decimal end  as "Shares Open Rate"
,COALESCE(iss.clicked_cnt,0) as "Shares Clicked"
, case when COALESCE(iss.share_cnt,0)=0 then 0 else  iss.clicked_cnt /COALESCE(iss.share_cnt,0)::decimal end as "Shares Click Thru Rate"
, COALESCE("Online Orders Submitted",0) + coalesce("InStore Orders Submitted", 0) AS "Total Orders"
, COALESCE("Online Orders Submitted", 0) AS "Online Orders"
, COALESCE("InStore Orders Submitted", 0) AS "InStore Orders"
, COALESCE("Deal Sheet Accepted", 0) AS "Deal Sheet Accepted"
, COALESCE("Trade-In Completed", 0) AS "Trade-In Completed"
, COALESCE("Trade-In Attached", 0) AS "Trade-In Attached"
, COALESCE("Credit Completed", 0) AS "Credit Completed"
, COALESCE("Accessories Completed", 0) AS "Accessories Completed"
, COALESCE("Accessories Attached", 0) AS "Accessories Attached"
, COALESCE("Service Plans Attached", 0) AS "Service Plans Attached"
, COALESCE("Service Plans Completed", 0) AS "Service Plans Completed"
, COALESCE("Final Deal Sent", 0) AS "Final Deal Sent"
from date_dpid dd
left join cdk_api ca on ca.dpid = dd.dpid
left join matched_sales ms on dd.agent_id=ms.agent_id and ms.dpid=dd.dpid
left join unmatched_sales us on dd.agent_id=COALESCE(us.agent_id,1) and us.dpid=dd.dpid
LEFT JOIN pivot_orders_agg poa ON  dd.agent_id=COALESCE(poa.agent_id,1) and poa.dpid=dd.dpid
LEFT JOIN in_store_shares iss ON  dd.agent_id=COALESCE(iss.agent_id,1) and  iss.dpid=dd.dpid
LEFT JOIN in_store_prospects isp ON dd.agent_id=COALESCE(isp.agent_id,1) and isp.dpid=dd.dpid
ORDER BY 1

) 
-- select COALESCE(department,'Department Not Entered') as "Department"
select      "Primary Make"
      -- ,"Dealership"
      ,sum("Matched Sales") as "Matched Sales"
      ,sum("UnMatched Sales") as "UnMatched Sales"
      ,sum("In-Store Prospects") as "In-Store Prospects"
      ,sum("Agent Shares") as "Agent Shares"
      ,sum("Shares Opened") as "Shares Opened"
      ,case when sum("Agent Shares")=0 then 0 else  round(sum("Shares Opened")::decimal/sum("Agent Shares"),2) end as "Shares Open Rate" 
      ,sum("Shares Clicked") as "Shares Clicked"
      ,case when sum("Agent Shares")=0 then 0 else  round(sum("Shares Clicked")::decimal/sum("Agent Shares"),2) end as "Shares Click Thru Rate"  
      ,sum("Total Orders") as "Total Orders"
      ,sum("Online Orders") as "Online Orders"
      ,sum("InStore Orders") as "InStore Orders"
      ,sum("Trade-In Completed") as "Trade-In Completed"
      ,sum("Trade-In Attached") as "Trade-In Estimate"
from detail
group by 1
order by 2 desc


{% form %}

start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}

end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  

{% endform %}
        