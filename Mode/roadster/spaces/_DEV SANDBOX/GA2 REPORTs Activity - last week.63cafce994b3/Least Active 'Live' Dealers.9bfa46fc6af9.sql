-- This report accesses the following tables - PLEASE KEEP THIS UPDATED --
-- ga_pageviews
-- public.dealer_partners
-- fact.salesforce_dealer_info




WITH tGA AS
  (SELECT ga_pageviews.dpid, COUNT(*) Total_Views
   FROM ga_pageviews

   LEFT JOIN public.dealer_partners dp
     ON ga_pageviews.dpid = dp.dpid

   WHERE Property = 'Dealer Admin'
     AND ga_pageviews.page_path ~~* '%/reports/%' -- Pull the past 7 days

     AND ((ga_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone) > (date_trunc('day' :: text, now()) - '28 days' :: interval)
     AND ((ga_pageviews."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone) < (date_trunc('day' :: text, now()))
     AND ga_pageviews.agent_email !~* '@roadster.com\M'
   GROUP BY ga_pageviews.dpid),

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