

select  distinct status, dealer_name,dpid,  
      to_char(effective_contract_date, 'YYYY_MM_DD') as "Effective Contract Date",
      to_char(contract_signed_date, 'YYYY_MM_DD') as "Contract Signed Date",
      to_char(kick_off_date, 'YYYY_MM_DD') as "Kickoff Date",
      to_char(actual_live_date, 'YYYY_MM_DD') as "Actual Live Date",
      to_char(contract_renewal_date, 'YYYY_MM_DD') as "Contract Renewal Date",
      success_manager, account_executive,
      address, city, state, postal_code, crm "CRM (SF)", dms_snapshot "DMS (SF)", dealer_website_url "Website",
      to_char(last_activity_date, 'YYYY_MM_DD') as "Last Activity Date",
      to_char(last_contact_date, 'YYYY_MM_DD') as "Last Contact Date"
      
from fact.mode_sfdc_status
where status != 'Cancelled'
  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  
  and contract_signed_date is not NULL
  
order by status asc, dealer_name