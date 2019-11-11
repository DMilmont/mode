table <- trade_data %>%
  group_by(Trade.In.Status, in_store) %>%
  tally() %>%
  ungroup() %>%
  spread(in_store, n) %>%
  mutate(total = false + true) %>%
  gather(in_store, n, false, true, total)

knitr::kable(table)

#table(trade_data$Trade.In.Status, trade_data$in_store, useNA = 'ifany')
#knitr::kable(trade_data) %>% knitr::kable_styling()
