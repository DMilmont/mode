 select distinct tableau_secret
  from dealer_partners 
  where status = 'Live'
  
  {% form %}

dpsk:
    type: select
    default: '1766768799'
    label: dpsk
    input_type: string
    options:
        labels: tableau_secret
        values: tableau_secret

{% endform %}