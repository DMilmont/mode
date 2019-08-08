


/*

-- Returns first 100 rows from roadster_salesforce.integration
with sfstat as (SELECT date_trunc('day',insert_timestamp)::date "date", dpid, status
FROM roadster_salesforce.integration
WHERE insert_timestamp in (SELECT max(insert_timestamp) FROM roadster_salesforce.integration) 
and contract_signed_date is not NULL 
OR date_trunc('day', insert_timestamp) = (SELECT date_trunc('day', max(insert_timestamp) - '31 days'::interval) FROM roadster_salesforce.integration) 
ORDER BY dpid)

select
  date,
  sum(case when status = 'Live' then 1 else 0 end) as "Live",
  sum(case when status = 'In Dev' then 1 else 0 end) as "In Dev"

from sfstat
group by 1
order by 1 DESC

*/




select 
  case when status in ('Pending Cancellation','Wind Down','Live') then 'Live'
  else 'In Dev' end status
  -- This counts 'dealer_name' because DPID isn't always filled out for new contracts in SFDC:  Bug Fix by Sean 20198_04_12
, count(distinct dealer_name)
from fact.mode_sfdc_status
where status in ('Pending Cancellation','Wind Down','Live','Not Started','In Dev')
and contract_signed_date is not NULL  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  Bug Fix by Sean 2019_04_12
group by 1
