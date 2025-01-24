#########################################################################################
# Step 1 - Loading related data
#########################################################################################
install.packages("lubridate")
install.packages("RPostgres")
install.packages("zoo")
install.packages("broom")
install.packages("readr")
install.packages("data.table")




uninstall.packages("dplyr")
install.packages("moments")
install.packages("tidyquant")
install.packages("timetk")
install.packages("rlang")
install.packages("tidyverse")
install.packages("dplyr")
install.packages("installr")

detach(package:tidyverse, unload = TRUE)
packageDescription("dplyr", fields = "Depends")
updateR()



######################
## start 
######################

library(tidyverse)
library(rlang)
library(tidyquant) # To download the data
library(plotly) # To create interactive charts
library(timetk) # To manipulate the data series
library(tidyr)
library(dplyr)


# Related libraries
library(tidyverse); library(tidyr); library(zoo);
library(lubridate); library(readr); library(moments); 
library(RPostgres); library(scales); library(broom);
require(data.table)

portfolio <- "FF"

# calculate BE
AUT.BE <- read.csv("AUT_yly.csv")
AUT.BE <- AUT.BE %>%
  filter(!is.na(cequ))

AUT.BE[,5][is.na(AUT.BE[,5])] <- 0

AUT.BE <- AUT.BE %>%
  mutate(BE = cequ + dtax)

# create portfolio 
AUT.ret <- read.csv("AUT_mly.csv")

AUT.ret <- AUT.ret %>%
  select(-c(ret,mv))
 
AUT.ret <- AUT.ret %>%
  filter(ret_usd<= 890) %>%
  filter(!is.na(ret_usd)) 



 AUT.ret <- AUT.ret %>%
  mutate(YEAR = year(Date))

AUT.ret <- AUT.ret %>%
  left_join(AUT.BE, by=c("YEAR","Id"))

AUT.ret <- AUT.ret %>%
  select(-�..country.y)


AUT.ret <- AUT.ret %>%
  mutate(BEME = BE/mv_usd)

AUT.ret <- AUT.ret %>%
  mutate(ym = as.yearmon(Date))

AUT_quantiles <- AUT.ret %>% 
  filter(month(ym) == 6) %>%
  group_by(ym) %>%
  summarize(BSmed = median(mv_usd, na.rm = TRUE),
            HNLq30 = quantile(BEME, probs = 0.30, na.rm = TRUE),
            HNLq70 = quantile(BEME, probs = 0.70, na.rm = TRUE)) %>%
  mutate(ym = as.Date(ym) %m+% months(1)) %>%
  mutate(ym = as.yearmon(ym)) 

AUT.ret.QUANTILE <- AUT.ret %>%
  left_join(AUT_quantiles, by=c("ym")) %>%
  arrange(ym) %>%
  mutate_at(vars(BSmed,HNLq30,HNLq70), funs(na.locf(.,na.rm = FALSE)))   

AUT.ret.QUANTILE <- AUT.ret.QUANTILE %>%
  mutate(BS = case_when( mv_usd < BSmed ~ "S",
                         mv_usd >= BSmed ~ "B"),
         HNL = case_when( BEME < HNLq30 ~ "L",
                          BEME >= HNLq30 & BEME < HNLq70 ~ "N",
                          BEME >= HNLq70 ~ "H"))  

AUT.ret.QUANTILE <- AUT.ret.QUANTILE %>%
  mutate(LABEL = paste0(BS,HNL))

AUT.ret.QUANTILE <- AUT.ret.QUANTILE %>%
  select(-c(BS,HNL))

AUT.ret.QUANTILE <- AUT.ret.QUANTILE %>%
  filter(!is.na(ret_usd))

setDT(AUT.ret.QUANTILE)

