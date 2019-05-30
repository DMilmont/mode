select count(distinct dpid)
from fact.mode_sfdc_status
where status != 'Cancelled'

