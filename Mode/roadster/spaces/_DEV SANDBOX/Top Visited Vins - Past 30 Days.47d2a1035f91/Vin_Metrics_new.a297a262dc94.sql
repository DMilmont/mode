select vin
      ,year
      ,make
      ,model
      ,trim
      ,body
      ,msrp
      ,invoce_price
      ,price
      ,exterior_color_name
      ,case when exterior_color_name like '%White%' or exterior_color_rgb='FFFFFF' then '<div style=''width: 150px; height: 20px; background-color: #' ||exterior_color_rgb||';''>'|| exterior_color_name ||'</div>'--'<font color="#' ||exterior_color_rgb||'">⬤</font>' as exterior_color_rgb
              else '<div style=''width: 150px; height: 20px; color: whitesmoke; background-color: #' ||exterior_color_rgb||';''>'|| exterior_color_name ||'</div>' end as exterior_color_rgb
      ,sum(case when type='New Vehicle Viewed' then 1 else 0 end ) as vdp_views
      ,count( distinct case when type='New Vehicle Viewed' then distinct_id else null end ) as unique_viewers
      ,count( distinct case when type='New Vehicle Viewed' and prospect_flag='Prospect' then distinct_id else null end ) as unique_prospects
       ,sum(case when type<>'New Vehicle Viewed' then 1 else 0 end ) as buy_activity_cnt
      ,count( distinct case when type<>'New Vehicle Viewed' then distinct_id else null end ) as buy_activity_users
from fact.vin_activity
where  dpid='{{dpid}}'
and timestamp_local>=(CURRENT_DATE - '31 days' :: interval)
and grade='new'
group by 1,2,3,4,5,6,7,8,9,10,11,exterior_color_rgb

