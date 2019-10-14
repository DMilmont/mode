select * 
      ,'Summary' as title
from report_layer.vin_metrics
where  dpid='{{dpid}}'
and grade='New'
order by vdp_viewers desc

