library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)

raw <- GET("http://sam.lrv.lt/lt/naujienos/koronavirusas")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)

# Add the totals data -----------------------------------------------------

cd <- html_nodes(oo,".text") %>% html_nodes("li") %>% html_text

cd1 <-  html_nodes(oo,".text") %>% html_nodes("strong") %>% html_text

cd2 <- html_nodes(oo,".text") %>% html_nodes("p") %>% html_text

cdd <- cd %>% strsplit(":")
cdd <- cdd[sapply(cdd, length) == 2]
nums1 <- cdd %>% sapply("[[", 2) %>% gsub("(.{1})([0-9]+)(.*)","\\2",.) %>% str_trim %>%  as.integer

nums2 <- cd1 %>% str_trim %>% gsub("([0-9]+)(.*)","\\1",.) %>% as.integer %>% na.omit

ia1 <- cd2[grepl("įvežt",cd2)] %>% strsplit(":") %>% .[[1]] %>% .[2] %>% str_trim %>% as.integer

# nums89 <- cd2[grepl("Per vakar",cd2)] %>%
#     strsplit("\r\n") %>%
#     .[[1]] %>%
#     strsplit(":") %>%
#     sapply(function(x)x[min(length(x),2)]) %>%
#     gsub("(.{1})([0-9]+)(.*)","\\2",.) %>%
#     str_trim %>% as.integer %>% na.omit

#nums <- c(nums1, nums89)

nums <- nums1

fns <- dir("total", pattern="[0-9]+.csv", full.names  = TRUE)

days <- fns %>% strsplit("-") %>% sapply(function(x)gsub(".csv","",x[length(x)]))

daysd <- ymd(days)

new_day <- max(daysd)+days(1)

outd <- gsub("-","",as.character(new_day))

new_day_data <- read.csv(fns[which.max(daysd)], stringsAsFactors = FALSE)

old_day_data <- new_day_data

new_day_data$day <- new_day



if ((nums[1] - nums[3]) == new_day_data$confirmed[1])  {
    new_day_data$confirmed[1] <- nums[1]
} else {
    warning("Confirmed numbers do not match")
    new_day_data$confirmed[1] <-  new_day_data$confirmed[1] + nums[3]
}

new_day_data$deaths[1] <- nums[4]
if (nums[4] < new_day_data$deaths[1]) warning("Deaths number is lower")

new_day_data$recovered[1] <- nums[6]

if (nums[6] < new_day_data$recovered[1])
    warning("Recovered number is lower")


if ((nums[9] - nums[8]) == new_day_data$tested[1])  {
    new_day_data$tested[1] <- nums[9]
} else  {
    warning("Tested numbers do not match")
    new_day_data$tested[1] <- nums[9]
}

new_day_data$quarantined[1] <- nums[7]

write.csv(new_day_data, glue::glue("total/lt-covid19-total-{outd}.csv"), row.names = FALSE )

ndd <- new_day_data %>% select(country, day) %>%
    mutate(confirmed = nums[1],
           active = nums[2],
           incidence = nums[3],
           deaths = nums[4],
           deaths_different =nums[5],
           recovered = nums[6],
           daily_tests = nums[8],
           quarantined = nums[7],
           total_tests = nums[9],
           imported0601 = ia1)
write.csv(ndd, glue::glue("daily/lt-covid19-daily-{outd}.csv"), row.names = FALSE )

