SELECT DISTINCT dpid, tableau_secret dpsk
FROM public.dealer_partners
ORDER BY dpid 
  
  
{% form %}

dpid: 
  type: select
  default: toyotasunnyvale
  options: 
    labels: dpid
    values: dpid
  description: Select your Dealer

{% endform %}