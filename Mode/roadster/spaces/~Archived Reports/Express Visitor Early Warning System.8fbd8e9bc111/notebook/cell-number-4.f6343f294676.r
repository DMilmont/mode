glimpse(data_grouped)
data_grouped <- data_grouped %>% mutate(perc_difference = round((`Current Week` - `Previous 7-8 Weeks`) / `Previous 7-8 Weeks`, 2))
data_grouped <- data_grouped %>% arrange(perc_difference, desc(`Previous 7-8 Weeks`))
data_grouped <- data_grouped %>% mutate(`Previous 7-8 Weeks` = round(`Previous 7-8 Weeks`, 2))