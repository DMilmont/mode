WITH Overlay_Dealers as (select distinct dpid, properties->>'embedded_checkout_frame' 
                      from dealer_partner_properties
                      left join dealer_partners dp on dealer_partner_properties.dealer_partner_id = dp.id
                      where  properties->>'embedded_checkout_frame' ='true'
                      and date ='2018-08-01'
                      and status='Live'
),

demo_dealers as ( select distinct dpid
                  from dealer_partners 
                  where status = 'Live'
                       and dpid like '%demo%'
),

dealer_visits as ( SELECT month_year
                          ,dpid
                          ,false as is_in_store
                          ,distinctid_count as dealer_visits
                    FROM fact.agg_monthly_traffic
                    WHERE dpid='{{ dpid }}'
                    and month_year >= (date_trunc('day', now()) - INTERVAL '7 Months')
                    and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                    AND item_type='Dealer Visitor'
),
express_visits as (SELECT month_year
                          ,dpid
                          ,dpsk
                          ,is_in_store
                          ,sum(distinctid_count) as express_visits
                    FROM fact.agg_monthly_traffic
                    WHERE dpid='{{ dpid }}'
                    and month_year >= (date_trunc('day', now()) - INTERVAL '7 Months')
                    and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                    AND item_type='Express Visitor'
                    and is_in_store is not null 
                    GROUP BY 1,2,3,4
                    ),
express_visits_SRP as (SELECT month_year
                          ,dpid
                          ,is_in_store
                          ,sum(distinctid_count) as express_visits_SRP
                    FROM fact.agg_monthly_traffic
                    WHERE dpid='{{ dpid }}'
                    and month_year >= (date_trunc('day', now()) - INTERVAL '7 Months')
                    and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                    AND item_type='Express SRP Visitor'
                    and is_in_store is not null 
                    GROUP BY 1,2,3
) ,
express_visits_VDP as (SELECT month_year
                          ,dpid
                          ,is_in_store
                          ,sum(distinctid_count) as express_visits_VDP
                    FROM fact.agg_monthly_traffic
                    WHERE dpid='{{ dpid }}'
                    and month_year >= (date_trunc('day', now()) - INTERVAL '7 Months')
                    and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                    AND item_type='Express VDP Visitor'
                    and is_in_store is not null 
                    GROUP BY 1,2,3
) ,
online_prospects as ( select month_year
                            ,dpid
                            ,is_in_store
                            ,sum(email_count) as prospect_count
                      FROM fact.agg_monthly_prospects
                      WHERE dpid='{{ dpid }}'
                       and month_year >= (date_trunc('day', now()) - INTERVAL '7 Months')
                       and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                      AND item_type='All'
                      AND grade='All'
                      AND source='Lead Type'
                      and is_prospect_close_sale is null --- ********* WHAT DOES THIS MEAN***************
                      and is_in_store is not null
                      group by 1,2,3

),

price_unlock as (select dpid
                        ,month_year
                        ,case when price_mode LIKE '%nolock%' then 'Prices Unlocked'
                        when price_mode LIKE '%pervin%' then 'Verified Unlock'
                        when price_mode LIKE '%pertrim%' then 'Verified Unlock'
                        when price_mode LIKE '%lock%' then 'Unlock Lead Form'
                        when price_mode LIKE '%invoicelock%' then 'Unlock Lead Form'
                        when price_mode LIKE '%msrplock%' then 'Unlock Lead Form'
                        else price_mode end as price_unlock
                  from fact.d_dealer_status_month
                  where dpid='{{ dpid }}'
                  and month_year >= (date_trunc('day', now()) - INTERVAL '7 Months')
                  and month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
                  )


SELECT ev.month_year + 1  as "Month Year"
      ,pu.price_unlock as "Price Unlock"
      ,case when ev.is_in_store is true then 'In-Store' else 'Online' end as "In Store"
      ,coalesce(dv.dealer_visits,0) as dealer_visitors
      ,ev.express_visits as express_visitors
      ,case when dv.dealer_visits = 0 then 0 else ev.express_visits::decimal/dv.dealer_visits end as "Online Express Ratio"
      ,evs.express_visits_SRP as "Express SRP Visitors"
      ,evv.express_visits_VDP as "Express VDP Visitors"
      ,op.prospect_count as prospect_count
      ,case when ev.express_visits =0 then 0 else op.prospect_count::decimal/ev.express_visits end as "Conversion to Online Prospect"
      ,'Summary' as title
FROM express_visits ev
left join price_unlock pu on ev.month_year=pu.month_year
left join dealer_visits dv on ev.month_year=dv.month_year and ev.is_in_store =dv.is_in_store
left join express_visits_SRP evs on ev.month_year=evs.month_year and ev.is_in_store=evs.is_in_store
left join express_visits_VDP evv on ev.month_year=evv.month_year and ev.is_in_store=evv.is_in_store
left join online_prospects op on ev.month_year=op.month_year and ev.is_in_store=op.is_in_store

