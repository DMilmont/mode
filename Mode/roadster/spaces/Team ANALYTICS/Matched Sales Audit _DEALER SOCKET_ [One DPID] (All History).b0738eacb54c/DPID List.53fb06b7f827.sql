


SELECT distinct     dp.dpid,   dp.primary_make, sf.success_manager, sf.account_executive, sf.integration_manager, sf.status
  
FROM public.crm_records crm

left join dealer_partners dp on crm.dealer_partner_id = dp.id
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid

where crm_type = 'dealer-socket'
  and crm.status = 'Sold'
  and created_at > now()-'3 months'::interval
  --and sf.status = 'live'
order by dpid

  
{% form %}

dpid: 
  type: select
  options: 
    labels: dpid
    values: dpid
  description: These are DPIDs who have at least 1 Dealer Socket sales record (matched or not) detected in our data warehouse.  

{% endform %}