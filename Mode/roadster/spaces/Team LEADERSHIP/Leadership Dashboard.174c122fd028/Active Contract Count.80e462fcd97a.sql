
-- This counts 'dealer_name' because DPID isn't always filled out for new contracts in SFDC:  Bug Fix by Sean 2019_04_12
select count(distinct dealer_name)
from fact.mode_sfdc_status
where status != 'Cancelled'
and status != 'Wind Down'
and contract_signed_date is not NULL  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  Bug Fix by Sean 2019_04_12


