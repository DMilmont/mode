SELECT DISTINCT dpid, tableau_secret dpsk
FROM public.dealer_partners
ORDER BY tableau_secret

{% form %}

dpsk: 
  type: text
  default: 1490125467
  options: 
    labels: dpsk
    values: dpsk
  description: Dealer Secret Key

{% endform %}