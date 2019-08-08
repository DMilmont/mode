
select status, 
      dpid,
      dealer_name, 
      to_char(effective_contract_date, 'YYYY_MM_DD') as "Effective Contract Date",
      to_char(contract_signed_date, 'YYYY_MM_DD') as "Contract Signed Date",
      to_char(actual_live_date, 'YYYY_MM_DD') as "Actual Live Date"
      
from fact.mode_sfdc_status
where status != 'Cancelled'
  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  
  and contract_signed_date is not NULL
group by 1, 2, 3, 4, 5, 6
order by 4 DESC
