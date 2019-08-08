
WITH tab1 as (SELECT CASE
           WHEN status = 'Not Started' then '1) Not Started'
           WHEN status = 'Stalled' then '2) Stalled'
           WHEN status = 'In Dev' then '3) In Dev'
           WHEN status = 'Live' then '4) Live'
           WHEN status = 'Wind Down' then '5) Wind Down'
           WHEN status = 'Cancelled' then '6) Cancelled'
           ELSE ''
       END "Ordered Status",
       -- This counts 'dealer_name' because DPID isn't always filled out for new contracts in SFDC:  Bug Fix by Sean 20198_04_12
       count(distinct dealer_name)
FROM fact.salesforce_dealer_info
where contract_signed_date is not NULL  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  Bug Fix by Sean 2019_04_12

GROUP BY 1
)

SELECT*
FROM tab1
WHERE "Ordered Status" = '4) Live'