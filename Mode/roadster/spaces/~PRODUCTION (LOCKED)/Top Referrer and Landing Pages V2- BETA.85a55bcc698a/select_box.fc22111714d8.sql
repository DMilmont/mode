with tab1 as (select distinct ((to_char(a.month_year, 'Month'::text) || ''::text) ||
          to_char(a.month_year, 'YYYY'::text))                                                          AS "Month & Year"
         ,date_part('month'::text, a.month_year)                                                       AS "Data Month"
        , date_part('year'::text, a.month_year)                                                        AS "Data Year"


FROM fact.traffic_landing_referral a
WHERE a.dpid='{{ dpid }}'
and a.month_year >= (date_trunc('day', now()) - INTERVAL '13 Months')
and a.month_year <= (date_trunc('day', now()) - INTERVAL '1 Months')
ORDER BY "Data Year", "Data Month"
)

SELECT 
"Month & Year"
FROM tab1