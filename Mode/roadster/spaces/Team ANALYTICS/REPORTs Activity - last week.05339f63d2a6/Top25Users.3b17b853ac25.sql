-- Sean's Scheduled run of 'Reports Activity Last Week' Query: Top 25 Users

-- Grab Pageviews from GA
WITH tGA AS
  (
  SELECT ga2_pageviews.id,
            (ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone DealerTime,
              ga2_pageviews.page_path,
              gs.landing_page_path,
              ga2_pageviews.property,
              gs.dpid,
              ga2_pageviews.distinct_id,
              gs.in_store,
              a.email, 
              gs.full_referrer,
          1 count
   
   FROM ga2_pageviews
   
-- Join dealer_partners to get the Time zone
-- Filter down to only Dealer Admin pages, and only the past 7 days
   LEFT JOIN 
   (
   SELECT *
   FROM public.ga2_sessions
   WHERE agent_dbid ~ '^[0-9]*$'
   AND timestamp > (date_trunc('day' :: text, now()) - '7 days' :: interval)
   )
   gs ON ga2_pageviews.ga2_session_id = gs.id
   LEFT JOIN public.dealer_partners dp ON gs.dpid = dp.dpid
   LEFT JOIN agents a ON (gs.agent_dbid)::integer = a.user_dbid
   WHERE Property = 'Dealer Admin'
     AND ((ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME
          ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '7 days' :: interval)
     AND ((ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME
          ZONE dp.timezone) < (date_trunc('day' :: text, now())) 
     AND dp.status = 'Live'
     
     ),

        
-- Search the page path to figure out which report was pulled 
-- count by date, report and agent
    tReportCount AS
  (SELECT Property,
          btrim(regexp_replace(regexp_replace((tGA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS page_path_fixed,
          dpid,
          email agent_email,
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
            agent_email)


SELECT case when right(agent_email,4) = '.com' then left(agent_email,length(agent_email)-4) else agent_email end AS "Agent Email",
       dealer_name AS "Dealer Partner",
       sum(tReportCount.daily_views) AS "Report Views",
       RANK() OVER (ORDER BY SUM(tReportCount.daily_views) DESC) Rank,
       dp.success_manager as "Success Manager",
       dp.account_executive as "Account Executive"
FROM tReportCount

LEFT JOIN fact.salesforce_dealer_info dp
  ON tReportCount.dpid = dp.dpid

       where agent_email !~* '@roadster.com\M'
       --and dp.status <> 'Demo'

Group By "Agent Email", "Dealer Partner",  "Success Manager", "Account Executive"
order by "Report Views" DESC

limit 500


