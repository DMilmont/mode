# Change the data
service_plan_specific <- service_plan_specific %>%
  spread(key = Button.Clicked, value = sum)