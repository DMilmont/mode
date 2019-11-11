with dpids as (

select distinct dpid, '{{ Target_Label}}' as label ,'{{ Target_dpid}}' as dpid_list,id,'1. Target Group - Target Date'as groups,'{{Target_start_date}}'  as start_date, '{{Target_end_date}}'  as end_date, '{{Target_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Target_dpid | replace: ",","','" }}')
UNION
select distinct dpid,'{{ Target_Label}}' as label,'{{ Target_dpid}}' as dpid_list ,id,'2. Target Group - Compare Date' as groups,'{{Comparison_start_date}}'  as start_date, '{{Comparison_end_date}}'  as end_date, '{{Comparison_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Target_dpid | replace: ",","','" }}')
union 
select distinct dpid,'{{ Comparison_1_Label}}' as label,'{{ Comparison_1_dpid}}' as dpid_list ,id,'3. Comparison 1 Group - Target Date' as groups,'{{Target_start_date}}'  as start_date, '{{Target_end_date}}'  as end_date, '{{Target_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Comparison_1_dpid | replace: ",","','" }}')
UNION
select distinct dpid,'{{ Comparison_1_Label}}' as label,'{{ Comparison_1_dpid}}' ,id,'5. Comparison 1 Group - Compare Date' as groups,'{{Comparison_start_date}}'  as start_date, '{{Comparison_end_date}}'  as end_date, '{{Comparison_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Comparison_1_dpid | replace: ",","','" }}')
UNION
select distinct dpid,'{{ Comparison_2_Label}}' as label,'{{ Comparison_2_dpid}}' as dpid_list ,id,'4. Comparison 2 Group - Target Date' as groups,'{{Target_start_date}}'  as start_date, '{{Target_end_date}}'  as end_date, '{{Target_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Comparison_2_dpid | replace: ",","','" }}')
UNION
select distinct dpid,'{{ Comparison_2_Label}}' as label,'{{ Comparison_2_dpid}}' ,id,'6. Comparison 2 Group - Compare Date' as groups,'{{Comparison_start_date}}'  as start_date, '{{Comparison_end_date}}'  as end_date, '{{Comparison_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Comparison_2_dpid | replace: ",","','" }}')

) ,

express_visitors as (
SELECT   d.groups
        ,case when '{{Target_start_date}}'::date<=t.date and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=t.date then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=t.date and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=t.date) then '{{Comparison_date_label}}' end date_label
        ,count(distinct t.dpid) as dpid_cnt
        ,count(DISTINCT t.distinct_id) express_visitors
        ,count(distinct t.date || t.dpid) as dpid_days_cnt
  FROM fact.f_traffic t 
  inner join dpids d on t.dpid=d.dpid 
  where t.is_in_store is false
  and (('{{Target_start_date}}'::date<=t.date and '{{Target_end_date}}'::date >=t.date) or ('{{Comparison_start_date}}'::date<=t.date and '{{Comparison_end_date}}'::date >=t.date) )
  group by 1,2
),

