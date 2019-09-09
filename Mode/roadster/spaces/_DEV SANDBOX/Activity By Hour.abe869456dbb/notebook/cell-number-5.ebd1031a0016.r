data_open_hours <- data_open_hours %>%
  mutate(open = 1)
  
data <- left_join(data, data_open_hours,  by = c("day_week","hr_day")) %>%
  mutate(open = ifelse(is.na(open), 0, open))