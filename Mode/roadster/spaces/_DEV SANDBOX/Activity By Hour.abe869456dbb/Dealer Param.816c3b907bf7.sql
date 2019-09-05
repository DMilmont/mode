SELECT name
FROM dealer_partners
ORDER BY name


{% form %}

dealer_name:
    type: multiselect
    default: 'Longo Lexus'
    options:
        labels: name
        values: name

{% endform %}