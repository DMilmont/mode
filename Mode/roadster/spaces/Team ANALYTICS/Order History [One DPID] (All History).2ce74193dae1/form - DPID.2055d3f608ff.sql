
SELECT distinct sf.dpid
FROM  dealer_partners dp
left join fact.salesforce_dealer_info sf on sf.dpid = dp.dpid
where dp.status = 'Live' or sf.status = 'Live'
order by sf.dpid

  
{% form %}

dpid: 
  type: select
  options: 
    labels: dpid
    values: dpid
    default: 'longotoyota'
  description: Please select a DPID  

{% endform %}