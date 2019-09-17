
with page_views as (
SELECT 
    ag.department
    ,ag.job_title
    ,gas.dpid
    ,case when gas.in_store = true then 'instore' else 'online' end as "in_store"
    ,ag.first_name
    ,ag.last_name
    ,ag.email


    ,ag.last_login_at
    --,ag.created_at
    ,date_trunc('day',gas.timestamp) "date"
    ,gap.property
    ,gap.time_on_page
    ,gap.page_path
    ,gap.previous_page_path
    ,gap.url
    ,gap.embedded
    --,gas.timestamp
    ,gas.duration
    ,gas.landing_page_path
    ,gas.agent_dbid
    ,gas.device_category
    ,gas.session_count
    ,gas.express_landing_page
    ,gas.locale 
    
FROM public.ga2_sessions gas
left join public.ga2_pageviews gap
  ON gas.id = gap.ga2_session_id
left join public.agents ag
  ON gas.agent_dbid::integer = ag.user_dbid::integer
WHERE gas.agent_dbid ~ '^[0-9]*$'
  AND gas.dpid in('applehonda','applebmwofyork','applefordpa','applenissan','applechevyofredlion','applesubaru','applefordyork','applechevrolet') -- '{{dpid}}' 
  and last_name is not NULL
  and time_on_page is not NULL
  and gas.timestamp >= '05/09/2019' -- GA2 launch
  and ag.email not ilike '%roadster.com'
  order by ag.email, gap.timestamp
)

select 
       department
       ,job_title
       ,first_name
       ,last_name
       ,email

       ,to_char(date_trunc('month',date), 'YYYY-MM') as "month"
       ,property
       ,case  
          when property = 'Dealer Admin' and page_path ilike '%/orders%' then 'R_' || in_store || '/dealer_admin/orders'
          when property = 'Dealer Admin' and page_path ilike '%/trade_ins%' then 'R_' || in_store || '/dealer_admin/trade_ins'
          when property = 'Dealer Admin' and page_path ilike '%/user_contacts%' then 'R_' || in_store || '/dealer_admin/contacts'
          when property = 'Dealer Admin' and page_path ilike '%/Sign In%' then 'R_' || in_store || '/dealer_admin/Sign_In'
          when property = 'Dealer Admin' and page_path ilike '%/users%' then 'R_' || in_store || '/dealer_admin/users'
                    when property = 'Dealer Admin' and page_path ilike '%/rates%' then 'R_' || in_store || '/dealer_admin/rates'
          when property = 'Dealer Admin' and page_path ilike '%/desking_deals%' then 'R_' || in_store || '/dealer_admin/desking_deals'
          when property = 'Dealer Admin' and page_path ilike '%/reports%' then 'R_' || in_store || '/dealer_admin/reports'
           when property = 'Dealer Admin' and page_path ilike '%/inbox%' then 'R_' || in_store || '/dealer_admin/inbox'
           when property = 'Dealer Admin' and page_path ilike '%/credit_pre_approvals%' then 'R_' || in_store || '/dealer_admin/credit_pre_approvals'
           when property = 'Dealer Admin' and page_path ilike '%/trade_in%' then 'R_' || in_store || '/dealer_admin/trade_in'
           when property = 'Dealer Admin' and page_path ilike '%/vehicles%' then 'R_' || in_store || '/dealer_admin/vehicles'
           when property = 'Dealer Admin' and page_path ilike '%/agent%' then 'R_' || in_store || '/dealer_admin/agents'
           when property = 'Dealer Admin' and page_path ilike '%/ratings%' then 'R_' || in_store || '/dealer_admin/ratings'
           when property = 'Dealer Admin' and page_path = '/' || dpid then 'R_' || in_store || '/dealer_admin'
           
           when property = 'Main Sites' and page_path ilike '%/new-inventory/%' then 'web/new srp'
           when property = 'Main Sites' and page_path ilike '%/used-inventory/%' then 'web/used srp'
           when property = 'Main Sites' and page_path ilike '%/all-inventory/%' then 'web/new&used srp'
           when property = 'Main Sites' and page_path ilike '%/used/%' then 'web/used vdp'
           when property = 'Main Sites' and page_path ilike '%/new/%' then 'web/used vdp'

          when page_path = '/virtual/new-inventory' then 'R_' || in_store || '/NEW_SRP - Search Refinement'
          when page_path = '/virtual/used-inventory' then 'R_' || in_store || '/USED_SRP - Search Refinement'
          when page_path = '/New Inventory' then 'R_' || in_store || '/NEW_SRP'
          when page_path = '/New VDP' then 'R_' || in_store || '/NEW_VDP'
          when page_path = '/modal/credit-score-selection-modal' then 'R_' || in_store || '/Credit - Selection'
          when page_path = '/modal/soft-credit-modal' then 'R_' || in_store || '/Credit - Soft Credit Pull'
          when property = 'Express Sites' then 'R_' || in_store || page_path
          when property = 'Dealer Admin' then 'R_' || in_store || '/dealer_admin' || page_path
          
          else page_path end as "page_path"
       ,device_category 
       ,count(distinct date) "distinct days"
       ,sum(time_on_page) "total_time_on_page"
       ,count(1) "page count"
  from page_views
  group by 1,2,3,4,5,6,7,8,9
  order by department, last_name, first_name, "page count" desc