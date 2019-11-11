
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

)

SELECT
order_type,
CASE WHEN status IS NULL THEN 'Open' ELSE status END status,
date_trunc('month', timing at TIME ZONE 'UTC')::date month_yr,
COUNT(*)
FROM base_data
WHERE created_at >= '2019-01-01'
GROUP BY 1,2,3
ORDER BY 1,2,3