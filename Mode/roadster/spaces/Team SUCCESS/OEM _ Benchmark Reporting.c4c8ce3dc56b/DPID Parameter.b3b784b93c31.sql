SELECT DISTINCT dpid
FROM public.dealer_partners
ORDER BY dpid
  
  
{% form %}

dpid: 
  type: multiselect
  default: ' '
  options:
        values: "dpid"
        label: "Choose DPIDs for Custom Grouping here"
  description: Select your Dpids. These will appear under your custom group heading in the tables below

{% endform %}