AUT_mly_FF3 <- AUT.ret.QUANTILE %>%
  group_by(LABEL, ym) %>%
  summarize(ret_VW = weighted.mean(ret_usd, mv_usd, na.rm = TRUE),
            ret_EW = mean(ret_usd, na.rm = TRUE)) %>%
  ungroup() %>% as.data.table() %>%
  melt(id.vars = c("ym", "LABEL")) %>%
  reshape(idvar= c("ym", "variable"),
          timevar = "LABEL",
          direction ="wide") %>%
  mutate(SMB = ((value.SH + value.SN + value.SL)/3) - ((value.BH + value.BN + value.BL)/3),
         HML = ((value.SH + value.BH)/2) - ((value.SL + value.BL)/2)) %>%
  select(ym,variable,SMB,HML)






AUT.retANALYZE <- AUT.ret %>%
  filter(!is.na(ret_usd)) %>%
  left_join(AUT_mly_FF3, by = "ym") %>%
  filter(variable == "ret_EW")

REG_MODEL <- lm("ret_usd ~ SMB + HML", data = AUT.retANALYZE)


############################ start again

## load factor

factors_ff = read.csv("Europe_5_Factors.csv")
factors_subset_month = factors_ff %>% filter(yearmonth >= 200001) %>% filter(yearmonth < 201800)

factors_subset_month
rf = (factors_subset_month %>% colMeans())['RF']/100
rf

#%>% mean()


#####################################

AUT.BE <- read.csv("AUT_yly.csv")
AUT.BE <- AUT.BE %>%
  filter(!is.na(cequ))

AUT.BE[,5][is.na(AUT.BE[,5])] <- 0

AUT.BE <- AUT.BE %>%
  mutate(BE = cequ + dtax) %>% mutate(OLD_YEAR = YEAR , YEAR = YEAR +1 )

AUT.retANALYZE2 <- AUT.retANALYZE %>% select(Id , Date , ret_usd , up , mv_usd, YEAR , ym , variable , SMB, HML)

Aut.joined <- AUT.retANALYZE2 %>% left_join(AUT.BE , by =c("YEAR", "Id") )

list_11 <- Aut.joined %>% filter(YEAR >= 2000& YEAR < 2018)  %>% filter(is.na(BE) | is.na(ret_usd)) %>% select(Id) %>% unique() 

df= Aut.joined %>% anti_join(list_11,by="Id")
df %>% filter(YEAR >= 2000 & YEAR < 2018) %>% count()
df3 <- df %>% filter(YEAR >= 2000& YEAR < 2018) %>% group_by(Id) %>% summarize(cnt = n())
view(df3)

n_cnt = ((2017-2000)+1) *12
n_cnt
# view(cnt)


list_stock2 = df3 %>% filter(cnt == n_cnt) %>% select(Id) %>% unique()


df_joined <- df %>% inner_join(list_stock2 , by =c("Id") ) %>% filter(YEAR >= 2000& YEAR < 2018)

##  number = 216

df_joined %>% select(Id) %>% unique() %>% count()

log_ret_tidy <- df_joined %>% mutate(ret_usd = ret_usd/100) %>%
  select(Id , ym,ret_usd) 

log_ret_xts <- log_ret_tidy %>%
  spread(Id, value = ret_usd) %>%
  tk_xts()

log_ret_xts


mean_ret <- colMeans(log_ret_xts)
mean_ret

cov_mat <- cov(log_ret_xts) * 12
cov_mat
print(round(cov_mat,4))


wts = runif(n = length(mean_ret ))
sum(wts)
wts <- wts/sum(wts)
wts
sum(wts)


port_returns <- (sum(wts * mean_ret) + 1)^12 - 1
port_risk <- sqrt(t(wts) %*% (cov_mat %*% wts))

print(port_returns)
print(port_risk)

# eq weight
weight = 1/length(mean_ret )
wts = rep(weight, length(mean_ret )) %>% as.matrix()
length(mean_ret )


mat = log_ret_xts %>% as.matrix() 




retport_eqw = mat %*% wts


retport_eqw

## MV weight
log_ret_tidy_mv <- df_joined %>% mutate(ret_usd = ret_usd/100) %>%
  select(Id , ym, mv_usd) 

