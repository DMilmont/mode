with date_dpid as (
        select DISTINCT date(c.date) as date,dp.id ,dp.dpid, dp.name, primary_make
        from fact.d_cal_date c
               cross join (
          select distinct dps.id,dps.dpid, dps.tableau_secret, dps.name, primary_make
          from dealer_partners dps
          where status in ( 'Live','Pending')
            AND dpid='{{ dpid }}'
        ) dp
             --  where dpid not like '%demo%')dp
        where c.date <= (date_trunc('day', now()) - interval '1 days')
        and c.date >= (date_trunc('day', now()) - interval '31 days')  
        group by 1, 2, 3, 4, 5
      ),
     agent as (
       select first_name||' ' ||substr(last_name,1,1) as agent_name
              ,first_name||' ' || last_name as agent_full_name
              ,a.*
       from agents a
       WHERE  status='Active'
       and email not like '%roadster%'
     ),
    leads_submitted as (
      select ls.*
            ,dd.dpid
            ,dd.name
      from lead_submitted ls
      inner join (select distinct id,dpid,name from date_dpid) dd on dd.id = ls.dealer_partner_id
      where timestamp >= (date_trunc('day', now()) - interval '91 days')
        and type='SharedExpressVehicle'
        and sent_at is not null
        and delivered_at is null
    ),
      detail as (SELECT a.agent_name as "Agent"
                    ,alo.customer_email as "E-mail"
                    ,date(sent_at) as "Date Sent"
               FROM leads_submitted ls
              left join agent a on ls.agent_id=a.id
              left join all_leads_and_orders alo on 'UC' || ls.user_contact_dbid = alo.id
              WHERE sent_at <= (date_trunc('day', now()) - interval '1 days')
                 and sent_at >= (date_trunc('day', now()) - interval '31 days')  
                  order by 1,3 asc
    )
    select * from detail
    
          

