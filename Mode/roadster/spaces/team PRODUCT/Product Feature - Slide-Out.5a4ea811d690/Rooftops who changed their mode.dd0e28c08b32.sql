
 
 with instore as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '6 weeks'
  and item_type in ('OrderStarted', 'Order Submitted')
group by 1
)

, dpid_mode as (
  SELECT dp.dpid
         ,case when admin.properties ->> 'embedded_checkout_frame' = 'true' then 'Slide-Out' else 'Inline' end as "Slide-out"
         ,min(date::date)
         ,max(date::date)
         
  FROM dealer_partner_properties admin
  left join dealer_partners dp on dp.id = admin.dealer_partner_id
  left join instore on instore.dpid = dp.dpid
  WHERE admin.properties ->> 'status' = 'Live'
    --and date > date('10/12/18')
  GROUP BY 1,2)

, dpid_change as (
  Select dpid
  , count("Slide-out") as "Mode Count"
  from dpid_mode
  group by 1)
  
, dpids_who_changed as (
  select * from dpid_change
  where "Mode Count" > 1
  )
  
,change_dates as(  select dc.dpid
  ,max(case when dm."Slide-out" = 'Inline' then min end) as "Inline Start"
  ,max(case when dm."Slide-out" = 'Inline' then max  end) as "Inline End"
  ,max(case when dm."Slide-out" = 'Slide-Out' then min  end) as "Slide Out Start"
  ,max(case when dm."Slide-out" = 'Slide-Out' then max  end) as "Slide Out End"
  
  
  from dpids_who_changed dc 
  left join dpid_mode dm on dm.dpid = dc.dpid 
  group by 1
  )

, change_interpretation as ( select
    cd.dpid
    ,case when"Slide Out Start" > "Inline Start" then '---Inline to Slideout' else '>>>Slideout to Inline' end as "Switched from"
    ,case when "Slide Out Start" > "Inline Start" then "Slide Out Start" else "Inline Start" end as "Action Date"
    ,COALESCE(instore."In Store",0) as "Instore Orders Started, past 6w"
    ,COALESCE(instore."Online",0) as "Online Orders Started, past 6w"
    ,"Inline Start"
    ,"Inline End"
    ,"Slide Out Start"
    ,"Slide Out End"

    from change_dates cd
    left join instore on instore.dpid = cd.dpid 
    )
    
    
select * from change_interpretation
order by "Action Date" DESC