log_ret_xts_mv <- log_ret_tidy_mv %>%
  spread(Id, value = mv_usd) %>%
  tk_xts()  
  

dfsum <- log_ret_xts_mv %>% as.data.frame() %>% rowSums() %>% as.data.frame()

names(dfsum) <- "mv"

log_ret_xts_mv %>% as.data.frame()

inv_mv_df = dfsum %>% mutate(inv_mv = 1/mv) %>% select(inv_mv)

log_ret_xts_mv

x = log_ret_xts_mv %>% as.matrix()

cbind(x[1], prop.table(as.matrix(x[-1])), margin = 1)
weighted_x <- x/rowSums(x)
names(weighted_x %>% as.data.frame())
names(mat %>% as.data.frame())
rowSums(weighted_x)

## st
dim(mat)
dim(weighted_x)

mv_mat  <- rowSums(mat * weighted_x)
retport_MV <-  mv_mat
retport_MV



### book value

names(df_joined)

log_ret_tidy_be <- df_joined %>% mutate(ret_usd = ret_usd/100) %>%
  select(Id , ym, BE) 

log_ret_xts_be <- log_ret_tidy_be %>%
  spread(Id, value = BE) %>%
  tk_xts()  


dfsum <- log_ret_xts_be %>% as.data.frame() %>% rowSums() %>% as.data.frame()

names(dfsum) <- "be"



log_ret_xts_be

x = log_ret_xts_be %>% as.matrix()

cbind(x[1], prop.table(as.matrix(x[-1])), margin = 1)
weighted_x <- x/rowSums(x)
names(weighted_x %>% as.data.frame())
names(mat %>% as.data.frame())
rowSums(weighted_x)

## st
dim(mat)
dim(weighted_x)

be_mat  <- rowSums(mat * weighted_x)
retport_BE <-  be_mat

## mean

retport_eqw %>% mean()
retport_MV %>% mean()
retport_BE%>% mean()

## sd 
retport_eqw %>% sd()
retport_MV %>% sd()
retport_BE%>% sd()


##########################################
#################### start replacement   : run install package only 1st time
##########################################

#install.packages("timeSeries")
#install.packages("PortfolioAnalytics")
#install.packages("ROI")
#install.packages(c("ROI.plugin.glpk", "ROI.plugin.quadprog" , "ROI.plugin.symphony"))


#######################################


library(timeSeries)
library(PortfolioAnalytics)
library(PerformanceAnalytics)
library(ROI)
library(zoo)
library(ROI.plugin.glpk)
library(ROI.plugin.quadprog)
library(ROI.plugin.symphony)
# convert zoo into timeSeries
index(log_ret_xts)    <- as.Date(index(log_ret_xts))
data_ret <- as.timeSeries(log_ret_xts)
data_ret
assets <- colnames(log_ret_xts)











portfolio.init <- portfolio.spec(assets)
# portfolio.init <- add.constraint(portfolio.init, type = "full_investment")
portfolio.init <- add.constraint(portfolio.init, type="long_only")
portfolio.init <- add.constraint(portfolio.init, type="box",min=0, max=0.1)

# calculate minimum std. dev. portfolio
portfolio.minSD <- add.objective(portfolio = portfolio.init, type="risk", name="StdDev")
portfolio.minSD.opt <- optimize.portfolio(data_ret, portfolio = portfolio.minSD, optimize_method = "ROI", trace = TRUE)
portfolio.minSD.weights <- portfolio.minSD.opt$weights

portfolio.minSD.weights



##excess ret
excess_ret_data = data_ret - rf

## max sharp

sharpe.portf <- add.objective(portfolio=portfolio.init, type="risk", name="StdDev")
sharpe.portf <- add.objective(portfolio=sharpe.portf, type="return", name="mean")

