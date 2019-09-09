split_data <- list(
  hours$s_Sunday,
  hours$s_Monday,
  hours$s_Tuesday,
  hours$s_Wednesday,
  hours$s_Thursday,
  hours$s_Friday,
  hours$s_Saturday
)

# If any data NA - fill with default values which won't show up on the graph
fix_nas <- function(x) {
  if(x == 'NA  NA') {
    v = list(c('08  AM', '08  AM'))
  } else {
    v = x
  }
  return(v)
}
split_data <- map(split_data, fix_nas)

# Create Vec Data
create_vec_hours <- function(split_data) {
  begin <- split_data[[1]][[1]]
  begin <- strptime(begin, format = "%I %p")
  end <- split_data[[1]][[2]]
  end <- strptime(end, format = "%I %p")
  vec_hours <- seq(from = begin, to = end, by = 'hour')
  return(vec_hours)
}

# Add in Hourly data
dt_fix2 <- function( v ) {
  d <- format(v, format="%I:%M:%S %p")
  paste(substr(d, start = 1, stop = 2),'', substr(d, start = str_length(d)-1, stop = str_length(d)))
}

# Create List of Open Hours
open_hours <- map(split_data, function(x) dt_fix2(create_vec_hours(x)))
days <- c('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
data_open_hours <- bind_rows(map2(open_hours, days, function(x, y) tibble(day_week = y, hr_day = x)))
data_open_hours$perc_hour_byday <- 0     

# Filter the days of week without data or closed
data_open_hours <- data_open_hours %>% 
  group_by(day_week) %>%
  mutate(ind = row_number()) %>%
  group_by(day_week) %>%
  mutate(total_rows = sum(ind)) %>%
  ungroup() %>%
  filter(total_rows > 1) 
  

p <- data %>% 
  ggplot(aes(x = day_week, y = hr_day, fill = perc_hour_byday)) +
  geom_tile(color = 'white') +
  labs(x = '', y = '') + 
  guides(fill=FALSE) + 
  theme(text = element_text(family="Gotham")) +
  theme_minimal() + 
  scale_fill_gradient2(low = 'blue', mid = 'white', high = 'red') +
  geom_text(aes(label = char_perc_hour)) +
  geom_tile(data = data_open_hours, alpha=0, color = 'black', size = .5)
