SELECT s::date
FROM generate_series(date_trunc('day', now() - '14 days'::interval), date_trunc('day', now()), '1 day') s

{% form %}

start_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 604800 | date: '%Y-%m-%d' }}
  
end_date: 
  type: date
  default: {{ 'now' | date: '%Y-%m-%d' }}

{% endform %}