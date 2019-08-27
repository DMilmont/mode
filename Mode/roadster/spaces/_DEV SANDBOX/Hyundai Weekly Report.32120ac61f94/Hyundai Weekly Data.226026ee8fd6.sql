WITH tab1 as (
SELECT DISTINCT *
FROM report_layer.hyundai_weekly_report
ORDER BY dpid, "Rolling 7 Day Window" DESC
),

dts as (
SELECT "Rolling 7 Day Window",
MAX(date) end_date,
MIN(date) start_date
FROM fact.d_rolling_seven_days
GROUP BY 1
)

SELECT
start_date, 
end_date, 
'Week of ' ||  (EXTRACT(MONTH FROM start_date)) || '/' || (EXTRACT(DAY FROM start_date))  || ' - ' || (EXTRACT(MONTH FROM end_date)) || '/' || (EXTRACT(DAY FROM end_date)) "Title",
tab1.*,
'Measures' "Measures"
FROM tab1
LEFT JOIN dts ON tab1."Rolling 7 Day Window" = dts."Rolling 7 Day Window"