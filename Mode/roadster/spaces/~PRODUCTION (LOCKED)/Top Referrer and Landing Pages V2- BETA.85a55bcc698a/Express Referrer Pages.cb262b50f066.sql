WITH last_month_visits as ( SELECT  dpid
                          ,replace(replace(express_referrer,'https://www.',''),'https://','') as express_referrer
                          ,sum(express_visitor_count)
                          ,row_number() over(order by sum(express_visitor_count)  desc ) as rnk
                    FROM fact.traffic_landing_referral
                    WHERE dpid='{{ dpid }}'
                   and month_year >= (date_trunc('day', now()) - INTERVAL '13 Months')
                    and month_year <=  (date_trunc('day', now()) - INTERVAL '1 Months')
                    and is_in_store is false
                    GROUP BY 1,2
),

monthly_totals as ( SELECT month_year
                          ,SUM(express_visitor_count) as cnt
                    FROM fact.traffic_landing_referral
                        WHERE dpid='{{ dpid }}'
                              and month_year >= (date_trunc('day', now()) - INTERVAL '13 Months')
                              and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                              and is_in_store is false
                    GROUP BY 1

),
overlay_dealers as ( select mt.month_year
                            ,mt.cnt
                    from monthly_totals mt 
                    left join (select avg(cnt) as avg_mt from monthly_totals where month_year>='2019-01-01') amt on 1=1
                    where case when month_year>='2018-09-01' and month_year<='2018-11-02' and mt.cnt>=amt.avg_mt*8 then 1
                                when month_year='2018-12-01'  and mt.cnt>=amt.avg_mt*3 then 1 else 0 end =1
),
detail as (select  a.month_year
            ,((to_char(a.month_year, 'Month'::text) || ''::text) ||
          to_char(a.month_year, 'YYYY'::text))                                                          AS "Month & Year"
         ,date_part('month'::text, a.month_year)                                                       AS "Data Month"
        , date_part('year'::text, a.month_year)                                                        AS "Data Year"
       ,a.dpid
       ,case when b.rnk<=10 then LEFT(replace(replace(a.express_referrer,'https://www.',''),'https://',''),35)  else 'other' end as express_referrer
       ,case when od.month_year is null then sum(express_visitor_count) when od.month_year='2018-12-01' then round(sum(express_visitor_count) /4)   else round(sum(express_visitor_count) /10) end as express_visitors
       ,case when od.month_year is null then mt.cnt when od.month_year='2018-12-01' then round(mt.cnt/4)  else round(mt.cnt/10)end as shares_express_visitors 
     ,case when od.month_year is null then sum(express_visitor_to_prospect_count) when od.month_year='2018-12-01' then round(sum(express_visitor_to_prospect_count)/4)  else round(sum(express_visitor_to_prospect_count)/10) end  as conversion_visitors
       
       

FROM fact.traffic_landing_referral a
left join last_month_visits b on coalesce(replace(replace(a.express_referrer,'https://www.',''),'https://','') ,'n')=coalesce(b.express_referrer,'x') and a.dpid=b.dpid 
inner join monthly_totals mt on a.month_year=mt.month_year
left join overlay_dealers od on a.month_year=od.month_year 
WHERE a.dpid='{{ dpid }}'
and a.month_year >= (date_trunc('day', now()) - INTERVAL '13 Months')
and a.month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
 and is_in_store is false
group by 1,2,3,4,5,6,od.month_year,mt.cnt 
 having  case when od.month_year is null then sum(express_visitor_count) when od.month_year='2018-12-01' then round(sum(express_visitor_count) /4)   else round(sum(express_visitor_count) /10) end>0
)

select * from detail
