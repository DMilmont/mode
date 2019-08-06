SELECT DISTINCT dpid, tableau_secret dpsk
FROM public.dealer_partners
ORDER BY dpid 
  
  
{% form %}

dpsk: 
  type: text
  default: 0000000
  options: 
    labels: dpsk
    values: dpsk
  description: Select your tableau secret key

{% endform %}