
SELECT 
  dpid
  ,sum(case when recommend >=9 then 1 else 0 end) as "promoters"
  ,sum(case when recommend <=6 then 1 else 0 end) as "detractors"
  ,sum(case when recommend >=7 and recommend <= 8 then 1 else 0 end) as "passives"
  ,sum(case when recommend is not null then 1 else 0 end) as "total"
  ,avg(overall) as "csi"

FROM public.rating pr
left join public.dealer_partners dp on dp.id = pr.dealer_partner_id

where timestamp > now() - '91 days'::interval
and recommend is not NULL
group by 1
