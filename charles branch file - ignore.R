## template for installing and loading multiple packages at once
for (package in c("tidyverse","here","skimr","janitor","magrittr","dplyr","reshape","moments","rsdmx","zoo","xts","Quandl","raustats","tidyquant","hydroTSM")) {
  if (!package %in% installed.packages()) {
    install.packages(package)
  }
  if (!package %in% .packages()) {
    library(package, character.only = TRUE)
  }
}

######## ANGUS's Code #######
# get some data ------

(url <- "https://stats.oecd.org/restsdmx/sdmx.ashx/GetData/MEI_CLI/LOLITONO.AUS.M/all?startTime=2005-01&endTime=2019-07")

dataset <- readSDMX(url)
OECDLI <- as.data.frame(dataset)
#Sort dates in xts
date = seq(as.Date("2005-01-01"), by = "1 month", length.out = nrow(OECDLI))
OECDLI <- xts(OECDLI[,-1], order.by = date, frequency = 1)
#select data and label column
OECDLI <-  setNames(OECDLI[,7], "oecd_li")

(url <- "http://stat.data.abs.gov.au/restsdmx/sdmx.ashx/GetData/MERCH_IMP/-.-1.-1.-.M/all?startTime=2005-01&endTime=2019-06")

dataset <- readSDMX(url)
AusImport <- as.data.frame(dataset)
#Sort dates in xts
date = seq(as.Date("2005-01-01"), by = "1 month", 
           length.out = nrow(AusImport))
AusImport <- xts(AusImport[,-1], order.by = date, frequency = 1)
#select data and label column
AusImport <-  setNames(AusImport[,7], "abs_imports")

(url <- "http://stat.data.abs.gov.au/restsdmx/sdmx.ashx/GetData/MERCH_EXP/-.-1.-1.-.M/all?startTime=2005-01&endTime=2019-06")

dataset <- readSDMX(url)
AusExport <- as.data.frame(dataset)
#Sort dates in xts
date = seq(as.Date("2005-01-01"), by = "1 month", 
           length.out = nrow(AusExport))
AusExport <- xts(AusExport[,-1], order.by = date, frequency = 1)
#select data and label column
AusExport <-  setNames(AusExport[,7], "abs_exports")

# Merge Data ----

Combi <- merge(OECDLI, AusImport, join="left")
Combi <- merge(Combi, AusExport, join="left")
CombiFrame <- as.data.frame(Combi)
CombiFrame <- mutate_all(CombiFrame, function(x) as.numeric(as.character(x)))


######## JOHN's Code ########
library(Quandl)
gold_forward_offer_rates <- Quandl("LBMA/GOFO", api_key="kf3rSrKM5xnKDzHNL74d")
#Gold forward rates (GOFO), in percentages; London Bullion Market Association (LBMA). LIBOR difference included. The Gold Forward Offered Rate is an international standard rate at which dealers will lend gold on a swap basis against US dollars, providing the foundation for the pricing of gold swaps, forwards and leases.

#Sort dates in xts
date <- seq(as.Date("2005-01-01/2019-06-01"), by = "1 month", 
            length.out = nrow(gold_forward_offer_rates))
gold_forward_offer_rates <- xts(gold_forward_offer_rates[,-1], order.by = date, frequency = 1) 
gold_forward_offer_rates <- gold_forward_offer_rates["2005-01-01/2019-06-01"]
gold_forward_offer_rates <- gold_forward_offer_rates$`GOFO - 1 Month`
Combi <- merge(Combi, gold_forward_offer_rates, join="left")


gold_price_london_fixing <- Quandl("LBMA/GOLD", api_key="kf3rSrKM5xnKDzHNL74d")
#Sort dates in xts
date <- seq(as.Date("2005-01-01/2019-06-01"), by = "1 month", 
            length.out = nrow(gold_price_london_fixing))
gold_price_london_fixing <- xts(gold_price_london_fixing[,-1], order.by = date, frequency = 1) 
gold_price_london_fixing <- gold_price_london_fixing["2005-01-01/2019-06-01"]
gold_price_london_fixing <- gold_price_london_fixing$`USD (AM`
Combi <- merge(Combi, gold_price_london_fixing, join="left")

#Gold Price: London Fixings, London Bullion Market Association (LBMA). Fixing levels are set per troy ounce. The London Gold Fixing Companies set the prices for gold that are globally considered as the international standard for pricing of gold. The Gold price in London is set twice a day by five LBMA Market Makers who comprise the London Gold Market Fixing Limited (LGMFL). The process starts with the announcement from the Chairman of the LGMFL to the other members of the LBMA Market Makers, then relayed to the dealing rooms where customers can express their interest as buyers or sellers and also the quantity they wish to trade. The gold fixing price is then set by collating bids and offers until the supply and demand are matched. At this point the price is announced as the 'Fixed' price for gold and all business is conducted on the basis of that price.

