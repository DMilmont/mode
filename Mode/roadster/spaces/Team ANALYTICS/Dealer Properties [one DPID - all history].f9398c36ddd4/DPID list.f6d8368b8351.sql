
SELECT distinct dpid
FROM  dealer_partners
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