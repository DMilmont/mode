-- Sean's Scheduled run of 'Reports Activity Last Week' Query: Least Active Live Dealers



WITH tGA AS
  (SELECT gs.dpid, COUNT(*) Total_Views
   FROM ga2_pageviews
   LEFT join (
  SELECT *
   FROM public.ga2_sessions
   WHERE agent_dbid ~ '^[0-9]*$'
   AND timestamp > (date_trunc('day' :: text, now()) - '28 days' :: interval)
   ) gs ON ga2_pageviews.ga2_session_id = gs.id
   LEFT JOIN agents a ON gs.agent_dbid::integer = a.user_dbid

   LEFT JOIN public.dealer_partners dp
     ON gs.dpid = dp.dpid

   WHERE Property = 'Dealer Admin'
     AND ga2_pageviews.page_path ~~* '%/reports/%' -- Pull the past 7 days

     AND ((ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '28 days' :: interval)
     AND ((ga2_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone) < (date_trunc('day' :: text, now()))
     AND a.email !~* '@roadster.com\M'
   GROUP BY gs.dpid
   
   ),

tab2 AS
  (SELECT dp.dpid, name, tGA.total_views, status
       
   FROM public.dealer_partners dp

   LEFT JOIN tGA
     ON dp.dpid = tGA.dpid)

SELECT tab2.name as "Dealer Partner", tabAE.success_manager as "Success Manager", tabAE.account_executive AS "Account Executive", tab2.status as "Status", 
       CASE
           WHEN tab2.total_views IS NULL THEN 0
           ELSE tab2.total_views
       END AS "Report Views"
FROM tab2

LEFT JOIN fact.salesforce_dealer_info tabAE
  ON tab2.dpid = tabAE.dpid

  WHERE tab2.total_views IS NULL
  and tab2.status = 'Live'

order by "Dealer Partner" ASC;