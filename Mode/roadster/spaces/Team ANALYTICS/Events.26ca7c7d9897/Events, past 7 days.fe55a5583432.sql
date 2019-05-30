/* Find all User Events for a certain Dealership, for a certain timeframe. */

SELECT name as "Event", count(name) 
FROM public.user_events tblEvents
where timestamp >= (now()-interval'7 days') 
group by name
order by count DESC

;