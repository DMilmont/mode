# Rename the Data rows
trade_data <- trade_in_information %>%
  mutate(Trade.In.Status = ifelse(Trade.In.Status == '', 'blank', Trade.In.Status)) %>%
  mutate(trade_in_status = case_when(
    Trade.In.Status == 'accepted' ~ 'Accepted Trade-In',
    Trade.In.Status == 'declined' ~ 'Declined Trade-In',
    Trade.In.Status == 'notrade' ~ 'Customer Clicks Skip Trade-In', 
    Trade.In.Status == 'received' ~ 'Trade-In Offer Received by Customer',
    Trade.In.Status == 'requested' ~ 'Dealer Received Full Trade-In Information',
    Trade.In.Status == 'Submitted' ~ 'Customer Submits Incomplete Trade-In Information',
    Trade.In.Status == 'updated' ~ 'Trade-In Offer Updated by Agent',
    TRUE ~ 'Not Started Trade-In Yet / Skipped'
    )
  )  %>%
  mutate(Trade.In.Status = fct_relevel(Trade.In.Status, 
      c('Submitted', 'requested', 'received', 'accepted', 'declined', 'updated', 'notrade', 'blank'))
      ) %>%
  mutate(created_at = ymd_hms(created_at))
  
# Filter for just Express Trade Dealers
trade_data <- trade_data %>%
  filter(Dealer.Trade.Type == 'Express Trade Dealer')
  