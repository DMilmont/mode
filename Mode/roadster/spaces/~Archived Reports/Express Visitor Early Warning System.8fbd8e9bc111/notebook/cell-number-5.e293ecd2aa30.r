library(scales)
my.percent<- function(x) {
  x = x*100
  x = paste0(x, ' %')
  return(x)
}
data_grouped <- data_grouped %>% mutate(`% Change` = my.percent(perc_difference))