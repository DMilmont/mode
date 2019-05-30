
SELECT sf.integration_manager "Integration Manager",
      admin.zip as "Admin Zip", 
      sf.postal_code as "Salesforce Zip", 
      admin.dpid as "Admin DPID", 
      admin.name as "Admin Dealer Name",  
      sf.status as "Salesforce Status"

FROM public.dealer_partners admin

left join fact.salesforce_dealer_info sf on admin.dpid = sf.dpid

where admin.zip <> sf.postal_code

order by sf.integration_manager, admin.dpid



