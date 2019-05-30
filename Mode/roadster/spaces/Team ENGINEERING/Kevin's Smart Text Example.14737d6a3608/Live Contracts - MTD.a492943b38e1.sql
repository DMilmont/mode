With tStarts AS
  (SELECT date_trunc('month', effective_contract_date) "Month",
          COUNT(DISTINCT dpid) "New Contract Starts"
   FROM fact.salesforce_dealer_info

   GROUP BY 1
   ),
   
   
     tCancels AS
  (SELECT date_trunc('month', termination_date) "Month",
          COUNT(DISTINCT dpid) "Contract Terminations"
   FROM fact.salesforce_dealer_info
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