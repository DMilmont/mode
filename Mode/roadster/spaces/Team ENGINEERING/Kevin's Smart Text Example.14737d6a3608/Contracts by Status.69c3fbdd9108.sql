WITH tab1 as (SELECT CASE
           WHEN status = 'Not Started' then '1) Not Started'
           WHEN status = 'Stalled' then '2) Stalled'
           WHEN status = 'In Dev' then '3) In Dev'
           WHEN status = 'Live' then '4) Live'
           WHEN status = 'Wind Down' then '5) Wind Down'
           WHEN status = 'Cancelled' then '6) Cancelled'
           ELSE ''
       END "Ordered Status",
       count(distinct dpid)
FROM fact.salesforce_dealer_info
GROUP BY 1
)

SELECT*
FROM tab1
WHERE "Ordered Status" <> ''