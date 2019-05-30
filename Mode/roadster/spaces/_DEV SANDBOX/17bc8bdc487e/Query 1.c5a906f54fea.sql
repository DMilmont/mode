

-- Returns first 100 rows from public.lead_submitted
SELECT to_char(clicked_at, 'YYYY_MM_DD') "Clicked On", type, count(type)

FROM public.lead_submitted
where clicked_at is not NULL
and clicked_at > date '2019/01/01'
group by 1,2

