{% form %}

start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 2678400 | date: '%Y-%m-%d' }}
  description: Start Date

end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 86400 | date: '%Y-%m-%d' }}
  description: End Date 

{% endform %}