# Optimization to maximize Sharpe Ratio
max_sharpe_opt <- optimize.portfolio(excess_ret_data, portfolio=sharpe.portf, optimize_method="ROI", maxSR=TRUE)
max_sharpe_opt
max_sharpe_opt.weights <- max_sharpe_opt$weights
max_sharpe_opt.weights




##########################################
### end replacement
##########################################


portfolio.minSD.weights 
max_sharpe_opt.weights
#min_var_weight
#max_sharp_weight




# w_min = t(portfolio.minSD.weights %>% as.matrix())
retport_minvar = mat %*% portfolio.minSD.weights 
retport_minvar


# w_max = t(max_sharp_weight %>% as.matrix())

retport_maxshp = mat %*% max_sharpe_opt.weights 
retport_maxshp

retport_minvar  %>% mean()
retport_minvar %>% sd()

retport_maxshp %>% mean()
retport_maxshp %>% sd()





# colnames(all_wts) <- colnames(log_ret_xts)

# Combing all the values together
#portfolio_values <- tk_tbl(cbind(all_wts, portfolio_values))
#names(portfolio_values)
#all_wts





### gather all return 
retport_eqw %>% mean() 
retport_MV %>% as.matrix() %>% mean() 
retport_BE %>% as.matrix() %>% mean() 
retport_maxshp  %>% mean() 
retport_minvar  %>% mean() 


retport_eqw %>% sd() 
retport_MV %>% as.matrix() %>% sd() 
retport_BE %>% as.matrix() %>% sd() 
retport_maxshp  %>% sd() 
retport_minvar  %>% sd() 



retport_eqw %>% str()
retport_MV %>% str()
retport_BE%>% str()
retport_maxshp%>% str()
retport_minvar%>% str()

retport_MV = retport_MV %>% as.data.frame()
retport_BE = retport_BE %>% as.data.frame()

ret_combine = cbind(rownames(retport_eqw) , retport_eqw , retport_MV , retport_BE , retport_maxshp , retport_minvar)
names(ret_combine) <- c("ym","ret_equal_weight","ret_market_value" , "ret_book_value" , "ret_max_sharpe" ,"ret_min_var")



### all return and sd
ret_combine[c("ret_equal_weight","ret_market_value" , "ret_book_value" , "ret_max_sharpe" ,"ret_min_var")]  %>% colSums()
apply(ret_combine[c("ret_equal_weight","ret_market_value" , "ret_book_value" , "ret_max_sharpe" ,"ret_min_var")], 2, sd)



df_factor_1 <- df_joined %>% select(ym,SMB ,HML)
df_factor_2 <- factors_subset_month %>% select(yearmonth , Mkt.RF , RMW , CMA, RF)


df_combined_premod = cbind(ret_combine , df_factor_1 , df_factor_2)
tail(df_combined_premod)
names(df_combined_premod)

###################################
## new apply 
##################################

df_combined_premod

factor_mom <- read.csv("factor_mom.csv")
factor_mom <- factor_mom %>% mutate(  ym = str_pad( ym , width =6 , side= c("left")   , pad = "0" )) %>% select(ym, return)
names(factor_mom) <- c("yearmonth" , "WML")
names(factor_mom)
names(df_combined_premod) <- c("ym1", "ret_equal_weight" , "ret_market_value" ,  "ret_book_value" , "ret_max_sharpe","ret_min_var", "ym", "SMB", "HML", "yearmonth","Mkt.RF","RMW","CMA","RF")


factor_mom = transform(factor_mom, yearmonth = as.numeric(yearmonth))

df_combined_premod2 <- df_combined_premod %>% 
  left_join(factor_mom, by=c("yearmonth"))


ff4_equal_weight <- lm(ret_equal_weight ~ Mkt.RF+ SMB + HML + WML  , data = df_combined_premod2)
ff4_market_value <- lm(ret_market_value ~ Mkt.RF + SMB + HML + WML , data = df_combined_premod2)
ff4_book_value <- lm(ret_book_value ~ Mkt.RF + SMB + HML + WML , data = df_combined_premod2)
ff4_max_sharpe <- lm(ret_max_sharpe ~ Mkt.RF + SMB + HML + WML , data = df_combined_premod2)
ff4_min_var <- lm(ret_min_var ~ Mkt.RF + SMB + HML + WML , data = df_combined_premod2)



