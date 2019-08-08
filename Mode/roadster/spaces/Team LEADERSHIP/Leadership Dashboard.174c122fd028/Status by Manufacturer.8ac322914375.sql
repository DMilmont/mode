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
      When dp.primary_make in ('Ford','Lincoln') then 'Ford Motors'
      When dp.primary_make in ('Buick','Cadillac','Chevrolet','GMC') then 'GM'
      When dp.primary_make in ('Acura','Honda') then 'Honda Motors'
      When dp.primary_make in ('Genesis','Hyundai','Kia') then 'Hyundai Group'
      When dp.primary_make in ('Mazda') then 'Mazda Corp'
      When dp.primary_make in ('Mercedes-Benz') then 'Daimler AG'
      When dp.primary_make in ('INFINITI','Mitsubishi','Nissan') then 'Renlt-Nissn-Mitsbi'
      When dp.primary_make in ('Subaru') then 'Subaru Corp'
      When dp.primary_make in ('Jaguar','Land Rover') then 'Tata Motors'
      When dp.primary_make in ('Lexus','Toyota') then 'Toyota Corp'
      When dp.primary_make in ('Audi','Porsche','Volkswagen') then 'VW Group'
      When dp.primary_make in ('Volvo') then 'Volvo/Lotus'
      else 'UNKNOWN:' || dp.primary_make
    end "primary_manufacturer", 
    

    
      CASE
           WHEN sf.status = 'Not Started' then '1) Not Started'
           --WHEN sf.status = 'Stalled' then '2) Stalled'
           WHEN sf.status = 'In Dev' then '2) In Dev'
           WHEN sf.status = 'Live' and sf.actual_live_date < (now() - '6 months'::interval) then '3) Live (<6m)'
           WHEN sf.status = 'Live' and sf.actual_live_date >= (now() - '6 months'::interval) then '4) Live (>6m)'
           --WHEN sf.status = 'Wind Down' then '5) Wind Down'
           WHEN sf.status = 'Cancelled' then '5) Cancelled'
           ELSE ''
       END "Ordered Status",
       -- This counts 'dealer_name' because DPID isn't always filled out for new contracts in SFDC:  Bug Fix by Sean 20198_04_12
       count(distinct dealer_name)
       
FROM fact.salesforce_dealer_info sf
left join public.dealer_partners dp on dp.dpid = sf.dpid 

where contract_signed_date is not NULL  -- there are 'test' accounts in SF... the best way we found to filter them out is that their contract signed dates were null.  Bug Fix by Sean 2019_04_12

GROUP BY 1,2,3
),

 MFGLost as (
select primary_manufacturer,
sum(case when "Ordered Status" = '5) Cancelled' then count else 0 end ) as "cancelled",
sum(case when "Ordered Status" = '4) Live (>6m)' then count else 0 end ) as "live",
sum(case when "Ordered Status" = '3) Live (<6m)' then count else 0 end ) as "recent"
from tab1
group by 1
),

 MakeLost as (
select primary_make,
sum(case when "Ordered Status" = '5) Cancelled' then count else 0 end ) as "cancelled",
sum(case when "Ordered Status" = '4) Live (>6m)' then count else 0 end ) as "live",
sum(case when "Ordered Status" = '3) Live (<6m)' then count else 0 end ) as "recent"
from tab1
group by 1
),

TotalLost as (
 select
sum(case when "Ordered Status" = '5) Cancelled' then count else 0 end ) as "cancelled",
sum(case when "Ordered Status" = '4) Live (>6m)' then count else 0 end ) as "live",
sum(case when "Ordered Status" = '3) Live (<6m)' then count else 0 end ) as "recent"
from tab1
),


calcStep as (
SELECT
  tab1.primary_manufacturer as "Primary Manufacturer",
  tab1.primary_make as "Primary Make",
  tab1."Ordered Status" as "Status",
  CASE   
      when tab1."Ordered Status" = '5) Cancelled' then -tab1.count
      else tab1.COUNT
  end as "Dealers",
  MFGLost.cancelled / (MFGLost.live + MFGLost.cancelled + MFGLost.recent) as "MFG Loss Rate",
  MakeLost.cancelled / (MakeLost.live + MakeLost.cancelled + MakeLost.recent) as "Make Loss Rate",
  (MFGLost.live - (MFGLost.live+MFGLost.cancelled)*(1- TotalLost.cancelled / (TotalLost.Live + TotalLost.cancelled))) / sqrt ((MFGLost.live+MFGLost.cancelled)*(1- TotalLost.cancelled / (TotalLost.Live + TotalLost.cancelled)))*10 as "MfgChiSq",
  (MakeLost.live - (MakeLost.live+MakeLost.cancelled)*(1- TotalLost.cancelled / (TotalLost.Live + TotalLost.cancelled))) / sqrt ((MakeLost.live+MakeLost.cancelled)*(1- TotalLost.cancelled / (TotalLost.Live + TotalLost.cancelled)))*10 as "MakeChiSq",
  totalLost.live "Total Live",
  totalLost.cancelled "Total Cancelled",
  totallost.cancelled / (totallost.live + totallost.cancelled + totallost.recent) as "Total Loss Rate"
  
FROM tab1
left join MFGLost on MFGLost.primary_manufacturer = tab1.primary_manufacturer
left join MakeLost on MakeLost.primary_make = tab1.primary_make
left join TotalLost on 1=1

WHERE "Ordered Status" <> ''
and tab1.primary_manufacturer is not NULL
and MFGLost.live + MFGLost.cancelled > 0
and MakeLost.live + MakeLost.cancelled >0
and MakeLost.live >0
and MfgLost.live > 0

order by 7 desc, 8 DESC
),

rank_create as (
  SELECT calcStep.*,
  DENSE_RANK() OVER(ORDER BY "MfgChiSq" desc) rank_t,
  DENSE_RANK() OVER(ORDER BY "MakeChiSq" desc) rank_v
  FROM calcStep 
)

select 
  to_char(rank_t,'00') || ' ' || "Primary Manufacturer" || ' (' || round("MFG Loss Rate"*100,0) || '% Lost)' as "Primary Manufacturer Display"
  ,to_char(rank_v,'00') || ' ' || "Primary Make" || ' (' || round("Make Loss Rate"*100,0) || '% Lost)' as "Primary Make Display"
  ,"Primary Manufacturer"
,"Primary Make"
,"Status"
,"Dealers"
,round("MFG Loss Rate",2) as "MFG Loss Rate"
,round("Make Loss Rate",2) as "Make Loss Rate"
,round("MfgChiSq",1) as "MfgChiSq"
,round("MakeChiSq",1) as "MakeChiSq"
,"Total Live"
,"Total Cancelled"
,round("Total Loss Rate",2) as "Total Loss Rate"
,"rank_t"
,"rank_v"
 from rank_create
order by 5 asc, 1 asc, 2 asc

