hourly <- datasets[[3]]


# Fixing the HOURS data
dt_fix <- function(x) {
  d <- format(strptime(x, "%I:%M%p"), format="%I:%M:%S %p")
  return(paste(substr(d, start = 1, stop = 2), '', substr(d, start = str_length(d)-1, stop = str_length(d))))
  }

hours <- hourly %>% 
  mutate(Monday = str_trim(str_extract(Monday, '\\d+:.*')),
         Tuesday = str_trim(str_extract(Tuesday,  '\\d+:.*')),
         Wednesday = str_trim(str_extract(Wednesday, '\\d+:.*')),
         Thursday = str_trim(str_extract(Thursday, '\\d+:.*')),
         Friday = str_trim(str_extract(Friday, '\\d+:.*')),
         Saturday = str_trim(str_extract(Saturday, '\\d+:.*')),
         Sunday = str_trim(str_extract(Sunday, '\\d+:.*'))
  ) %>% 
  mutate(s_Monday = str_split(Monday, '-'),
         s_Tuesday = str_split(Tuesday, '-'),
         s_Wednesday = str_split(Wednesday, '-'),
         s_Thursday = str_split(Thursday, '-'),
         s_Friday = str_split(Friday, '-'),
         s_Saturday = str_split(Saturday, '-'),
         s_Sunday = str_split(Sunday, '-')
  ) %>% 
  mutate(s_Monday = map(s_Monday, dt_fix),
         s_Tuesday = map(s_Tuesday, dt_fix),
         s_Wednesday = map(s_Wednesday, dt_fix),
         s_Thursday = map(s_Thursday, dt_fix),
         s_Friday = map(s_Friday, dt_fix),
         s_Saturday = map(s_Saturday, dt_fix),
         s_Sunday = map(s_Sunday, dt_fix))


hourly
