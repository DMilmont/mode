options(repr.plot.width=13, repr.plot.height=5.5)


data_graph <- data %>%
  mutate(open_char = ifelse(open == 1, 'Open', 'Closed')) %>%
  group_by(open_char, day_week) %>%
  summarize(total_events_by_open_close = sum(exist)) %>%
  ungroup()
  

  
data_graph <- data_graph %>%
  left_join(totals) 
  
data_graph <- data_graph %>%
  mutate(perc_time_day = total_events_by_open_close / total_events)

# head(data_graph)
  
# Create Bar Graph
data_graph %>% 
  ggplot(aes(x = fct_rev(fct_relevel(day_week, c('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'))), 
             y = perc_time_day, fill = open_char)) + geom_col() + 
  theme(text = element_text(family="Gotham")) +
  theme_minimal() +
  scale_y_continuous(breaks = NULL) + 
  geom_text(aes(label = scales::percent(perc_time_day)), position = position_stack(vjust = 0.5), color = 'white') +
  labs(x = '', y = '', fill = '') + scale_fill_grey(end = .6) +
  
  coord_flip() 