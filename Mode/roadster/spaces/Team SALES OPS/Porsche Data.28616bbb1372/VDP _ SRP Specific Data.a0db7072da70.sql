SELECT *
FROM report_layer.porsche_customer_journey('2019-09-01'::date, date_trunc('day', NOW())::date)