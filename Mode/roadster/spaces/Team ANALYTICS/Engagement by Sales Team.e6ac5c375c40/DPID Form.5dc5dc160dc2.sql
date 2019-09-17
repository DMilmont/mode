
SELECT distinct dp.dpid
FROM  dealer_partners dp 
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid 
where dp.status = 'Live' or sf.status = 'Live'
and sf.status is not null 
order by dpid

  
{% form %}

dpid: 
  type: select
  options: 
    labels: dpid
    values: dpid
    default: 'longotoyota'
  description: Please select a DPID  

{% endform %}