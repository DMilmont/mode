with date_dpid as (
        select DISTINCT date(c.date) as date,dp.id ,dp.dpid, dp.name, primary_make,timezone
        from fact.d_cal_date c
               cross join (
          select distinct dps.id,dps.dpid, dps.tableau_secret, dps.name, primary_make,timezone
          from dealer_partners dps
          where status = 'Live'
            AND dpid='{{ dpid }}'
        ) dp
             --  where dpid not like '%demo%')dp
        where c.date <= (date_trunc('day', now()) - interval '1 days')
        and c.date >= (date_trunc('day', now()) - interval '31 days')  
        group by 1, 2, 3, 4, 5,6
      ),
     agent as (
       select first_name||' ' ||substr(last_name,1,1) as agent_name
              ,first_name||' ' || last_name as agent_full_name
              ,a.*
       from agents a
       WHERE    status='Active'
       and email not like '%roadster%'
     ),
    leads_submitted as (
      select *
      from lead_submitted
      where timestamp >= (date_trunc('day', now()) - interval '91 days')
        and type='SharedExpressVehicle'
        and sent_at is not null
    )
   SELECT dd.date
                    , dd.dpid
                    , dd.name
                    ,a.agent_name
                    ,a.email
                    ,a.agent_full_name
                    ,a.job_title
                    ,ls.agent_id
                    , ls.id
                    ,ls.crm_record_id
                    ,ls.vin
                    ,ls.make
                    ,ls.model
                    ,ls.year
                    ,ls.grade
                    ,ls.deal_type
                    ,ls.referral_coupon
                    ,ls.details
                    ,ls.order_id
                    ,case when ls.delivered_at is not  null or ls.clicked_at is not  null or ls.opened_at is not null
                          then 1 else 0 end as Deliver_Check
                    ,case when ls.clicked_at is not  null or ls.opened_at is not null
                          then 1 else 0 end as Open_Check
                   ,case when ls.clicked_at is not null
                          then 1 else 0 end as Click_Check
               FROM date_dpid dd
                      left join leads_submitted ls on dd.id = ls.dealer_partner_id and date(dd.date) = date(ls.sent_at)
                      left join agent a on ls.agent_id=a.id
              where a.agent_name is not null   

    