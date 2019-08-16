SELECT DISTINCT State
FROM public.dealer_partners
WHERE state is not null
AND state <> ''

{% form %}

state:
    type: multiselect
    default: all
    options:
        values: state
{% endform %}