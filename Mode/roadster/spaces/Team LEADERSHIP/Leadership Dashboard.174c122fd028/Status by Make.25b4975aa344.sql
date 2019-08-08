WITH tab1 as (
  SELECT 
  
    CASE 
      WHEN dp.primary_make = 'All' then 'Multiple'
      else dp.primary_make 
    end "primary_make",
  
  
    CASE 
      WHEN dp.primary_make = 'All' then 'Multiple'
      When dp.primary_make in ('BMW','MINI','Rolls-Royce') then 'BMW Group'
      When dp.primary_make in ('Alfa Romeo','Chrysler','FIAT','Jeep','Maserati') then 'Fiat Chrysler'
      When dp.primary_make in ('Ford','Lincoln') then 'Ford Motor Company'
      When dp.primary_make in ('Buick','Cadillac','Chevrolet','GMC') then 'General Motors'
      When dp.primary_make in ('Acura','Honda') then 'Honda Motor Company'
      When dp.primary_make in ('Genesis','Hyundai','Kia') then 'Hyundai Motor Group'
      When dp.primary_make in ('Mazda') then 'Mazda Motor Corp'
      When dp.primary_make in ('Mercedes-Benz') then 'Daimler AG'
      When dp.primary_make in ('INFINITI','Mitsubishi','Nissan') then 'Renault-Nissan-Mitsubishi Alliance'
      When dp.primary_make in ('Subaru') then 'Subaru Corp'
      When dp.primary_make in ('Jaguar','Land Rover') then 'Tata Motors'
      When dp.primary_make in ('Lexus','Toyota') then 'Toyota Motor Corp'
      When dp.primary_make in ('Audi','Porsche','Volkswagen') then 'Volkswagen Group'
      When dp.primary_make in ('Volvo') then 'Volvo/Lotus'
      else 'UNKNOWN:' || dp.primary_make
    end "primary_manufacturer", 
    

    
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

GROUP BY 1,2,3
)


SELECT
  primary_make as "Primary Make",
  primary_manufacturer as "Primary Manufacturer",
  "Ordered Status" as "Status",
  CASE   
      when "Ordered Status" = '5) Wind Down' or "Ordered Status" = '6) Cancelled' then -count
      else COUNT
      end as "Dealers"
FROM tab1
WHERE "Ordered Status" <> ''
and primary_make is not NULL


