
WITH base_data as (

Select
o.id, o.order_dbid, o.created_at, o.in_store, o.order_type,
order_status.*,
CASE WHEN status_ts IS NOT NULL then status_ts ELSE created_at END timing
from orders o
LEFT JOIN (
  SELECT order_id, is_final, 'Completed' status, timestamp status_ts
  FROM order_completed oc
  UNION
  SELECT order_id, is_final, 'Canceled' status, timestamp status_ts
  FROM order_cancelled oca
) order_status ON o.id = order_status.order_id
Where order_type = 'StandaloneTrade'

)

,base_data2 as (
SELECT
CASE WHEN status IS NULL THEN 'Open' ELSE status END status,
date_trunc('month', timing at TIME ZONE 'UTC') month_yr,
COUNT(*) ct_trade_in
FROM base_data
WHERE created_at >= '2019-01-01'
GROUP BY 1,2
)

,grouped_data as (
SELECT month_yr, SUM(ct_trade_in) "Total"
FROM base_data2
GROUP BY month_yr
)

SELECT 
status, 
base_data2.month_yr, 
ct_trade_in,
ct_trade_in::decimal / "Total" "Percentage of Trades"
FROM base_data2
LEFT JOIN grouped_data gd ON base_data2.month_yr = gd.month_yr
