
SELECT admin.dpid as "Admin DPID [correct]", 

case when sf2.dpid is null then '???' else sf2.dpid END "Salesforce DPID [Please Fix]" ,
  admin.name as "Admin Dealer Name", 
  admin.status as "Admin Status"


FROM public.dealer_partners admin



left join fact.salesforce_dealer_info sf on admin.dpid = sf.dpid
left join fact.salesforce_dealer_info sf2 on admin.name = sf2.dealer_name

where sf.status is null 
and (admin.status = 'Live' or admin.status = 'Pending')
and admin.dpid  not in ('roadster', 'buysidedemo', 'fergusonsubaru', 'delaneyauto')
;

