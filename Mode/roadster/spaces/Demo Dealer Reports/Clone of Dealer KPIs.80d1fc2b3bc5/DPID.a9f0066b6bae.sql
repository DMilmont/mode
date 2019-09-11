 select distinct dpid
  from dealer_partners 
  where status = 'Live'
  ORDER by dpid
  
  {% form %}

dpid:
    type: select
    default: 'manchesterhonda'
    label: dpid
    input_type: string
    options:
        labels: dpid
        values: dpid

{% endform %}