online as (
SELECT   d.groups
         ,case when '{{Target_start_date}}'::date<=gs.timestamp and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=gs.timestamp then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=gs.timestamp and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=gs.timestamp) then '{{Comparison_date_label}}' end date_label
        ,count(DISTINCT case when gs.in_store is false and gp.property = 'Main Sites' then gs.distinct_id else null end ) as dealer_visitors
        ,sum(case when gp.property = 'Express Sites'and gp.page_path in ('/modal/modal-price-summary','/modal_price_summary','/virtual/modal-price-summary') then 1 else 0 end ) as sheets_cnt
        ,count(distinct case when gp.property = 'Express Sites'and gp.page_path in ('/modal/modal-price-summary','/modal_price_summary','/virtual/modal-price-summary') then gs.distinct_id else null end ) as sheets_user_cnt
        ,count(distinct case when  a.id is not null and agent_dbid is not null and length(agent_dbid) > 7 aND gp.property IN ('Dealer Admin', 'Express Sites') then agent_dbid else null end) as active_agents
  FROM ga2_sessions gs
  left join ga2_pageviews gp on gp.ga2_session_id = gs.id
  inner join dpids d on gs.dpid=d.dpid 
  left join (select distinct_id as id,dealer_partner_id from agents where status='Active' and last_login_at>=(CURRENT_DATE - '6 mons' :: interval)) a on d.id=a.dealer_partner_id and gs.agent_dbid=a.id::varchar
     where (('{{Target_start_date}}'::date<=gs.timestamp and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=gs.timestamp) or ('{{Comparison_start_date}}'::date<=gs.timestamp and  date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=gs.timestamp))
   and (('{{Target_start_date}}'::date<=gp.timestamp and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=gp.timestamp) or ('{{Comparison_start_date}}'::date<=gp.timestamp and  date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=gp.timestamp))
  group by 1,2
),
events as (
SELECT   d.groups
         ,case when '{{Target_start_date}}'::date<=ue.timestamp and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=ue.timestamp then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=ue.timestamp and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=ue.timestamp) then '{{Comparison_date_label}}' end date_label
        ,sum ( case when name='Copy To Clipboard' then 1 else 0 end) as copies
        ,sum ( case when name in ('Print Share Details','Print Price Summary') then 1 else 0 end) as prints
        ,sum ( case when name='Deal Built' then 1 else 0 end) as pencils
        ,count (distinct case when name='Deal Built' then user_id else null end) as prosects_pencils
from user_events_intermediate ue    
inner join dpids d on d.id=ue.dealer_partner_id 
  where (('{{Target_start_date}}'::date<=ue.timestamp and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=ue.timestamp) or ('{{Comparison_start_date}}'::date<=ue.timestamp and  date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=ue.timestamp))
group by 1,2
),
agents as (

SELECT d.groups
      ,d.date_label
      ,count(distinct a.id) as agents
FROM agents a      
inner join dpids d on a.dealer_partner_id=d.id
where status='Active' and last_login_at>=(CURRENT_DATE - '6 mons' :: interval)
group by 1,2
),
prospects as 
(SELECT   d.groups
        ,case when '{{Target_start_date}}'::date<=p.cohort_date_utc  and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=p.cohort_date_utc  then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=p.cohort_date_utc  and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=p.cohort_date_utc ) then '{{Comparison_date_label}}' end date_label
        ,count(distinct customer_email) as prospect_cnt
        ,count (distinct case when is_in_store is true then customer_email else null end) as in_store_prospect_cnt
        ,count  ( distinct case when is_in_store is false then customer_email else null end) as online_prospect_cnt
        ,count(distinct case when is_prospect_close_sale = true and source = 'Lead Type' then customer_email else null end ) as sales_cnt
        ,count (distinct case when is_in_store is true and is_prospect_close_sale = true and source = 'Lead Type' then customer_email else null end) as in_store_sales_cnt
        ,count  ( distinct case when is_in_store is false and is_prospect_close_sale = true and source = 'Lead Type' then customer_email else null end) as online_sales_cnt
        
from fact.f_prospect p      
inner join dpids d on d.dpid=p.dpid 
where   (('{{Target_start_date}}'::date<=p.cohort_date_utc  and '{{Target_end_date}}'::date >=p.cohort_date_utc ) or ('{{Comparison_start_date}}'::date<=p.cohort_date_utc  and '{{Comparison_end_date}}'::date >=p.cohort_date_utc ) )

group by 1,2
),


leads_sub as 
(SELECT   d.groups
        ,case when '{{Target_start_date}}'::date<=timestamp and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=timestamp then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=timestamp and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=timestamp) then '{{Comparison_date_label}}' end date_label
        ,sum(case when type = 'SharedExpressVehicle' and  sent_at is not null then 1 else 0 end )as share_cnt   
        ,sum(case when type = 'SharedExpressVehicle' and  opened_at is not null then 1 else 0 end )as share_open   
        ,sum(case when type = 'SharedExpressVehicle' and clicked_at is not null then 1 else 0 end) as clicked_cnt
        ,sum(case when type = 'TradeEstimate' then 1 else 0 end) as trades_valued_cnt
        
