
SELECT sf2.integration_manager "Integration Manager",
      admin.name as "Admin Dealer Name", 
      case when sf2.dealer_name is null then '<<can''t find - DPID must be wrong too>>' else sf2.dealer_name END "Salesforce Dealer Name" ,
      admin.dpid as "Admin DPID", admin.status as "Admin Status" 

FROM public.dealer_partners admin

left join fact.salesforce_dealer_info sf on admin.name = sf.dealer_name
left join fact.salesforce_dealer_info sf2 on admin.dpid = sf2.dpid 

where sf.dealer_name is null 
and admin.status = 'Live'
  and admin.dpid <> 'miniofsterling'
  and admin.dpid <> 'bmwofsterling'
  and admin.dpid <> 'landrovermarin'
  and admin.dpid <> 'masterautomotive'
  and admin.dpid <> 'clearshiftcars'

order by sf2.integration_manager, admin.name
;