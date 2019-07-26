






SELECT sf.integration_manager "Integration Manager",
      admin.dpid as "Admin DPID", 
      admin.City as "Admin City", 
      sf.City as "Salesforce City", 
      sf.address as "SF Address",
      admin.address "Admin Address",
      admin.name as "Admin Dealer Name",
      sf.status as "Salesforce Status",
      sfi."Base_Product_Type__c" as "Base Product"
      

FROM public.dealer_partners admin

left join fact.salesforce_dealer_info sf on admin.dpid = sf.dpid
left join roadster_salesforce."Integration__c" sfi on admin.dpid = sfi."DealerPartnerID__c"

where admin.city <> sf.city
and sf.status <> 'Cancelled'
and sf.status <> 'Pending Cancellation'
and sfi."Base_Product_Type__c" <> 'Marketplace'

order by sf.integration_manager, admin.dpid 
