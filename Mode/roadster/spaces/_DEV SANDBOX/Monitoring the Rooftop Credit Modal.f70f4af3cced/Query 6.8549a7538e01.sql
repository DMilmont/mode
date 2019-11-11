SELECT DISTINCT primary_make, state
FROM public.dealer_partners
  
  
{% form %}

Primary_Make: 
  type: select
  default: Toyota
  options: 
    labels: primary_make
    values: primary_make
  description: Select your make

{% endform %}

{% form %}

State: 
  type: select
  default: CA
  options: 
    labels: state
    values: state
  description: Select your state

{% endform %}