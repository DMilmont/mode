  select dpid, tableau_secret, name 
  from dealer_partners 
  group by 1,2,3
  order by 3
  
  
{% form %}

select_dpid: 
  type: select
  default: longotoyota
  options:
    labels: name
    values: dpid
  description: Select a dealership

{% endform %}