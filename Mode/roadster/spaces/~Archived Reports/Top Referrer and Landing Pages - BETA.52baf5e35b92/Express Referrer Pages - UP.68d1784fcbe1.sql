WITH last_month_visits as ( SELECT month_year
                          ,dpid
                          ,express_referrer
                          ,sum(express_visitor_count)
                          ,row_number() over(order by sum(express_visitor_count)  desc ) as rnk
                    FROM fact.traffic_landing_referral
                    WHERE dpid='{{ dpid }}'
                    and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                    and month_year > (date_trunc('day', now()) - INTERVAL '2 Months')
                    and is_in_store is false
                    GROUP BY 1,2,3
),

monthly_totals as ( SELECT month_year
                          ,SUM(express_visitor_count) as cnt
                    FROM fact.traffic_landing_referral
                        WHERE dpid='{{ dpid }}'
                          and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                          and month_year > (date_trunc('day', now()) - INTERVAL '6 Months')
                          and is_in_store is false
                    GROUP BY 1

),
detail as (select a.month_year
       ,a.dpid
       ,a.express_referrer
       ,b.rnk as rnk_page
       ,sum(express_visitor_count) as express_visitors
       ,sum(express_visitor_count)::decimal/mt.cnt as shares_express_visitors 
       ,sum(express_visitor_to_prospect_count)::decimal/sum(express_visitor_count) as conversion_prospect
       
       
     --  ,to_char(100.0*sum(express_visitor_to_prospect_count)::decimal/sum(express_visitor_count) ,'999D99%') as conversion_prospect
FROM fact.traffic_landing_referral a
inner join last_month_visits b on coalesce(a.express_referrer,'x')=coalesce(b.express_referrer,'x') and a.dpid=b.dpid and  b.rnk<=5
inner join monthly_totals mt on a.month_year=mt.month_year
group by 1,2,3,4,mt.cnt
),
unpivot as (select d.month_year
      ,d.dpid 
      ,case when d.express_referrer like 'https://www.%' then substring(d.express_referrer,13)
      else express_referrer end  express_referrer
      ,d.rnk_page
      ,e.*
from detail d
, LATERAL (
          VALUES
          ('Express Visitors', d.express_visitors)
          ,('Share of Express Visitors', d.shares_express_visitors)
          ,('Conversion to Prospect', d.conversion_prospect)
          ) e (calc_type, measure )
)
select month_year + 1 as month_year
      ,dpid

      ,COALESCE(express_referrer,'n/a') as express_referrer
      ,calc_type
      ,case when calc_type='Share of Express Visitors' then to_char(100.0 *measure ,'999D9%') 
            when calc_type='Conversion to Prospect' then to_char(100.0 *measure ,'999D9%') 
            else to_char(measure,'9,999') end as measure 
       ,measure as measure_dec       
      ,rnk_page      
      ,case when calc_type='Share of Express Visitors' then 2 
            when calc_type='Conversion to Prospect' then 3
            else 1 end as rnk_type       
      from unpivot
      