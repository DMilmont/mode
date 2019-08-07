with top_performers as (
  SELECT dpid
  FROM dealer_partners dp 
  WHERE dpid in ('oxmoorcdjr','nissanoflexingtonpark','shockleyhonda','cochranhyundaimonroeville','beavertoninfiniti','crownhyundai','rickcasehondacleveland','grapponeford','waldorfhonda','grapponehonda','cochrannissanmonroeville','larrymillerhyundai','longotoyotaprosper','eurobethesdamercedes','rickcasekiasunrise','rickcasehyundaicleveland','oxmoormazda','cochrannissanwest','paragonhonda','oxmoorhyundai')
),



data as (
SELECT
DISTINCT
date_trunc('month' :: text, (po.cohort_date_utc) :: timestamp with time zone) AS month_year,
po.dpid,
po.is_in_store,
a.name,
a.category,
price,
'Accessory' "Type",
customer_email
FROM fact.f_prospect po
LEFT JOIN accessories a ON ((a.order_id = po.order_id))
WHERE dpid IN (SELECT * FROM top_performers)
AND price IS NOT NULL

UNION

SELECT
DISTINCT
date_trunc('month' :: text, (po.cohort_date_utc) :: timestamp with time zone) AS month_year,
po.dpid,
po.is_in_store,
sp.name,
sp.category,
price,
'Service Plan' "Type",
customer_email
FROM (fact.f_prospect po
JOIN plans sp ON ((sp.order_id = po.order_id)))
WHERE dpid IN (SELECT * FROM top_performers)
AND category IS NOT NULL
)

SELECT data.*, 
LEFT(((month_year + '1 day'::interval)::text), 10) mth_yr,
1 exists_now,
CASE WHEN is_in_store = true THEN 'In-Store' ELSE 'Online' END "Order Location"

FROM data
ORDER BY month_year desc