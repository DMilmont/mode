library(tidyverse)
data <-datasets[[3]] 

data <- data %>% select(-dpsk:-Primary.Make)

test <- data %>% t()
test <- as_tibble(test, rownames = 'Metrics')


colnames(test)[2:ncol(test)] <- test[1, 2:ncol(test)]

test <- test[2:nrow(test),]

data <- test

# Remove the weird perioed etc
data <- data %>% 
  mutate(Metrics = str_replace_all(Metrics, '[[:punct:]]', ' ')) %>% 
  mutate(Metrics = str_squish(Metrics))