-- Returns first 100 rows from public.all_leads_and_orders
SELECT * FROM public.all_leads_and_orders LIMIT 100;

-- Returns first 100 rows from public.leads
SELECT "Item Type", count("Item Type")
FROM public.all_leads_and_orders 
group by 1
order by "Item Type" asc
LIMIT 100;