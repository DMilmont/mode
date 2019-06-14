-- Returns first 100 rows from fact.f_prospect
with instore as (SELECT dpid,
  sum(case when is_in_store = true then 1 else 0 end) "In Store",
  sum(case when is_in_store = false then 1 else 0 end) "Online"
FROM fact.f_prospect 
where step_date_utc > now() - interval '1 month'
group by 1
order by dpid)

select dpid,
    ("In Store"::decimal / ("In Store" + "Online")) * 100 as "In Store Percent"

from instore

order by ("In Store"::decimal / ("In Store" + "Online")) * 100 asc

