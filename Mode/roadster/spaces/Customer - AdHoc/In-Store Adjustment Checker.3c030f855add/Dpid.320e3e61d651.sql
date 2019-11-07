SELECT DISTINCT dpid
FROM public.dealer_partners
ORDER BY dpid 
  
  
{% form %}

dpid: 
  type: select
  default: continentalmazda
  options: 
    labels: dpid
    values: dpid
  description: Select your Dealer

{% endform %}