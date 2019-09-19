with dpids as (

select distinct dpid ,'{{ Target_dpid}}' as dpid_list,id,'Target Group - Target Date'as groups,'{{Target_start_date}}'  as start_date, '{{Target_end_date}}'  as end_date, '{{Target_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Target_dpid | replace: ",","','" }}')
UNION
select distinct dpid,'{{ Target_dpid}}' as dpid_list ,id,'Target Group - Compare Date' as groups,'{{Comparison_start_date}}'  as start_date, '{{Comparison_end_date}}'  as end_date, '{{Comparison_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Target_dpid | replace: ",","','" }}')
union 
select distinct dpid,'{{ Comparison_dpid}}' as dpid_list ,id,'Comparison Group - Target Date' as groups,'{{Target_start_date}}'  as start_date, '{{Target_end_date}}'  as end_date, '{{Target_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Comparison_dpid | replace: ",","','" }}')
UNION
select distinct dpid,'{{ Comparison_dpid}}' ,id,'Comparison Group - Compare Date' as groups,'{{Comparison_start_date}}'  as start_date, '{{Comparison_end_date}}'  as end_date, '{{Comparison_date_label}}'  as date_label
from public.dealer_partners
where dpid in ('{{ Comparison_dpid | replace: ",","','" }}')

) ,

express_visitors as (
SELECT   d.groups
        ,d.date_label
        ,count(distinct t.dpid) as dpid_cnt
        ,count(DISTINCT t.distinct_id) express_cnt
        ,count(distinct t.date || t.dpid) as dpid_days_cnt
  FROM fact.f_traffic t 
  inner join dpids d on t.dpid=d.dpid and d.start_date::date<=t.date and d.end_date::date>=t.date
  where t.is_in_store is false
  group by 1,2
),
online_visitors as (
SELECT   d.groups
        ,d.date_label
        ,count(distinct (gs.timestamp::date)::varchar(100) || gs.dpid) as dpid_days
        ,count(DISTINCT gs.distinct_id) site_cnt

  FROM ga2_sessions gs
  left join ga2_pageviews gp on gp.ga2_session_id = gs.id
  inner join dpids d on gs.dpid=d.dpid and d.start_date::date<=gs.timestamp::date and d.end_date::date>=gs.timestamp::date
  where gs.in_store is false
  and gp.property = 'Main Sites'
  group by 1,2
),
price_sheets as (
SELECT   d.groups
        ,d.date_label
        ,count(1) as sheets_cnt
        ,count(DISTINCT gs.distinct_id) sheets_user_cnt

  FROM ga2_sessions gs
  left join ga2_pageviews gp on gp.ga2_session_id = gs.id
  inner join dpids d on gs.dpid=d.dpid and d.start_date::date<=gs.timestamp::date and d.end_date::date>=gs.timestamp::date
  where gp.property = 'Express Sites'
  and gp.page_path in ('/modal/modal-price-summary','/modal_price_summary','/virtual/modal-price-summary')
  group by 1,2
),
prospects as 
(SELECT   d.groups
        ,d.date_label
        ,count(distinct cohort_date_utc || p.dpid) as dpid_days
        ,count(distinct customer_email) as prospect_cnt
        ,count (distinct case when is_in_store is true then customer_email else null end) as in_store_prospect_cnt
        ,count  ( distinct case when is_in_store is false then customer_email else null end) as online_prospect_cnt
        
        ,count(distinct case when item_type = 'OrderStarted' and source = 'Lead Type' then customer_email else null end ) as order_cnt
        ,count (distinct case when is_in_store is true and item_type = 'OrderStarted' and source = 'Lead Type' then customer_email else null end) as in_store_order_cnt
        ,count  ( distinct case when is_in_store is false and item_type = 'OrderStarted' and source = 'Lead Type' then customer_email else null end) as online_order_cnt
        
        ,count(distinct case when is_prospect_close_sale = true and source = 'Lead Type' then customer_email else null end ) as sales_cnt
        ,count (distinct case when is_in_store is true and is_prospect_close_sale = true and source = 'Lead Type' then customer_email else null end) as in_store_sales_cnt
        ,count  ( distinct case when is_in_store is false and is_prospect_close_sale = true and source = 'Lead Type' then customer_email else null end) as online_sales_cnt
        
from fact.f_prospect p      
inner join dpids d on d.dpid=p.dpid and d.start_date::date<=p.cohort_date_utc and d.end_date::date>=p.cohort_date_utc
group by 1,2
),
leads_sub as 
(SELECT   d.groups
        ,d.date_label
        ,count(distinct (timestamp::date)::varchar(100) || ls.dealer_partner_id) as dpid_days
        ,sum(case when type = 'SharedExpressVehicle' and  sent_at is not null then 1 else 0 end )as share_cnt     
        ,sum(case when type = 'SharedExpressVehicle' and clicked_at is not null then 1 else 0 end) as clicked_cnt
        ,sum(case when type = 'TradeEstimate' then 1 else 0 end) as trades_valued_cnt
        
from public.lead_submitted ls      
inner join dpids d on d.id=ls.dealer_partner_id and d.start_date::date<=timestamp::date  and d.end_date::date>=timestamp::date 
group by 1,2
),

