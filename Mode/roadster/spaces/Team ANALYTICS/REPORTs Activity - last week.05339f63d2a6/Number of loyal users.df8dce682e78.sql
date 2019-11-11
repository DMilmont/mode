-- Sean's Scheduled run of 'Reports Activity Last Week' Query: Number of Loyal Users

/* We want to identify the number of users who are loyal to a given report - 
if a report has even a single loyal user then we should not consider that report for elimination - it's important to someone
Our definition of loyalty is: if a user pulls the report on 3 distinct days within the past 4 weeks, the report must be important to them.
*/

WITH 
    GA AS ( SELECT 
            gas.agent_dbid,
            dp.dpid,
            date_trunc('day',(gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone)::date "day",
            btrim(regexp_replace(regexp_replace((gap.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS report,
            --gap.distinct_id,
            count(1) as "report_views"
   FROM ga2_pageviews gap
   left join public.ga2_sessions gas on gas.id = gap.ga2_session_id
   left join public.dealer_partners dp on gas.dpid = dp.dpid
   left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
   WHERE property = 'Dealer Admin'
   and sf.status is not NULL
   and ((gap.page_path) :: text ~~* '%/reports/%' :: text)
   group by 1,2,3,4
   order by 1 asc, 2 desc)
   

   -- scan back and identify the number of unique days a report was pulled by a user.
   -- if a user pulls a report 18 times in a single day, that's counted as 1.
, GA_user_report_days as (select 
    agent_dbid
    --,GA.dpid
    ,ag.email
    ,date_trunc('week',"day")::date as week
    ,report
    ,count(report_views) as days_with_a_report_view
    ,sum(report_views) as total_report_views
   from GA
   left join public.agents ag on ag.user_dbid::integer = GA.agent_dbid::integer
   where GA.agent_dbid ~ '^[0-9]*$' --dump all the strange user ids with characters. 
    and GA.agent_dbid is not null
    and ag.email is not null 
    --and ag.email not ilike '%roadster%'-- exclude Roadster Employees
    group by 1,2,3,4)

    --this generates the base data and fills in zeros for weeks when users don't use the reports.  
, all_week_reports as (select week, report from GA_user_report_days group by 1,2)
, all_users as (select distinct agent_dbid, email from GA_user_report_days)
, base_data as (select week,report,agent_dbid,email from all_week_reports cross join all_users)

, GA_user_report_withzeros as (select 
      bd.agent_dbid
      ,bd.email
      --,bd.dpid
      ,case when bd.report = 'kpis' then '1.0 Performance/KPIs (default)'
             when bd.report in ('overview', 'express visitors prospects') then '2.0 Traffic/Overview'
             when bd.report = 'top referring and landing pages' then '2.1 Traffic/Top Referring and Landing Pages'
             when bd.report = 'referral all' then '2.2 Traffic/Referral All'
             when bd.report = 'landing all' then '2.3 Traffic/Landing All'
             when bd.report = 'session level metrics bounce rate' then '2.4 Traffic/Landing All'
             when bd.report = 'summary' then '3.0 Prospect/Summary'
             when bd.report = 'orders' then '3.1 Prospects/Orders'
             when bd.report = 'orders f i and accessories' then '3.2 Prospects/Orders F&I and Accessories'
             when bd.report = 'close rate' then '3.3 Prospects/Close Rate'
             when bd.report = 'details' then '3.4 Prospect/Details'
             when bd.report in ('utilization', 'utilization v2') then '4.1 Agent/Utilization'
             when bd.report = 'certification' then '4.2 Agent/Certification'
             when bd.report in ('dealer group report', 'dealer groups') then '5.1 Dealer Group Report [MODE]'
             when bd.report in ('shares open rate', 'shares open click rates') then '4.3 Agent/Shares Open Rate'
             when bd.report in ('prospect dashboard', 'prospects dashboard') then '3.1 Prospects/Prospect Dashboard [MODE]'
             when bd.report = 'sales dashboard' then '3.2 Prospects/Sales Dashboard [MODE]'
             when bd.report = 'behavior' then '2.3 Traffic/Behavior [MODE]'
             when bd.report = 'overviewt' then '2.1 Traffic/Overview [MODE]'
             when bd.report = 'session level metrics' then '2.4 Traffic/Session Level Metrics [MODE]'
             when bd.report = 'shares open click rates' then '4.3 Agents/Shares Open Click Rates [MODE]'
             when bd.report = 'top referring and landing page' then '2.2 Traffic/Top Referring and Landing Page [MODE]'
             else bd.report end as "report"
      ,bd.week::date
      ,COALESCE(days_with_a_report_view,0) total_days_viewed
      ,total_report_views
  from base_data bd 
  left join GA_user_report_days GAU on GAU.report = bd.report and GAU.week = bd.week and GAU.agent_dbid = bd.agent_dbid
 )


    
, agent_report_loyalty as (SELECT 
      agent_dbid, 
      email,
      --dpid,
      report, 
      week,
      -- scan back over the past 4 weeks and add up the number of unique days the report was pulled
       SUM(total_days_viewed) OVER (PARTITION BY report, agent_dbid ORDER BY week ROWS BETWEEN 5 preceding and current row) unique_reporting_days,
       total_days_viewed,
       total_report_views
FROM GA_user_report_withzeros)


select --dpid
      email
      ,report
      ,week
      ,SUM(total_days_viewed) total_days
      ,SUM(total_report_views) total_views
      ,max(unique_reporting_days) cum_days_past4wks

    from agent_report_loyalty 
    where  week <= date_trunc('week',now()) -'7 days'::interval
    --and week >= '2019-04-08'::date
    and unique_reporting_days >=3

    GROUP BY 1,2,3
    order by 1,2,3
