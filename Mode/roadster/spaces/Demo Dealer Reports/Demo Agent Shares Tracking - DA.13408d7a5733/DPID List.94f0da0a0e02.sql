 select distinct dpid,tableau_secret
  from dealer_partners 
  where dpid  like '%demo%'
  ORDER by dpid
  
  {% form %}

dpid:
    type: select
    default: 'toyotademo'
    label: dpid
    input_type: string
    options:
        labels: dpid
        values: dpid

{% endform %}


