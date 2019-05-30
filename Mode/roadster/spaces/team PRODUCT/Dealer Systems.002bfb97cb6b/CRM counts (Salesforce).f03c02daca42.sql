SELECT crm "CRM",
       COUNT(dpid) AS "Total Dealers"
       
FROM fact.salesforce_dealer_info

WHERE crm IS NOT NULL
      and status = 'Live'

GROUP BY crm 

order by COUNT(dpid) desc 
