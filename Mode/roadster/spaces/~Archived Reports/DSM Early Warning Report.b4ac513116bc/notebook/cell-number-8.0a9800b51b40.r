library(ggplot2)
library(ggthemes)
names_dealers <- data_grouped$name

data_weekly <- data %>% filter(name %in% names_dealers)
glimpse(data_weekly)