WITH basic_data as (
    SELECT dpid,
           name,
           timestamp,
           recommend,
           CASE WHEN recommend > 8 THEN 1 ELSE 0 END                   "Promoter",
           CASE WHEN recommend < 7 THEN 1 ELSE 0 END                   "Detractor",
           CASE WHEN recommend > 6 AND recommend < 9 THEN 1 ELSE 0 END "Passive",
           1                                                           Total
    FROM rating
           LEFT JOIN dealer_partners dp ON rating.dealer_partner_id = dp.id
    WHERE recommend IS NOT NULL
)

SELECT
name,
SUM(TOTAL) "CT Reponses",
ROUND(SUM("Promoter")::decimal / SUM(total), 2) "% Promoter",
ROUND(SUM("Detractor")::decimal / SUM(total), 2) "% Detractor",
100*ROUND((SUM("Promoter")::decimal / SUM(total)) - (SUM("Detractor")::decimal / SUM(total)), 2) "Net Promoter Score"
FROM basic_data
WHERE timestamp >= '{{ start_date }}' and timestamp <= '{{ end_date }}'
GROUP BY name
ORDER BY ROUND((SUM("Promoter")::decimal / SUM(total)) - (SUM("Detractor")::decimal / SUM(total)), 2) * SQRT(SUM(TOTAL)) DESC