
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
    default: 'longotoyota'
  description: Please select a DPID  


start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}
  description: Data available for previous 3 months

end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  description: Data available for previous 3 months

{% endform %}