# Check Data Out
library(tidyverse)
summed_data <- datasets[[4]] %>% 
  summarize(unique_users = sum(ct_unique_users_total, na.rm = T),
            sell_your_car = sum(ct_unique_users_sell_your_car, na.rm = T),
            trade_in_wizard_see = sum(ct_unique_users_trade_in_wizard_seen, na.rm = T), 
            standalone_trades_completed = sum(ct_standalone_trades_completed, na.rm = T))
