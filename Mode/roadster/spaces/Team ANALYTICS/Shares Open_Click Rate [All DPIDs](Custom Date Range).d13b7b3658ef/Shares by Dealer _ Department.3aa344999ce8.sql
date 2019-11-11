with leads_submitted as  (
      select *
      from lead_submitted
      where timestamp >= '2019-01-09'
        and type='SharedExpressVehicle'
        and sent_at is not null
    ),
      agent as (
       select first_name||' ' ||substr(last_name,1,1) as agent_name
              ,a.*
       from agents a
       where  status='Active'
     ),
detail as  (   
 select ls.id
        ,(sent_at AT TIME ZONE 'UTC') AT TIME ZONE dd.timezone as date
        ,dpid
        ,primary_make
        ,department
        ,agent_name
        ,make
        ,model
        ,year
        ,vin
        ,deal_type
        ,case when clicked_at is not null then 'Share Clicked'
              when opened_at  is not null then 'Share Opened'
              when delivered_at is not null then 'Share Delivered'
              else 'Invalid Email' end as share_status
        ,case when sent_at is not null then 1 else 0 end as share_cnt     
        ,case when clicked_at is not null then 1 else 0 end as clicked_amt
        ,case when opened_at is not null then 1 else 0 end as opened_amt
 
 
 from leads_submitted ls
 left join public.dealer_partners dd
 on dd.id = ls.dealer_partner_id
  left join agent a on ls.agent_id=a.id)
  
  select dpid
        ,department
        ,sum(share_cnt) as "Shares"
        ,sum(opened_amt) as "Opens"
        ,sum(opened_amt)::decimal/sum(share_cnt) as "Open Rate"
        ,sum(clicked_amt) as "Clicks"
        ,sum(clicked_amt)::decimal/sum(share_cnt) as "Click Rate"
from detail
where date >= '{{ start_date }}' 
and date <= '{{ end_date }}'
group by 1,2
order by 3 desc


{% form %}

start_date:
  type: date
  default: {{ 'now' | date: '%s' | minus: 716400 | date: '%Y-%m-%d' }}
  description: Data available since Jan 15th

end_date: 
  type: date
  default: {{ 'now' | date: '%s' | minus: 111600 | date: '%Y-%m-%d' }}
  

{% endform %}
        