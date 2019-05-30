data_weekly %>% ggplot(aes(x = weeks_from_today, y = online_express_visitors, group = 1)) + 
geom_line() + facet_wrap(~name, ncol = 5, scales = 'free_y') + scale_y_continuous(name = 'Express Visitors') + 
scale_x_discrete(name = 'Weeks from Current Day') + theme_minimal()
