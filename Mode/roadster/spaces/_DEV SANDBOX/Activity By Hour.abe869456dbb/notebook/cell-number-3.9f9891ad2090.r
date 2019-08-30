# Convert Numbers to Labels
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

# Heat Map of Last 3 Months (Total)
# data %>% 
#   ggplot(aes(y = hour_day, x = day_week, fill = exist)) + 
#   geom_tile() + 
#   theme_classic() +
#   labs(x = '', y='', title = 'Peak Times') 

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

ax <- list(
  title = "",
  zeroline = FALSE,
  showline = FALSE,
  showticklabels = TRUE,
  showgrid = FALSE
)

plot_ly(data, x = ~day_week, y = ~hr_day, z = ~perc_hour_byday) %>%
  layout(autosize = F, width = 1150, height = 650, showlegend = FALSE) %>% 
  add_heatmap(xgap = 2, ygap = 2, zhoverformat = ".1%") %>%
  layout(xaxis = ax, yaxis = ax, legend = list(x = 0.1, y = 0.9))

