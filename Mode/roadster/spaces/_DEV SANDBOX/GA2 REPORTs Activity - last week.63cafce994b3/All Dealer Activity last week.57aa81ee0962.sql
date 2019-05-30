

-- Grab Pageviews from GA
WITH tGA AS
  (SELECT ga_pageviews.id,
          ga_pageviews.count, (ga_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone DealerTime,
              ga_pageviews.page_path,
              ga_pageviews.landing_page_path,
              ga_pageviews.property,
              ga_pageviews.dpid,
              ga_pageviews.distinct_id,
              ga_pageviews.in_store,
              ga_pageviews.agent_id,
              ga_pageviews.agent_email,
              ga_pageviews.full_referrer
   
   FROM ga_pageviews
   
-- Join dealer_partners to get the Time zone
-- Filter down to only Dealer Admin pages, and only the past 7 days
   LEFT JOIN public.dealer_partners dp 
   ON ga_pageviews.dpid = dp.dpid
   
   WHERE Property = 'Dealer Admin'
     AND ((ga_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME
          ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '7 days' :: interval)
     AND ((ga_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME
          ZONE dp.timezone) < (date_trunc('day' :: text, now())) 
     AND dp.status = 'Live'),

        
-- Search the page path to figure out which report was pulled 
-- count by date, report and agent
    tReportCount AS
  (SELECT Property,
          btrim(regexp_replace(regexp_replace((tGA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS page_path_fixed,
          dpid,
          agent_email,
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

       where agent_email !~* '@roadster.com\M'
       and dp.status = 'Live'

Group By "Dealer Partner",  "Success Manager", "Account Executive"
order by "Report Views" DESC




