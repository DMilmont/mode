
SELECT generate_series(date_trunc('month', CURRENT_DATE- '6 mons'::interval), 
date_trunc('month', CURRENT_DATE ), '1 month'::interval)::date::text "Month & Year"

{% form %}

choose_your_date_range:
    type: multiselect
    default: '2019-05-01'
    options:
        values: "Month & Year"
{% endform %}