aud_usd <- Quandl("PERTH/AUD_USD_D", api_key="kf3rSrKM5xnKDzHNL74d")
#Sort dates in xts
date <- seq(as.Date("2005-01-01/2019-06-01"), by = "1 month", 
            length.out = nrow(aud_usd))
aud_usd <- xts(aud_usd[,-1], order.by = date, frequency = 1) 
aud_usd <- aud_usd["2005-01-01/2019-06-01"]
aud_usd$aud_usd_bid_avg <- aud_usd$`Bid Average`
aud_usd <- aud_usd$aud_usd_bid_avg
Combi <- merge(Combi, aud_usd, join="left")

#UNEMPLOYMENT
unemployment <- Quandl("FRED/NROUST", api_key="kf3rSrKM5xnKDzHNL74d")
#Sort dates in xts
date <- seq(as.Date("2005-01-01/2019-06-01"), by = "1 month", 
            length.out = nrow(unemployment))
unemployment <- xts(unemployment[,-1], order.by = date, frequency = 1) 
unemployment <- unemployment["2005-01-01/2019-06-01"]
Combi <- merge(Combi, unemployment, join="left")


######## Charles' Code ########
# list functions vailable from raustats package
ls("package:raustats")

# putting the cachelist to an array
abslist <- abs_cat_cachelist

# putting the cachelist to an array
rbalist <- rba_cachelist

## Download datasets
rba_mon <- rba_stats("A2")
rba_infla <- rba_stats("G1")

#### Data Munging ####
#### RBA Interest Rates datasets ####
colnames(rba_mon)
unique(rba_mon$title)

# Trim datasets
col <- c('date','value','title')
rba_mon <- rba_mon[,col]
colnames(rba_mon)

rba_mon <- subset(rba_mon, title == "New Cash Rate Target")
col1 <- c('date','value')
rba_mon <- rba_mon[,col1]

# complete missing month
rba_mon <- rba_mon %>% complete(date = seq.Date(min(date), max(date), by="month"))

# take only data from 2005 onwards
rba_mon <- subset(rba_mon, date >= '2005-01-01')

# adding rate into first two months of 2005 becuase rate has not changed since dec 2003 which is 5.25
rba_mon[1:2,2] = 5.25 

# populate the rest of the NA
rba_mon_fin <- rba_mon %>% fill('value')

# check to confirm no na
unique(is.na(rba_mon_fin))


# covert to data frame
rba_mon_fin<-as.data.frame(rba_mon_fin)

# correct colname
colnames(rba_mon_fin) <- c('date','RBA Interest Rate')
colnames(rba_mon_fin)

head(rba_mon_fin)


#### RBA Year-end Inflation Datasets ####

colnames(rba_infla)
unique(rba_infla$title)
unique(rba_infla$frequency)
rba_infla<- subset(rba_infla, title == "Year-ended inflation")
unique(rba_infla$title)

# Trim datasets
col <- c('date','value','title')
rba_infla <- rba_infla[,col]
colnames(rba_infla)

str(rba_infla)

col1 <- c('date','value')
rba_infla <- rba_infla[,col1]

nrow(rba_infla)

# complete missing month and put it on a new variable
rba_infla_day <- rba_infla %>% complete(date = seq.Date(min(date), max(date), by="day"))

# check to see confirm more rows created
nrow(rba_infla_day)

# populate the rest of the NA
rba_infla_day <- rba_infla_day %>% fill('value')

# check to confirm no na
unique(is.na(rba_infla_day))

# take only data from the last reading before 2005 onwards
rba_infla_day <- subset(rba_infla_day, date >= '2005-01-01')

# convert to monthly data
rba_infla_day <- as.data.frame(rba_infla_day)

rba_infla_day$date <- as.POSIXct.Date(rba_infla_day$date)
rba_infla_day$date <- strptime(rba_infla_day$date,"%Y-%m-%d")
rba_infla_day <- xts(rba_infla_day[,-1], order.by=rba_infla_day[,1])
rba_infla_mon <- apply.monthly(rba_infla_day,mean)
str(rba_infla_mon)

# convert to data frame
rba_infla_mon<-as.data.frame(rba_infla_mon)

nrow(rba_infla_mon)
str(rba_infla_mon)
rba_infla_mon$V1<- format(rba_infla_mon$V1, digits=1, nsmall=1)

head(rba_infla_mon)
tail(rba_infla_mon)
nrow(rba_infla_mon)

colnames(rba_infla_mon) <- c("Year-end Inflation")
colnames(rba_infla_mon)