from public.lead_submitted ls      
inner join dpids d on d.id=ls.dealer_partner_id 
where (('{{Target_start_date}}'::date<=timestamp and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=timestamp) or ('{{Comparison_start_date}}'::date<=timestamp and  date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=timestamp))
group by 1,2
),


session_metrics as (
select d.groups
        ,case when '{{Target_start_date}}'::date<=s.date_local and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=s.date_local then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=s.date_local and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=s.date_local) then '{{Comparison_date_label}}' end date_label
        ,case when sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end)= 0 then 0 else round(sum(case when session_type in ('Dealer + Express Site','Express Site Only')  then duration else 0 end)::decimal/sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end),3) end as express_avg_session_duration
        ,case when sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end)= 0 then 0 else round(sum(case when session_type in ('Dealer Main Site Only') then duration else 0 end)::decimal/sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end),3) end as dealer_avg_session_duration  
        ,case when sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end)= 0 then 0 else round(sum(case when session_type in ('Dealer + Express Site','Express Site Only')  then pageviews else 0 end)::decimal/sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end),3)end as express_avg_pages_per_session
        ,case when sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end)= 0 then 0 else round(sum(case when session_type in ('Dealer Main Site Only') then pageviews else 0 end)::decimal/sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end),3)  end as dealer_avg_pages_per_session

        ,case when sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end)= 0 then 0 else round(sum(case when session_type in ('Dealer + Express Site','Express Site Only') and bounce is true then 1 else 0 end)::decimal/sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end),3) end as express_bounce 
        ,case when sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end)= 0 then 0 else round(sum(case when session_type in ('Dealer Main Site Only') and bounce is true then 1 else 0 end)::decimal/sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end),3) end as dealer_bounce  
from fact.f_sessions s
  inner join dpids d on s.dpid=d.dpid
where (('{{Target_start_date}}'::date<=s.date_local and '{{Target_end_date}}'::date >=s.date_local) or ('{{Comparison_start_date}}'::date<=s.date_local and '{{Comparison_end_date}}'::date >=s.date_local) )
and COALESCE(session_type,'x')<>'Dealer Admin'

group by 1,2
),
order_steps as (
select d.groups
      ,case when '{{Target_start_date}}'::date<=os.date and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=os.date then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=os.date and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=os.date) then '{{Comparison_date_label}}' end date_label
    
      ,sum("Order Submitted") as orders_submitted
      ,sum(case when os."Order Status"= 'Open'    then "Order Submitted" else 0 end) as orders_submitted_open
      ,sum(case when os."Order Status"= 'Cancelled'    then "Order Submitted" else 0 end) as orders_submitted_cancelled
      ,sum(case when os."Order Status"= 'Completed'   then "Order Submitted" else 0 end) as orders_submitted_completed
      ,sum(case when os.is_in_store is true then "Order Submitted" else 0 end) as orders_submitted_instore
      ,sum(case when os.is_in_store is false then "Order Submitted" else 0 end) as orders_submitted_online
      ,sum("Deal Sheet Accepted") as vehicle_details_pricing
      ,sum("Trade-In Completed")  as trade_in_completed
      ,sum("Credit Completed" )  as credit_completed
      ,sum( "Service Plans Completed" )  as service_plans
      ,sum( "Accessories Completed" )  as accesories
      ,sum("Final Deal Sent")  as final_review