#########################
## done 4
#####################



####################################
## 
####################################


### modeling 

# CAPM with alpha 

capm_equal_weight <- lm(ret_equal_weight ~ Mkt.RF , data = df_combined_premod)
capm_market_value <- lm(ret_market_value ~ Mkt.RF , data = df_combined_premod)
capm_book_value <- lm(ret_book_value ~ Mkt.RF , data = df_combined_premod)
capm_max_sharpe <- lm(ret_max_sharpe ~ Mkt.RF , data = df_combined_premod)
capm_min_var <- lm(ret_min_var ~ Mkt.RF , data = df_combined_premod)

# summary

summary(capm_equal_weight)
summary(capm_market_value)
summary(capm_book_value)
summary(capm_max_sharpe)
summary(capm_min_var)



## wrrite csv

write.csv(tidy(capm_equal_weight), "capm_equal_weight.csv")

write.csv(tidy(capm_market_value), "capm_market_value.csv")

write.csv(tidy(capm_book_value), "capm_book_value.csv")

write.csv(tidy(capm_max_sharpe), "capm_max_sharpe.csv")

write.csv(tidy(capm_min_var), "capm_min_var.csv")

## FF 4 factor model 

ff4_equal_weight <- lm(ret_equal_weight ~ Mkt.RF+ SMB + HML + RMW  , data = df_combined_premod)
ff4_market_value <- lm(ret_market_value ~ Mkt.RF + SMB + HML + RMW , data = df_combined_premod)
ff4_book_value <- lm(ret_book_value ~ Mkt.RF + SMB + HML + RMW , data = df_combined_premod)
ff4_max_sharpe <- lm(ret_max_sharpe ~ Mkt.RF + SMB + HML + RMW , data = df_combined_premod)
ff4_min_var <- lm(ret_min_var ~ Mkt.RF + SMB + HML + RMW , data = df_combined_premod)



summary(ff4_equal_weight)
summary(ff4_market_value)
summary(ff4_book_value)
summary(ff4_max_sharpe)
summary(ff4_min_var)


write.csv(tidy(ff4_equal_weight), "ff4_equal_weight.csv")

write.csv(tidy(ff4_market_value), "ff4_market_value.csv")

write.csv(tidy(ff4_book_value), "ff4_book_value.csv")

write.csv(tidy(ff4_max_sharpe), "ff4_max_sharpe.csv")

write.csv(tidy(ff4_min_var), "ff4_min_var.csv")



### FF 5 factor model 



ff_equal_weight <- lm(ret_equal_weight ~ Mkt.RF+ SMB + HML + RMW + CMA , data = df_combined_premod)
ff_market_value <- lm(ret_market_value ~ Mkt.RF + SMB + HML + RMW + CMA, data = df_combined_premod)
ff_book_value <- lm(ret_book_value ~ Mkt.RF + SMB + HML + RMW + CMA, data = df_combined_premod)
ff_max_sharpe <- lm(ret_max_sharpe ~ Mkt.RF + SMB + HML + RMW + CMA, data = df_combined_premod)
ff_min_var <- lm(ret_min_var ~ Mkt.RF + SMB + HML + RMW + CMA, data = df_combined_premod)

## summary

summary(ff_equal_weight)
summary(ff_market_value)
summary(ff_book_value)
summary(ff_max_sharpe)
summary(ff_min_var)




write.csv(tidy(ff_equal_weight), "ff_equal_weight.csv")

write.csv(tidy(ff_market_value), "ff_market_value.csv")

write.csv(tidy(ff_book_value), "ff_book_value.csv")

write.csv(tidy(ff_max_sharpe), "ff_max_sharpe.csv")

write.csv(tidy(ff_min_var), "ff_min_var.csv")