#### RBA Quarterly Inflation Datasets ####
# download datasets
rba_infla_qrt <- rba_stats("G1")

colnames(rba_infla_qrt)
unique(rba_infla_qrt$title)
unique(rba_infla_qrt$frequency)
rba_infla_qrt<- subset(rba_infla_qrt, title == "Quarterly inflation")
unique(rba_infla_qrt$title)

# Trim datasets
col <- c('date','value','title')
rba_infla_qrt <- rba_infla_qrt[,col]
colnames(rba_infla_qrt)

str(rba_infla)

col1 <- c('date','value')
rba_infla_qrt <- rba_infla_qrt[,col1]

nrow(rba_infla_qrt)

# convert to daily readings
rba_infla_qrt_day <- rba_infla_qrt %>% complete(date = seq.Date(min(date), max(date), by="day"))

# check to see confirm more rows created
nrow(rba_infla_qrt_day)

# populate the rest of the NA on daily readings
rba_infla_qrt_day <- rba_infla_qrt_day %>% fill('value')

#confirm no NA
unique(is.na(rba_infla_day))

# take only data from the last reading before 2005 onwards
rba_infla_qrt_day <- subset(rba_infla_qrt_day, date >= '2005-01-01')

# convert to monthly data
rba_infla_qrt_day <- as.data.frame(rba_infla_qrt_day)

rba_infla_qrt_day$date <- as.POSIXct.Date(rba_infla_qrt_day$date)
rba_infla_qrt_day$date <- strptime(rba_infla_qrt_day$date,"%Y-%m-%d")
rba_infla_qrt_day <- xts(rba_infla_qrt_day[,-1], order.by=rba_infla_qrt_day[,1])
rba_infla_qrt_mon <- apply.monthly(rba_infla_qrt_day,mean)
str(rba_infla_qrt_mon)

rba_infla_qrt_mon<-as.data.frame(rba_infla_qrt_mon)

nrow(rba_infla_qrt_mon)
str(rba_infla_qrt_mon)
rba_infla_qrt_mon$V1 <- as.numeric(as.character(rba_infla_qrt_mon$V1))
str(rba_infla_qrt_mon)
summary(rba_infla_qrt_mon)
rba_infla_qrt_mon$V1 <- round(rba_infla_qrt_mon$V1,1)


head(rba_infla_qrt_mon)
tail(rba_infla_qrt_mon)
nrow(rba_infla_qrt_mon)

colnames(rba_infla_qrt_mon) <- c("Quarterly Inflation")
colnames(rba_infla_qrt_mon)



#### Merge the three datasets ####
# list all the datasets
head(rba_mon_fin)
tail(rba_mon_fin)
head(rba_infla_mon)
head(rba_infla_qrt_mon)

# check row numbers for all the datasets
nrow(rba_mon_fin)
nrow(rba_infla_mon)
nrow(rba_infla_qrt_mon)

# summary & str
str(rba_infla_mon)

# sort date in xts for rba_mon_fin
date <- seq(as.Date("2005-01-01/2019-06-01"), by = "1 month", 
            length.out = nrow(rba_mon_fin))
rba_mon_fin <- xts(rba_mon_fin, order.by = date, frequency = 1) 

# cut off excesses date range and put in the correct date range
rba_mon_fin <- rba_mon_fin["2005-01-01/2019-06-01"]

# take out the date value
rba_mon_fin <- rba_mon_fin[,2]

# sort date in xts for rba_infla_mon
date <- seq(as.Date("2005-01-01"), by = "1 month",length.out = nrow(rba_mon_fin))
rba_infla_mon <- xts( x = rba_infla_mon, order.by = date)
rba_infla_mon <- as.xts(rba_infla_mon)
# rba_infla_mon <- xts(rba_infla_mon[,-1], order.by = date, frequency = 1) 

# sort date in xts for rba_infla_qrt_mon
date <- seq(as.Date("2005-01-01/2019-06-01"), by = "1 month", 
            length.out = nrow(rba_infla_qrt_mon))
rba_infla_qrt_mon <- xts(rba_infla_qrt_mon, order.by = date, frequency = 1) 

# merge with the consolidated datasets
Combi <- merge(Combi, rba_mon_fin, join="left")
Combi <- merge(Combi, rba_infla_mon, join="left")
Combi <- merge(Combi, rba_infla_qrt_mon, join="left")

colnames(Combi)

## correcting colnames
# rename(Combi$rba_mon_fin, "RBA")
# dimnames.xts(Combi$rba_mon_fin) <- c("RBA interest rates")
# colnames(Combi[,8]) <- c("RBA interest rates")
# colnames(Combi$rba_mon_fin) <- "RBA interest rates" 




