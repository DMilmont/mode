-- Returns first 100 rows from public.dealer_partners
SELECT 
  sf.integration_manager as "Integration Manager",
  admin.status as "Admin Status [Please Fix]", 
  sf.status as "Salesforce Status [Correct]", 
  extract('day' from now() - sf.actual_live_date) as "Days Live",
  admin.dpid as "Admin DPID" 
  --,sf.dealer_name
--  admin.name as "Admin Dealer Name"

FROM public.dealer_partners admin

left join fact.salesforce_dealer_info sf on admin.dpid = sf.dpid
INNER JOIN (
SELECT
dpid,
--dealer_name,
MAX(created_timestamp) mx_timestamp
FROM fact.salesforce_dealer_info sdi
left join roadster_salesforce."Integration__c" i on sdi.dpid= i."DealerPartnerID__c"  and sdi.created_timestamp=i."CreatedDate"
where i."IsDeleted" is false
GROUP BY 1
) t ON sf.dpid = t.dpid AND sf.created_timestamp = t.mx_timestamp


where admin.status <> sf.status
  and not(admin.status = 'Terminated' and sf.status = 'Cancelled')
  and not(admin.status = 'Pending' and sf.status = 'In Dev')
  and not(admin.status = 'Pending' and sf.status = 'Stalled')
  and not(admin.status = 'Pending' and sf.status = 'Not Started')
  and not(admin.status = 'Live' and sf.status = 'Wind Down')
  and not(admin.status = 'Live' and sf.status = 'Pending Cancellation')
  and not(admin.status = 'Prospect' and sf.status = 'Not Started')
  and not(admin.status = 'Pending' and sf.status = 'Pending Cancellation')
  and not(admin.status = 'Cold' and sf.status = 'Cancelled')
  and admin.dpid not in ('miniofsterling', 'bmwofsterling', 'landrovermarin', 'masterautomotive', 'clearshiftcars', 'porschechandler')
  and sf.dealer_name not ilike('%(OLD)%')
order by sf.integration_manager, admin.status, sf.status, sf.actual_live_date desc, admin.dpid
;