from report_layer.dg_order_step_metrics_daily os
inner join dpids d on os.dpid=d.dpid
where (('{{Target_start_date}}'::date<=os.date and '{{Target_end_date}}'::date >=os.date) or ('{{Comparison_start_date}}'::date<=os.date and '{{Comparison_end_date}}'::date >=os.date) )
group by 1,2

),
sales as ( 
select d.groups
     ,case when '{{Target_start_date}}'::date<=s."Sold Date" and date_trunc('day','{{Target_end_date}}'::date + interval '1 day')>=s."Sold Date" then '{{Target_date_label}}'
              when ('{{Comparison_start_date}}'::date<=s."Sold Date" and date_trunc('day','{{Comparison_end_date}}'::date + interval '1 day')>=s."Sold Date") then '{{Comparison_date_label}}' end date_label
      ,count(distinct case when "Sale Type" = 'Roadster' then "Deal No" else null end) as roadster_sales
      ,count(distinct case when "Sale Type" = 'Non-Roadster' then "Deal No" else null end) as nonroadster_sales
      ,sum(case when "Sale Type" = 'Roadster' and "New/Used"='New' then "Front Gross" else 0 end) as new_roadster_front_gp
      ,sum(case when "Sale Type" = 'Non-Roadster' and "New/Used"='New' then "Front Gross"else 0 end) as new_nonroadster_front_gp
      ,sum(case when "Sale Type" = 'Roadster' and "New/Used"='New' then "Back Gross" else 0 end) as new_roadster_back_gp
      ,sum(case when "Sale Type" = 'Non-Roadster' and "New/Used"='New' then "Back Gross" else 0 end) as new_nonroadster_back_gp
      ,sum(case when "Sale Type" = 'Roadster' and "New/Used"='Used' then "Front Gross" else 0 end) as used_roadster_front_gp
      ,sum(case when "Sale Type" = 'Non-Roadster' and "New/Used"='Used' then "Front Gross" else 0 end) as used_nonroadster_front_gp
      ,sum(case when "Sale Type" = 'Roadster' and "New/Used"='Used' then "Back Gross" else 0 end) as used_roadster_back_gp
      ,sum(case when "Sale Type" = 'Non-Roadster' and "New/Used"='Used' then "Back Gross" else 0 end) as used_nonroadster_back_gp
      
from report_layer.crm_sale_daily s
inner join dpids d on s.dpid=d.dpid
where  (('{{Target_start_date}}'::date<=s."Sold Date" and '{{Target_end_date}}'::date >=s."Sold Date") or ('{{Comparison_start_date}}'::date<=s."Sold Date" and '{{Comparison_end_date}}'::date >=s."Sold Date") )
group by 1,2
)

