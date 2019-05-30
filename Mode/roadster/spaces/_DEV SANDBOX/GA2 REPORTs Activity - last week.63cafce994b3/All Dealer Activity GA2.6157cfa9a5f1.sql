


-- Grab Pageviews from GA2
WITH tGA AS
  (
  SELECT    count(1), 
             gap.id,
             (gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone DealerTime,
              gap.page_path,
              gas.landing_page_path,
              gap.property,
              gas.dpid,
              gap.distinct_id,
              gas.in_store,
              --gas.agent_id,
              agent.email
              --gas.full_referrer
   
   FROM ga2_pageviews gap
   
-- Join dealer_partners to get the Time zone
-- Filter down to only Dealer Admin pages, and only the past 7 days
   Left join public.ga2_sessions gas on gap.ga2_session_id = gas.id 
   LEFT JOIN public.dealer_partners dp  ON gas.dpid = dp.dpid 
   left join public.agents agent on gas.agent_dbid::integer = agent.user_dbid
   
   WHERE 
        gap.property = 'Dealer Admin'
     AND ((gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '7 days' :: interval)
     AND ((gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone) < (date_trunc('day' :: text, now())) 
     AND dp.status = 'Live'
     and  gas.agent_dbid ~ '^[0-9]*$' -- throw out non-numerical user IDs
     
     group by 2,3,4,5,6,7,8,9,10
     ),
     

        
-- Search the page path to figure out which report was pulled 
-- count by date, report and agent
    tReportCount AS
  (SELECT Property,
          btrim(regexp_replace(regexp_replace((tGA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS page_path_fixed,
          dpid,
          email,
          date_part('day', DealerTime) day_t,
          date_part('month', DealerTime) month_t,
          date_part('year', DealerTime) year_t,
          count(*) AS daily_views
   FROM tGA
   WHERE ((tGA.page_path) :: text ~~* '%/reports/%' :: text)
   GROUP BY Property,
            btrim(regexp_replace(regexp_replace((tGA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)),
            date_part('day', DealerTime),
            date_part('month', DealerTime),
            date_part('year', DealerTime),
            dpid,
            email)


SELECT 
       RANK() OVER (ORDER BY SUM(tReportCount.daily_views) DESC) Rank,
       dealer_name AS "Dealer Partner",
       sum(tReportCount.daily_views) AS "Report Views",
       dp.success_manager as "Success Manager",
       dp.account_executive as "Account Executive",
       dp.account_executive || '<br/>('  || ')' as "Display Label"

FROM tReportCount

LEFT JOIN fact.salesforce_dealer_info dp
  ON tReportCount.dpid = dp.dpid
       where email !~* '@roadster.com\M'
       and dp.status = 'Live'

Group By "Dealer Partner",  "Success Manager", "Account Executive"
order by "Report Views" DESC




