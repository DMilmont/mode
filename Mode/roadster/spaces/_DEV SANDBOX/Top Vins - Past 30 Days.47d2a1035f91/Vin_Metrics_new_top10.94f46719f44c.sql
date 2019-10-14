with detail as (select * 
      ,'Summary' as title
      ,row_number () over (order by vdp_viewers desc) as rnk
from report_layer.vin_metrics
where  dpid='{{dpid}}'
and grade='New'
order by vdp_viewers desc
)
select *
      ,case when vin='2T3J1RFV3KC037908' then 'https://d2yvqewjuuy0k6.cloudfront.net/evox/color_320_001_png/13369/13369_cc320_001_3T3.png'
            when vin='4T1BZ1FB5KU032950' then 'https://d2yvqewjuuy0k6.cloudfront.net/evox/color_320_001_png/13637/13637_cc320_001_218.png'
      else 'https://image.shutterstock.com/image-vector/car-monochrome-icon-600w-755763799.jpg'
      end as img
from detail
where rnk<11
order by rnk
