select type
from fact.mode_agg_daily_traffic_and_prospects
where date between current_date-8 and current_date-1
group by 1
