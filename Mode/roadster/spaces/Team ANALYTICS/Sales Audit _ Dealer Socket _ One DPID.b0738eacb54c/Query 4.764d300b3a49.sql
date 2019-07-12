
SELECT      dp.primary_make, sf.success_manager, sf.account_executive, sf.integration_manager, sf.status
    ,count(dp.dpid)
  
FROM public.crm_records crm

left join dealer_partners dp on crm.dealer_partner_id = dp.id
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid

where crm_type = 'dealer-socket'
  and crm.status = 'Sold'
  and created_at > now()-'3 months'::interval
  and sf.status = 'live'
group by 1,2,3,4,5,6

  