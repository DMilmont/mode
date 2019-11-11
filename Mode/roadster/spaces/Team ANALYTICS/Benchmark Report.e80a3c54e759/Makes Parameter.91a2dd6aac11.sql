SELECT DISTINCT CASE WHEN primary_make = 'All' THEN 'Multiple (Usually Used Rooftops)' else primary_make END AS primary_make
FROM public.dealer_partners
ORDER BY primary_make
  
  
{% form %}

primary_make: 
  type: multiselect
  default: Toyota
  label: Primary Make (Limit 3)
  options: 
    values: primary_make
  description: Select your Primary Make(s)

{% endform %}