events as (
SELECT   d.groups
        ,d.date_label
        ,count(distinct (timestamp::date)::varchar(100) || ue.dealer_partner_id) as dpid_days
        ,count (distinct case when name='Copy To Clipboard' then user_event_dbid else null end) as copies
        ,count (distinct case when name in ('Print Share Details','Print Price Summary') then user_event_dbid else null end) as prints
        ,count (distinct case when name='Deal Built' then user_event_dbid else null end) as pencils
from user_events ue    
inner join dpids d on d.id=ue.dealer_partner_id and d.start_date::date<=timestamp::date  and d.end_date::date>=timestamp::date 
group by 1,2
),
session_metrics as (
select d.groups
        ,d.date_label
        ,round(sum(case when session_type in ('Dealer + Express Site','Express Site Only')  then duration else 0 end)::decimal/sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end),3) as express_avg_session_duration
        ,round(sum(case when session_type in ('Dealer Main Site Only') then duration else 0 end)::decimal/sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end),3) as dealer_avg_session_duration  
        ,round(sum(case when session_type in ('Dealer + Express Site','Express Site Only')  then pageviews else 0 end)::decimal/sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end),3) as express_avg_pages_per_session
        ,round(sum(case when session_type in ('Dealer Main Site Only') then pageviews else 0 end)::decimal/sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end),3) as dealer_avg_pages_per_session

        ,round(sum(case when session_type in ('Dealer + Express Site','Express Site Only') and bounce is true then 1 else 0 end)::decimal/sum(case when session_type in ('Dealer + Express Site','Express Site Only') then 1 else 0 end),3) as express_bounce 
        ,round(sum(case when session_type in ('Dealer Main Site Only') and bounce is true then 1 else 0 end)::decimal/sum(case when session_type in ('Dealer Main Site Only') then 1 else 0 end),3) as dealer_bounce  
from fact.f_sessions s
  inner join dpids d on s.dpid=d.dpid and d.start_date::date<=s.date_local and d.end_date::date>=s.date_local
where COALESCE(session_type,'x')<>'Dealer Admin'

group by 1,2
)

select d.dpid_list as "DPID List"
      ,d.groups as "Groups"
      ,d.date_label as "Date Label"
      ,d.start_date || ' - ' || d.end_date as "Date Range"
      ,ev.dpid_cnt as "DPIDs in Group"
      ,ev.dpid_days_cnt as "Active Days for all DPIDs"
      ,ov.site_cnt as "Dealer Website Visitors"
      ,ev.express_cnt as "Express Visitors"
      ,round(ev.express_cnt::decimal/ov.site_cnt,3) as "Express Ratio"
      ,p.prospect_cnt as "Prospects"
      ,p.in_store_prospect_cnt as "Prospects - In Store"
      ,p.online_prospect_cnt as "Prospects - Online"
      ,round(p.prospect_cnt::decimal/ev.express_cnt,3) as "Prospect Ratio"
      ,ls.share_cnt as "Shares"
      ,ls.clicked_cnt as "Shares Clicked"
      ,round(ls.clicked_cnt::decimal/share_cnt,3) as "Click-Thru Rate"
      ,p.order_cnt as "Orders"
      ,p.in_store_order_cnt as "Orders - In Store"
      ,p.online_order_cnt as "Orders - Online"
      ,p.sales_cnt as "Sales"
      ,p.in_store_sales_cnt as "Sales - In Store"
      ,p.online_sales_cnt as "Sales - Online"
      ,round(p.sales_cnt::decimal/p.prospect_cnt,3) as "Closed Rate"
      ,e.copies as "Copies"
      ,e.prints as "Prints"
      ,e.pencils as "Pencils"
      ,TO_CHAR((sm.express_avg_session_duration || ' second')::interval, 'MI:SS') as "Average Session Duration - Express"
      ,TO_CHAR((sm.dealer_avg_session_duration || ' second')::interval, 'MI:SS') as "Average Session Duration - Native"
      ,sm.express_avg_pages_per_session as "Pages Per Session - Express"
      ,sm.dealer_avg_pages_per_session as "Pages Per Session - Native"
      ,sm.express_bounce as "Bounce Rate - Express"
      ,sm.dealer_bounce as "Bounce Rate - Native"
      ,ps.sheets_cnt as "Price Deal Sheets Reviewed"
      ,ps.sheets_user_cnt "Users with Price Deal Sheets Reviewed"
      ,ls.trades_valued_cnt as "Trades Valued"
from (select distinct dpid_list, groups , date_label, start_date, end_date from dpids) d
left join express_visitors ev on d.groups=ev.groups and d.date_label=ev.date_label
left join online_visitors ov on d.groups=ov.groups and d.date_label=ov.date_label
left join prospects p on d.groups=p.groups and d.date_label=p.date_label
left join leads_sub ls on d.groups=ls.groups and d.date_label=ls.date_label
left join events e on d.groups=e.groups and d.date_label=e.date_label
left join session_metrics sm on d.groups=sm.groups and d.date_label=sm.date_label
left join price_sheets ps on d.groups=ps.groups and d.date_label=ps.date_label



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

  Target_dpid:
    type: text
    default: longotoyota

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

  Comparison_dpid:
    type: text
    default: longolexus,toyotawc

{% endform %}        