select d.dpid_list as "DPID List"
      ,d.groups as "Groups"
      ,d.label as "[D#]" -- Dealer label
      ,d.date_label as "[DT#]" -- date label
      ,d.start_date || ' - ' || d.end_date as "Date Range"
      ,ev.dpid_cnt as "[N#]" --"DPIDs in Group"
      ,ev.dpid_days_cnt "Active Days for all DPIDs"
      ,case when ov.dealer_visitors=0 then '0%' else to_char(round(ev.express_visitors::decimal/ov.dealer_visitors, 2)*100,'9999%') end as "[ER#]" --"Express Ratio"
      ,to_char(round(ev.express_visitors/ev.dpid_cnt,0),'9,999,999') as "[EN#]" -- express visitors
      ,to_char(round(ov.dealer_visitors/ev.dpid_cnt,0),'9,999,999') as "[DN#]" --dealer visitors
      ,case when ev.express_visitors=0 or p.online_prospect_cnt=0 then '0%' else to_char(round(p.online_prospect_cnt::decimal/ev.express_visitors,2)*100,'9999%') end   as "[PC#]"-- "Prospect Ratio"
      ,case when p.prospect_cnt=0 then '0%' else to_char(round(p.prospect_cnt/ev.dpid_cnt,0),'9,999,999') end as "[P#]" --"Prospects"
      ,case when a.agents=0 then '0%' else to_char(round(ov.active_agents::decimal/a.agents,2)*100,'9999%') end as "[AA#]"
      
      ,case when (e.copies + e.prints + ls.share_cnt)=0 then '0' else to_char(round((e.copies + e.prints + ls.share_cnt)/ev.dpid_cnt,0),'9,999,999')end as "[AN#]" -- shares / copies / prints 
      
      ,case when COALESCE(p.prospect_cnt,0)=0 or  os.orders_submitted = 0  then '0%' else to_char(round(os.orders_submitted/p.prospect_cnt,2)*100,'9999%') end as "[OC#]"   -- order conversion
      ,case when os.orders_submitted = 0 then '0' else to_char(round(  os.orders_submitted /ev.dpid_cnt,0),'9,999,999')end  as "[O#]" --"Orders Started
      ,case when COALESCE(p.prospect_cnt,0)=0 then '0%' else to_char(round(p.sales_cnt::decimal/p.prospect_cnt,2)*100,'9999%')end as "[CR#]"  -- prospect close rate
      ,case when p.sales_cnt=0 then '0' else to_char(round(p.sales_cnt/ev.dpid_cnt),'9,999,999') end as  "[MS#]"  --as "Sales"
      
     
      
      
      ,to_char(round(p.in_store_prospect_cnt/ev.dpid_cnt,0),'9,999,999') as "[IP#]"  --"Prospects - In Store"
      ,to_char(round(ls.share_cnt/ev.dpid_cnt,0),'9,999,999') as"[SH#]"--Shares"
      ,to_char(round(ls.share_open/ev.dpid_cnt,0),'9,999,999') as"[SO#]"--Shares Opneed
      ,case when COALESCE(share_cnt,0)=0 then '0%' else to_char(round(ls.share_open::decimal/share_cnt,2)*100,'9999%') end as "[SOP#]" --shares opened percent
      ,to_char(round(ls.clicked_cnt/ev.dpid_cnt,0),'9,999,999') as "[SC#]" --"Shares Clicked"
      ,case when COALESCE(share_cnt,0)=0 then '0%' else to_char(round(ls.clicked_cnt::decimal/share_cnt,2)*100,'9999%') end as "[SCP#]" 
      ,to_char(round((e.copies + e.prints)/ev.dpid_cnt,0),'9,999,999') as "[CP#]" --Copies and prints
      ,to_char(round(os.orders_submitted_instore/ev.dpid_cnt,0),'9,999,999') "[OI#]" --as "Orders - In Store"
      
      --User Acive in Last 7 Days?
      
      
      ,to_char(round(p.online_prospect_cnt/ev.dpid_cnt,0),'9,999,999') as"[OP#]" --"Prospects - Online"
      ,to_char(round(orders_submitted_online/ev.dpid_cnt,0),'9,999,999') as "[OO#]"-- "Orders - Online"
      ,case when COALESCE(p.prospect_cnt,0)=0 then '0%' else to_char(round(os.orders_submitted_online/p.prospect_cnt,2)*100,'9999%') end as "[OCO#]"   -- order conversion
      ,case when e.prosects_pencils=0 then 0 else round(e.pencils/e.prosects_pencils,1) end as "[PPP#]" -- Pencils per prospect
      ,to_char(round(e.prosects_pencils/ev.dpid_cnt,0) ,'9,999,999') as "[PP#]" -- Prospects who generated a pencil  
      ,to_char(round(ov.sheets_cnt/ev.dpid_cnt,0),'9,999,999') as "[PD#]" --"Price Deal Sheets Reviewed"
       ,to_char(round(ls.trades_valued_cnt/ev.dpid_cnt,0),'9,999,999') as "[TE#]" --"Trades Valued"
      ,TO_CHAR((sm.express_avg_session_duration || ' second')::interval, 'MI:SS') "[ASE#]" --as "Average Session Duration - Express"
      ,TO_CHAR((sm.dealer_avg_session_duration || ' second')::interval, 'MI:SS') "[ASN#]" -- as "Average Session Duration - Native"
      ,round(sm.express_avg_pages_per_session,1) as "[PSE#]" --"Pages Per Session - Express"
      ,round(sm.dealer_avg_pages_per_session,1) as "[PSN#]" --"Pages Per Session - Native"
      ,to_char(round(sm.express_bounce,2)*100,'9999%')  as "[BRE#]"-- "Bounce Rate - Express"
      ,to_char(round(sm.dealer_bounce,2)*100,'9999%')  as "[BRN#]"--"Bounce Rate - Native"
    
      
      ,coalesce(round(orders_submitted_open/ev.dpid_cnt,0),0 )as "[OOO#]"-- Online Orders Open
      ,coalesce(round(orders_submitted_cancelled/ev.dpid_cnt,0),0 ) as "[OOC#]"-- Online Orders Canclled
      ,coalesce(round(orders_submitted_completed/ev.dpid_cnt,0),0 ) as "[OOD#]"-- Online Orders Completed
      ,coalesce(round( os.vehicle_details_pricing /ev.dpid_cnt,0),0 ) as "[DS#]"-- Deal Sheet
      ,coalesce(round( os.trade_in_completed /ev.dpid_cnt,0),0 ) as "[TI#]"-- Trade In
      ,coalesce(round(os.credit_completed /ev.dpid_cnt,0),0 ) as "[CI#]"-- Credit Info
      ,coalesce(round(os.service_plans /ev.dpid_cnt,0),0 ) as "[SP#]"-- Service Plans
      ,coalesce(round(os.accesories /ev.dpid_cnt,0),0 ) as "[AC#]"-- Accesories
      ,coalesce(round( os.final_review /ev.dpid_cnt,0),0 ) as "[FR#]"-- Final Deal Sent
      
      ,case when (round(orders_submitted/ev.dpid_cnt,0) - round( os.vehicle_details_pricing /ev.dpid_cnt,0))<0 then 0 else round(orders_submitted/ev.dpid_cnt,0) - round( os.vehicle_details_pricing /ev.dpid_cnt,0) end  as "[OSS#]"
      ,case when (round( os.vehicle_details_pricing /ev.dpid_cnt,0)  - round( os.trade_in_completed /ev.dpid_cnt,0))<0 then 0 else round( os.vehicle_details_pricing /ev.dpid_cnt,0)  - round( os.trade_in_completed /ev.dpid_cnt,0) end as "[DSS#]"
      ,case when (round( os.trade_in_completed /ev.dpid_cnt,0) - round(os.credit_completed /ev.dpid_cnt,0))<0 then 0 else round( os.trade_in_completed /ev.dpid_cnt,0) - round(os.credit_completed /ev.dpid_cnt,0) end as "[TIS#]"
      ,case when(round(os.credit_completed /ev.dpid_cnt,0) - round(os.service_plans /ev.dpid_cnt,0))<0 then 0 else round(os.credit_completed /ev.dpid_cnt,0) - round(os.service_plans /ev.dpid_cnt,0)end  as "[CIS#]"
      ,case when(round(os.service_plans /ev.dpid_cnt,0) - round(os.accesories /ev.dpid_cnt,0))<0 then 0 else round(os.service_plans /ev.dpid_cnt,0) - round(os.accesories /ev.dpid_cnt,0) end   as "[SPS#]"
      ,case when(round(os.accesories /ev.dpid_cnt,0) - round( os.final_review /ev.dpid_cnt,0))<0 then 0 else round(os.accesories /ev.dpid_cnt,0) - round( os.final_review /ev.dpid_cnt,0) end  as "[ACS#]"
      
      
      ,round(p.in_store_sales_cnt/ev.dpid_cnt,0) as "Sales - In Store"
      ,round(p.online_sales_cnt/ev.dpid_cnt,0) as "Sales - Online"
      ,round(p.in_store_prospect_cnt/ev.dpid_cnt,0) as "InStore"
      ,round(p.online_prospect_cnt/ev.dpid_cnt,0) as"Online"  --"Prospects - Online"
      
      ,roadster_sales
      ,nonroadster_sales
      ,case when roadster_sales = 0 then '$0' else to_char(round(new_roadster_front_gp/roadster_sales,0),'$99,999') end as "[NFR#]"
      ,case when nonroadster_sales = 0 then '$0' else to_char(round(new_nonroadster_front_gp/nonroadster_sales,0),'$99,999') end "[NFN#]"
      ,case when roadster_sales = 0 then '$0' else to_char(round(new_roadster_back_gp/roadster_sales,0),'$99,999') end as "[NBR#]"
      ,case when nonroadster_sales = 0 then '$0' else to_char(round(new_nonroadster_back_gp/nonroadster_sales,0),'$99,999') end as "[NBN#]"
      ,case when roadster_sales = 0 then '$0' else  to_char(round(used_roadster_front_gp/roadster_sales,0),'$99,999') end as "[UFR#]"
      ,case when nonroadster_sales = 0 then '$0' else to_char(round(used_nonroadster_front_gp/nonroadster_sales,0),'$99,999') end as "[UFN#]"
      ,case when roadster_sales = 0 then '$0' else to_char(round(used_roadster_back_gp/roadster_sales,0),'$99,999') end as "[UBR#]"
      ,case when nonroadster_sales = 0 then '$0' else to_char(round(used_nonroadster_back_gp/nonroadster_sales,0),'$99,999') end as "[UBN#]"
      ,case when roadster_sales = 0 or roadster_sales is null then '$0' else to_char(round((new_roadster_front_gp +new_roadster_back_gp + used_roadster_front_gp + used_roadster_back_gp)/roadster_sales,2),'$99,999') end as "[RGP#]"
      ,case when nonroadster_sales = 0 or nonroadster_sales is null then '$0' else to_char(round((new_nonroadster_front_gp +new_nonroadster_back_gp + used_nonroadster_front_gp + used_nonroadster_back_gp)/nonroadster_sales,2),'$99,999') end as "[NGP#]"
      ,ov.sheets_user_cnt "Users with Price Deal Sheets Reviewed"
      ,ov.active_agents as "[IAA#]"
      ,a.agents as "[IA#]"
     
