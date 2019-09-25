SELECT DISTINCT primary_make
FROM public.dealer_partners
ORDER BY primary_make
  
  
{% form %}

primary_make: 
  type: select
  default: Toyota
  options: 
    labels: primary_make
    values: primary_make
  description: Select your Primary Make(s)

{% endform %}