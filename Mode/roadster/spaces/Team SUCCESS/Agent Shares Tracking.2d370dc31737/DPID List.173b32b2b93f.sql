 select distinct dpid
  from dealer_partners 
  where status = 'Live'
  ORDER by dpid
  
  {% form %}

dpid:
    type: select
    default: 'toyotawc'
    label: DPID
    input_type: string
    options:
        labels: dpid
        values: dpid

{% endform %}


