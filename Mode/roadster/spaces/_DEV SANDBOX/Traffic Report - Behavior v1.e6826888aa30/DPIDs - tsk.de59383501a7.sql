 select distinct tableau_secret
  from dealer_partners 
  where status in ( 'Live','Pending')
  
  {% form %}

dpsk:
    type: select
    default: '1449378703'
    label: dpsk
    input_type: string
    options:
        labels: tableau_secret
        values: tableau_secret

{% endform %}