from (select distinct dpid_list, groups,label , date_label, start_date, end_date from dpids) d
left join express_visitors ev on d.groups=ev.groups and d.date_label=ev.date_label
left join online ov on d.groups=ov.groups and d.date_label=ov.date_label
left join prospects p on d.groups=p.groups and d.date_label=p.date_label
left join leads_sub ls on d.groups=ls.groups and d.date_label=ls.date_label
left join events e on d.groups=e.groups and d.date_label=e.date_label
left join session_metrics sm on d.groups=sm.groups and d.date_label=sm.date_label
left join order_steps os on d.groups=os.groups and d.date_label=os.date_label
left join sales s on d.groups=s.groups and d.date_label=s.date_label
left join agents a on d.groups=a.groups and d.date_label=a.date_label 


order by 2
-- where case when '{{ Target_dpid | replace: ",","','" }}'='longotoyota' then 0 else 1 end =1
-- UNION

-- select 'Dpid Fail'
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- ,NULL
-- ,null
-- where case when '{{ Target_dpid | replace: ",","','" }}'='longotoyota' then 0 else 1 end =0


{% form %}

Target_start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}

Target_end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  

{% endform %}
{% form %}
  Target_date_label:
    type: text
    default: Current Week

{% endform %}        

{% form %}

Comparison_start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 1332800 | date: '%Y-%m-%d' }}

Comparison_end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}
  

{% endform %}
{% form %}

  Comparison_date_label:
    type: text
    default: Previous Week

  Target_dpid:
    type: text
    default: longotoyota
    
  Target_Label:
    type: text
    default: Longo Toyota
  
  Comparison_1_dpid:
    type: text
    default: cochranmazdanorth
    
  Comparison_1_Label:
    type: text
    default: Cochran Mazda
    
  Comparison_2_dpid:
    type: text
    default: toyotawc
    
  Comparison_2_Label:
    type: text
    default: Toyota of Walnut Creek
    
{% endform %}    



