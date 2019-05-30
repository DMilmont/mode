-- Returns first 100 rows from public.dealer_partners
SELECT sf.integration_manager "Integration Manager",
      admin.City as "Admin City", 
      sf.City as "Salesforce City", 
      admin.dpid as "Admin DPID", 
      admin.name as "Admin Dealer Name",
      sf.status as "Salesforce Status"

FROM public.dealer_partners admin

left join fact.salesforce_dealer_info sf on admin.dpid = sf.dpid

where admin.city <> sf.city
and sf.status <> 'Cancelled'

order by sf.integration_manager, admin.dpid 
