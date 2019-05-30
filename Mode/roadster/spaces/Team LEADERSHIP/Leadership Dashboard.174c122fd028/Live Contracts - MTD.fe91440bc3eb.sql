
With tStarts AS
  (SELECT date_trunc('month', effective_contract_date) "Month",
          -- This counts 'dealer_name' because DPID isn't always filled out for new contracts in SFDC:  Bug Fix by Sean 20198_04_12
          COUNT(DISTINCT dealer_name) "New Contract Starts"
   FROM fact.salesforce_dealer_info
   where contract_signed_date is not NULL  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  Bug Fix by Sean 2019_04_12

   GROUP BY 1
   ),
   
   
     tCancels AS
  (SELECT date_trunc('month', termination_date) "Month",
          -- This counts 'dealer_name' because DPID isn't always filled out for new contracts in SFDC:  Bug Fix by Sean 20198_04_12
          COUNT(DISTINCT dealer_name) "Contract Terminations"
   FROM fact.salesforce_dealer_info
   where contract_signed_date is not NULL  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  Bug Fix by Sean 2019_04_12

   GROUP BY 1)
SELECT tStarts."Month",
       "New Contract Starts",
       -"Contract Terminations" as "Contract Terminations",
       "New Contract Starts" - "Contract Terminations" as "Net New Contracts"
FROM tStarts
left join tCancels
  ON tStarts."Month" = tCancels."Month"
WHERE tStarts."Month" > now() - INTERVAL'18 months'
ORDER BY "Month"