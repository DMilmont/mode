data_weekly <- data_weekly %>% mutate(max_week = max(week_no))

data_weekly <- data_weekly %>% mutate(weeks_from_today = week_no - max_week) %>% mutate(weeks_from_today = paste0(weeks_from_today, ' weeks'))

library(forcats)
data_weekly <- data_weekly %>% mutate(weeks_from_today = fct_reorder(weeks_from_today, week_no))

glimpse(data_weekly)

library(plotly)