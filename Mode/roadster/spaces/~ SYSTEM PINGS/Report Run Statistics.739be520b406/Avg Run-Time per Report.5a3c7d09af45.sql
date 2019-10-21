SELECT s.*, 
EXTRACT(month from s.started) "Month Started",
EXTRACT(day from s.started) "Day Started",
EXTRACT(hour FROM s.started) "Hour Started",
EXTRACT(minute from s.started) "Minute Started"
FROM report_layer.mode_report_table_statistics s