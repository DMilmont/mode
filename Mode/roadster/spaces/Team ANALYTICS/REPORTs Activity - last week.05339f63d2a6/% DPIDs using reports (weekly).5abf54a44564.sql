-- Sean's Scheduled run of 'Reports Activity Last Week' Query: % DPIDs using Reports

/* 
Active Dealers have at least 14 unique customers doing something in a given week (getting a share, taking an order step - anything.  Just 10 unique emails)
Active Dealers must have pulled at least 2 different reports in a given week 
*/


WITH 
    GA_wk AS ( 
    SELECT 
        gas.dpid,
        case when 
            ag.email ilike '%roadster%' and ag.email not in ('sean.kervin@roadster.com', 'louis.bohorquez@roadster.com', 'george.jacobs@roadster.com', 'daniel.saisho@roadster.com') 
            then 'Roadster' else 'Customer' end as user_type,
        date_trunc('week',(gap."timestamp" AT TIME ZONE 'UTC') AT TIME ZONE dp.timezone )::date "week", 
        count(1) as "report views"
   FROM ga2_pageviews gap
   left join public.ga2_sessions gas on gas.id = gap.ga2_session_id
   left join public.dealer_partners dp on gas.dpid = dp.dpid
   left join public.agents ag on gas.agent_dbid::integer = ag.user_dbid::integer
   left join fact.salesforce_dealer_info sf on sf.dpid = gas.dpid
      WHERE property = 'Dealer Admin'
      and gap.page_path :: text ~~* '%/reports/%' :: text
      and gas.agent_dbid ~ '^[0-9]*$' 
      and gap."timestamp" is not NULL
      and sf.status is not NULL
   GROUP BY  1,2,3)
   
   
   ,activity as (SELECT 
          date_trunc('week', cohort_date_utc - 1 )::date "week", -- Note: I pushed the days back so weeks are Sun>Sat... I did this because this report is sent out on Mondays and Sunday data is never ready in time.  
          dpid,
          count(distinct customer_email) "unique_users"
    FROM fact.f_prospect
    where cohort_date_utc > '03/04/2019'::date  -- date we started tracking report usage.
    GROUP BY 1,2
    )

  , GA_wk_activity as (SELECT
    GA_wk.dpid 
    , GA_wk.week 
    ,COALESCE(activity.unique_users,0) as "unique_users"
    , sum(case when user_type = 'Customer' then GA_wk."report views" else 0 end) as "Customer Report Views"
    , sum(case when user_type = 'Roadster' then GA_wk."report views" else 0 end) as "Roadster Report Views"
    from GA_wk
    left join activity on activity.week = GA_wk.week and activity.dpid = GA_wk.dpid
    group by 1,2,3
  )

, next_step as (select da.week, 
          count(distinct dpid) as active_dealers, 
          sum(case when "Customer Report Views" >=2 then 1 else 0 end ) as "reporting_dealers_min2",
          sum(case when "Roadster Report Views" >=2 then 1 else 0 end ) as  "reporting_roadsteremployees_min2"
      from GA_wk_activity da
      where da.unique_users >=6
      and da.week <= date_trunc('week',now()) -'7 days'::interval
      group by 1
      )
      
select week,active_dealers,"reporting_dealers_min2","reporting_roadsteremployees_min2",
  round(reporting_dealers_min2::decimal/active_dealers::decimal*100,1) as "% DPIDs with Customer viewing at least 2 Reports",
  round(reporting_roadsteremployees_min2::decimal/active_dealers::decimal*100,1) as "% DPIDs with Roadster Employee viewing at least 2 Reports",
  60 as "Goal"
from next_step