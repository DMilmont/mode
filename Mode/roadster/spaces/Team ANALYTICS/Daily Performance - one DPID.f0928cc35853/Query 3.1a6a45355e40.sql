SELECT DISTINCT name
FROM public.dealer_partners
ORDER BY name 

{% form %}

dealer_name:
    type: select
    default: Toyota Demo
    options:
        labels: name
        values: name

{% endform %}
