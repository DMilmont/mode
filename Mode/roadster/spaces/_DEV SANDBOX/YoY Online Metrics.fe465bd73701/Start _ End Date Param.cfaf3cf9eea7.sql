SELECT *
FROM fact.d_cal_date

{% form %}

start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}

end_date: 
  type: date
  default: '2019-07-16'

{% endform %}