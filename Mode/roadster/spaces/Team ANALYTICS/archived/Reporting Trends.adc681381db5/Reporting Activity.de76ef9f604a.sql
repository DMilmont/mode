

SELECT *
FROM public.ga2_pageviews;

WITH tab1 AS
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
   LEFT JOIN public.dealer_partners dp ON ga_pageviews.dpid = dp.dpid
   WHERE Property = 'Dealer Admin'
     AND ((ga_pageviews."timestamp" AT TIME
           ZONE 'UTC') AT TIME
          ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '28 days' :: interval)
     AND ((ga_pageviews."timestamp" AT TIME
           ZONE 'UTC') AT TIME
          ZONE dp.timezone) < (date_trunc('day' :: text, now())) ),
        tab2 AS
  (SELECT Property,
          btrim(regexp_replace(regexp_replace((tab1.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS page_path_fixed,
          dpid,
          agent_email,
          date_part('day', DealerTime) day_t,
          date_part('month', DealerTime) month_t,
          date_part('year', DealerTime) year_t,
          count(*) AS daily_views
   FROM tab1
   WHERE ((tab1.page_path) :: text ~~* '%/reports/%' :: text)
   GROUP BY Property,
            btrim(regexp_replace(regexp_replace((tab1.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)),
            date_part('day', DealerTime),
            date_part('month', DealerTime),
            date_part('year', DealerTime),
            dpid,
            agent_email)
SELECT name AS "Dealer Partner",
       to_date(LPAD(day_t::text, 2, '0') || LPAD(month_t::text, 2, '0') || year_t::text, 'DDMMYYYY') "Date",
       initcap(tab2.page_path_fixed) AS "Report Type",
       agent_email AS "Agent Email",
       tab2.daily_views AS "Report Views",
       tab2.dpid,
       dp.status as "Dealer Status", 
       dp."SF_Success Manager" AS "Success Manager",
       dp."SF_Account Executive" AS "Account Executive",
       CASE
           WHEN agent_email ~* '@roadster.com\M' then '.Roadster Users'
           ELSE 'Customers'
       END AS "User Type"
FROM tab2

-- This pulling from a Temp table for now.  
-- As soon as we can get a Sync from SFDC to the application table, we can change this over to the normal dealer properties table. 

LEFT JOIN public.temp_dealer_properties_2019_03_08 dp
  ON tab2.dpid = dp.dpid
ORDER BY tab2.dpid ASC,
         to_date(LPAD(day_t::text, 2, '0') || LPAD(month_t::text, 2, '0') || year_t::text, 'DDMMYYYY') DESC, 
         tab2.daily_views DESC;