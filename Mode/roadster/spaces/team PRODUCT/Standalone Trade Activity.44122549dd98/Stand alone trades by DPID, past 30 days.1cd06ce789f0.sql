
-- Returns first 100 rows from fact.f_prospect
SELECT dpid, 
count(dpid) "Total SA Trades",
sum(case when is_in_store = true then 1 else null end) "in-Store SA Trades",
sum(case when is_in_store = false then 1 else null end) "Online SA Trades"


FROM fact.f_prospect
where item_type = 'SATradeStarted'
and step_date_utc > date(now() - interval '1 month')
group by 1
order by count(dpid) DESC
