SELECT
dpid,
month_year,
CASE WHEN in_store = true THEN 'In-Store' ELSE 'Online' END "in_store",
"Button Clicked",
'Measures' "Measures",
name,
SUM(1)
FROM
(
    SELECT DISTINCT
    dp.dpid,
    date_trunc('month', timestamp) month_year,
    ue.in_store,
    user_id,
    ue.name,
    ue.payload ->> 'title' "Button Clicked"
    FROM user_events ue
    LEFT JOIN dealer_partners dp
    ON ue.dealer_partner_id = dp.id
    WHERE timestamp >= '2019-09-01'
    AND primary_make = 'Porsche'
    AND ue.name IN ('Service Plan Added', 'Service Plan Removed')
    AND dp.dpid IN (
      SELECT dpid
      FROM dealer_partners dp
      WHERE primary_make = 'Porsche'
      AND dpid != 'loeberporsche'
      )
) t
GROUP BY 1,2,3,4,5,6