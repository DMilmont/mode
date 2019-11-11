-- Sean's Scheduled run of 'Reports Activity Last Week' Query: Report utilization by Super Users

/* Super Users are defined as users who view at least 2 different reports per week
for at least 6 of the past 13 weeks.  */

WITH 
    GA AS ( SELECT 
            gas.agent_dbid,
            gas.dpid,
            (gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone "dealertime",
            gap.property,
            gap.page_path,
            gap.distinct_id,
            1 count
   FROM ga2_pageviews gap
   left join public.ga2_sessions gas on gas.id = gap.ga2_session_id
   left join public.dealer_partners dp on gas.dpid = dp.dpid
   WHERE property = 'Dealer Admin')
   

  ,GA_wk AS (SELECT 
          GA.agent_dbid,
          date_trunc('week',dealertime)::date "week",
          btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS report,
          count(1) as "report_views",
          count(distinct GA.dpid) as "distinct_dpids"
   FROM GA
   left join fact.salesforce_dealer_info sf on sf.dpid = GA.dpid
   WHERE ((GA.page_path) :: text ~~* '%/reports/%' :: text)
   and sf.status is not null
   and dealertime is not null 
   and dealertime > now() - '13 weeks'::interval
   GROUP BY 1,2,3)

  ,GA_user_wk as (SELECT
      agent_dbid,
      avg(distinct_dpids) "avg_distinct_dpids",
      count(distinct week)"distinct_weeks",
      avg("report_views") "avg_report_views"
    from GA_wk
    group by 1
  )
  
    ,superusers as (SELECT
      agent_dbid,
      ag.email,
      distinct_weeks,
      avg_report_views
    from GA_user_wk guw
    left join public.agents ag on ag.user_dbid::integer = guw.agent_dbid::integer
    where distinct_weeks >= 6 --arbitraily chosen threshold.  SuperUsers must view reports in >= 6 distinct weeks. 
    and avg_report_views >=2 -- arbitraily chosen threshold.  SuperUsers must view at least 2 reports per week, on average.  
    and agent_dbid ~ '^[0-9]*$' --dump all the strange user ids with characters.  
    and ag.email not ilike '%roadster%'-- exclude Roadster Employees
    and ag.email is not null 
  )
  
    ,superuser_reports as (
    select 
        su.agent_dbid,
        su.email,
        gaw.report,
        count(distinct gaw.week) "distinct_weeks",
        sum(gaw.report_views) "total_report_views"
      from  superusers su
      left join GA_wk gaw on gaw.agent_dbid = su.agent_dbid
      group by 1,2,3) --hi

    ,current_reports as(SELECT report from GA_wk where week >= now() - '3 weeks'::interval group by 1)
    
      select 
        case when cr.report = 'kpis' then '1.0 Performance/KPIs (default)'
             when cr.report in ('overview', 'express visitors prospects') then '2.0 Traffic/Overview'
             when cr.report in ('top referring and landing pages', 'referral landing') then '2.1 Traffic/Top Referring and Landing Pages'
             when cr.report in ('referral all', 'referral breakdown') then '2.2 Traffic/Referral All'
             when cr.report in ('landing all', 'landing breakdown') then '2.3 Traffic/Landing All'
             when cr.report = 'session level metrics bounce rate' then '2.4 Traffic/Landing All'
             when cr.report in ('summary', 'sales summary prospects') then '3.0 Prospect/Summary'
             when cr.report = 'orders' then '3.1 Prospects/Orders'
             when cr.report = 'orders f i and accessories' then '3.2 Prospects/Orders F&I and Accessories'
             when cr.report = 'close rate' then '3.3 Prospects/Close Rate'
             when cr.report = 'details' then '3.4 Prospect/Details'
             when cr.report in ('utilization', 'utilization v2', 'agent utilization') then '4.1 Agent/Utilization'
             when cr.report = 'certification' then '4.2 Agent/Certification'
             when cr.report = 'shares open rate' then '4.3 Agent/Shares Open Rate'
             when cr.report = 'behavior' then '2.3 Traffic/Behavior [MODE]'
             when cr.report = 'dealer group report' then '5.1 Dealer Group Report [MODE]'
             when cr.report = 'overviewt' then '2.1 Traffic/Overview [MODE]'
             when cr.report in ('prospect dashboard', 'prospects dashboard') then '3.1 Prospects/Prospect Dashboard [MODE]'
             when cr.report = 'sales dashboard' then '3.2 Prospects/Sales Dashboard [MODE]'
             when cr.report = 'session level metrics' then '2.4 Traffic/Session Level Metrics [MODE]'
             when cr.report = 'shares open click rates' then '4.3 Agents/Shares Open Click Rates [MODE]'
             when cr.report = 'top referring and landing page' then '2.2 Traffic/Top Referring and Landing Page [MODE]'
             
             
             else cr.report end as "Report"
        
        ,COALESCE(sum(sr.distinct_weeks),0) as "Distinct User-Weeks"
        ,COALESCE(sum(sr.total_report_views),0) as "Total Report Views"
      
      from current_reports cr
      left join superuser_reports sr on sr.report = cr.report
      --where distinct_weeks >=2
      where  total_report_views >=1
      group by 1
      order by 1 asc
      
      