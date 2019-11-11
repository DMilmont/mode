WITH tab1 as (
SELECT *
FROM report_layer.general_hyundai_kpis_full_run1
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
dp.name,
sf_set.dealer_code,
'Week of ' ||  (EXTRACT(MONTH FROM start_date)) || '/' || (EXTRACT(DAY FROM start_date))  || ' - ' || (EXTRACT(MONTH FROM end_date)) || '/' || (EXTRACT(DAY FROM end_date)) "Title",
tab1.*,
'Measures' "Measures"
FROM tab1
LEFT JOIN dealer_partners dp ON tab1.dpid = dp.dpid
LEFT JOIN dts ON tab1."Rolling 7 Day Window" = dts."Rolling 7 Day Window"
LEFT JOIN fact.shopper_assurance hsa ON tab1.dpid = hsa.dpid
LEFT JOIN fact.mode_sfdc_status_set sf_set ON tab1.dpid = sf_set.dpid
WHERE tab1."Rolling 7 Day Window" = (SELECT max("Rolling 7 Day Window") FROM dts)
AND sf_set.dealer_code IS NOT NULL
AND dp.status = 'Live'