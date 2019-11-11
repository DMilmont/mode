SELECT DISTINCT dpid
FROM public.dealer_partners
ORDER BY dpid
  
  
{% form %}

dpid: 
  type: multiselect
  default: ' '
  options:
        values: "dpid"
  description: Select your Dpids. Make sure you put a single quote around each dpid. 

{% endform %}