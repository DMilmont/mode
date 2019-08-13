 select distinct dpid,tableau_secret
  from dealer_partners 
  where status in ( 'Live','Pending')
  ORDER by dpid
  
  {% form %}

dpid:
    type: select
    default: 'johnelwaycadillac'
    label: dpid
    input_type: string
    options:
        labels: dpid
        values: dpid

{% endform %}


