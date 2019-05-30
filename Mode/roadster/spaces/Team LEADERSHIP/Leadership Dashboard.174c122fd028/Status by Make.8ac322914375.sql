


WITH tab1 as (
  SELECT 
  
    CASE 
      WHEN dp.primary_make = 'All' then 'Multiple'
      else dp.primary_make
    end "primary_make", 
    
      CASE
           WHEN sf.status = 'Not Started' then '1) Not Started'
           WHEN sf.status = 'Stalled' then '2) Stalled'
           WHEN sf.status = 'In Dev' then '3) In Dev'
           WHEN sf.status = 'Live' then '4) Live'
           WHEN sf.status = 'Wind Down' then '5) Wind Down'
           WHEN sf.status = 'Cancelled' then '6) Cancelled'
           ELSE ''
       END "Ordered Status",
       -- This counts 'dealer_name' because DPID isn't always filled out for new contracts in SFDC:  Bug Fix by Sean 20198_04_12
       count(distinct dealer_name)
       
FROM fact.salesforce_dealer_info sf
left join public.dealer_partners dp on dp.dpid = sf.dpid 

where contract_signed_date is not NULL  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  Bug Fix by Sean 2019_04_12

GROUP BY 1,2
)


SELECT
  primary_make as "Primary Make",
  "Ordered Status" as "Status",
  CASE   
      when "Ordered Status" = '5) Wind Down' or "Ordered Status" = '6) Cancelled' then -count
      else COUNT
      end as "Dealers"
FROM tab1
WHERE "Ordered Status" <> ''
and primary_make is not NULL


