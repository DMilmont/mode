# Convert Numbers to Labels
data <- datasets[[1]]

data <- data %>% 
  mutate(day_week = case_when(
    `Day.of.Week` == 0 ~ 'Sunday',
    `Day.of.Week` == 1 ~ 'Monday',
    `Day.of.Week` == 2 ~ 'Tuesday',
    `Day.of.Week` == 3 ~ 'Wednesday',
    `Day.of.Week` == 4 ~ 'Thursday',
    `Day.of.Week` == 5 ~ 'Friday',
    `Day.of.Week` == 6 ~ 'Saturday'
  )) %>% 
  mutate(day_week = fct_reorder(day_week, `Day.of.Week`)) %>% 
  mutate(hour = paste(Hour.of.Day, ':00:00', sep='')) %>% 
  mutate(hour_day = format(strptime(hour, format='%H:%M:%S'), '%I:%M:%S %p')) %>% 
  mutate(hour_day = fct_reorder(hour_day, `Hour.of.Day`,.desc = T))

# Percent by Day of Week
totals <- data %>% 
  group_by(day_week) %>% 
  summarize(total_events = sum(exist))

data <- data %>% 
  left_join(totals)

data <- data %>% 
  mutate(perc_hour_byday = exist / total_events) %>% 
  mutate(char_perc_hour = scales::percent(perc_hour_byday))
  
data <- data %>% 
  mutate(hr_day = paste(
    substr(hour_day, start = 1, stop = 2), '', substr(hour_day, start = str_length(hour_day)-1, stop = str_length(hour_day))
    )) %>%
    mutate(hr_day = fct_reorder(hr_day, Hour.of.Day, .desc = T))
