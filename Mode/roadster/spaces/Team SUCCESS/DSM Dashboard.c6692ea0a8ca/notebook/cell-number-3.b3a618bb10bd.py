data_grouped <- data_grouped %>% ungroup() %>% spread(current_week, express_visitors, fill = 0)
