
SELECT dp.dpid, sf.success_manager, sf.account_executive 
from public.dealer_partners dp 
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid 
WHERE  dp.status = 'Live' or sf.status = 'Live'
ORDER BY dpid ASC

{% form %}

dpid: 
  type: select
  options: 
    labels: dpid
    values: dpid
    default: 'lexusofpleasanton'
  description: Please select a DPID  

{% endform %}