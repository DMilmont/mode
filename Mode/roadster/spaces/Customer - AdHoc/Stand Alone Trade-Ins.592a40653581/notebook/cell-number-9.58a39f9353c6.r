# How many customer received an offer when they requested a trade-in? 
table_vals <- trade_data %>%
  group_by(Trade.In.Status, in_store) %>%
  tally() %>%
  ungroup() %>%
  spread(in_store, n) %>%
  mutate(total = false + true) %>%
  gather(in_store, n, false, true, total) %>%
  ungroup() %>%
  spread(Trade.In.Status, n) %>%
  mutate(in_store_flag = case_when(in_store == 'true' ~ 'In-Store', in_store == 'false' ~ 'Online', in_store == 'total' ~ 'Total')) %>%
  select(in_store_flag, everything())
  
  table_vals <- table_vals %>%
    mutate(rank = case_when(in_store == 'true' ~ 1, in_store == 'false' ~ 2, in_store == 'total' ~ 3)) %>%
    arrange(rank) %>%
    mutate(received_offer = (received + accepted + declined + updated) /  (requested + received + accepted + declined + updated)) %>%
    mutate(offers_received = (received + accepted + declined + updated),
           accepted_offer = accepted / (received + accepted + declined + updated)
          )
    
  table_vals