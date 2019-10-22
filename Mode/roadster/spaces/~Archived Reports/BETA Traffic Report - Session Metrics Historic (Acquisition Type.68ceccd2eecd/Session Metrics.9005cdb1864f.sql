select *

from fact.agg_monthly_session_metrics
where type = 'Acquisition Type' 
AND dpid='{{ dpid }}'
and session_type <> 'Dealer Admin'


--{% form %}

-- segment:
--     type: select
--     default: Main Site or Express Site
--     options: [Main Site or Express Site, Express New or Used Shoppers,Express SRP or VDP Viewers,Acquisition Type]
-- {% endform %}