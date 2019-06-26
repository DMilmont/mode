WITH 
    GA AS ( SELECT 
            
            gas.dpid,
            (gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone "dealertime",
            gap.property,
            gap.page_path,
            gap.distinct_id,
            1 count
   FROM ga2_pageviews gap
   left join public.ga2_sessions gas on gas.id = gap.ga2_session_id
   left join public.dealer_partners dp on gas.dpid = dp.dpid
   WHERE property = 'Dealer Admin')
   
   
  ,GA_mth AS (SELECT 
          dpid,
          date_trunc('month',dealertime)::date "month",
          btrim(regexp_replace(regexp_replace((GA.page_path) :: text, '\/reports\/' :: text, '' :: text), '-|_' :: text, ' ' :: text, 'g' :: text)) AS report,
          sum(count) AS views
   FROM GA
   WHERE ((GA.page_path) :: text ~~* '%/reports/%' :: text)
   GROUP BY 1,2,3)
   
   
      select * from GA_mth
   
   ,dealersreporting as (SELECT
        month,
        report,
        count(distinct dpid) "dealers_using"
    from GA_mth
    where daily_views > 1
    and month is not null
    group by 1,2
   )


   
   
   ,shares as (SELECT 
          date_trunc('month', cohort_date_utc)::date "month",
          dpid,
          count(distinct f_prospect.customer_email) "shares"
    FROM fact.f_prospect
    WHERE item_type = 'SharedExpressVehicle'
    AND source = 'Lead Type'
    GROUP BY 1,2
    )
  
  ,activedealers as(SELECT
        month,
        count(distinct dpid) "active_dealers"
      from shares 
      where shares > 1
      group by 1
        ) 
        
select ad.month,
      dr.report,
      ad.active_dealers,
      dr.dealers_using
      
from activedealers ad 
left join dealersreporting dr on dr.month = ad.month

  
