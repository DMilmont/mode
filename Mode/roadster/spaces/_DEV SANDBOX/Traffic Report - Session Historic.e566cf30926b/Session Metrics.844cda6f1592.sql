select *

from report_layer.ga2_session_metrics
where type = '{{ category }}' 
AND dpid='{{ dpid }}'
and session_type <> 'Dealer Admin'
{% form %}


category:
    type: select
    default: Main Site or Express Site
    options: [Main Site or Express Site, Express New or Used Shoppers,Express SRP or VDP Viewers,Acquisition Type]
{% endform %}