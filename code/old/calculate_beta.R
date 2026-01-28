load("closure_sample_beta_reg_v1.rda") #file created by the script setup-data-08092025-v1.qmd
branch_df <- copy(df[['reg_sample']])

key_chars <- c("college_frac","dividend_frac","family_income","age_bin","age","population_density","log_population_density","no_of_visits")
# bank_rural <- branch_df[,.(bank_ruca = mean(RUCA1),population_density=mean(population_density,na.rm=T)),by=.(RSSDID,yr)]

branch_2019 <- branch_df[yr==2019,] %>% select(all_of(c("RSSDID","DEPSUMBR","sophisticated","sophisticated_ed_sm","sophisticated_acs_only",key_chars)))
branch_2019[,sum_deposits:=sum(DEPSUMBR,na.rm=T),by=RSSDID]
branch_2019[,deposit_weight:=DEPSUMBR/sum_deposits]

branch_2019 <- branch_2019[,.(
  college_frac = sum(college_frac*deposit_weight,na.rm = T)+0.01,
  dividend_frac = sum(dividend_frac*deposit_weight,na.rm = T)+0.01,
  family_income = sum(family_income*deposit_weight,na.rm = T)+1,
  population_density = sum(population_density*deposit_weight,na.rm = T),
  log_population_density= sum(log_population_density*deposit_weight,na.rm = T)+1,
  age = sum(age*deposit_weight,na.rm = T),
  age_bin = floor(median(age_bin,na.rm = T)),
  no_of_visits = sum(no_of_visits,na.rm=T),
  sophisticated_deposits_frac=sum(sophisticated*deposit_weight,na.rm=T),
  sophisticated_ed_sm_deposits_frac=sum(sophisticated_ed_sm*deposit_weight,na.rm=T),
  sophisticated_acs_only_deposits_frac=sum(sophisticated_acs_only*deposit_weight,na.rm=T)
),
by=RSSDID]

branch_2019[,factor_age_bin:=factor(age_bin)]



branch_2012 <- branch_df[yr==2012,] %>% select(all_of(c("RSSDID","DEPSUMBR","sophisticated","sophisticated_ed_sm","sophisticated_acs_only",key_chars)))
branch_2012[,sum_deposits:=sum(DEPSUMBR,na.rm=T),by=RSSDID]
branch_2012[,deposit_weight:=DEPSUMBR/sum_deposits]

branch_2012 <- branch_2012[,.(
  college_frac = sum(college_frac*deposit_weight,na.rm = T)+0.01,
  dividend_frac = sum(dividend_frac*deposit_weight,na.rm = T)+0.01,
  family_income = sum(family_income*deposit_weight,na.rm = T)+1,
  population_density = sum(population_density*deposit_weight,na.rm = T),
  log_population_density= sum(log_population_density*deposit_weight,na.rm = T)+1,
  age = sum(age*deposit_weight,na.rm = T),
  age_bin = floor(median(age_bin,na.rm = T)),
  no_of_visits = sum(no_of_visits,na.rm=T),
  sophisticated_deposits_frac=sum(sophisticated*deposit_weight,na.rm=T),
  sophisticated_ed_sm_deposits_frac=sum(sophisticated_ed_sm*deposit_weight,na.rm=T),
  sophisticated_acs_only_deposits_frac=sum(sophisticated_acs_only*deposit_weight,na.rm=T)
),
by=RSSDID]

branch_2012[,factor_age_bin:=factor(age_bin)]




call_data <-readRDS("call_data.rds")

cycles <- list()
cycles[['0406']][['st']] <- as.Date('2004-03-31')
cycles[['0406']][['ed']] <- as.Date('2006-03-31')
cycles[['0406']][['demos']] <- copy(branch_2012)
cycles[['0406']][['call_chg']] <- NULL
cycles[['0406']][['reg']] <- NULL
cycles[['0406']][['rate_chg']] <- 3.5
cycles[['0406']][['deposit_chg']] <- NULL

cycles[['1619']][['st']] <- as.Date('2016-03-31')
cycles[['1619']][['ed']] <- as.Date('2019-03-31')
cycles[['1619']][['demos']] <- copy(branch_2019)
cycles[['1619']][['call_chg']] <- NULL
cycles[['1619']][['reg']] <- NULL
cycles[['1619']][['rate_chg']] <- 2.5
cycles[['1619']][['deposit_chg']] <- NULL

cycles[['2224']][['st']] <- as.Date('2022-03-31')
cycles[['2224']][['ed']] <- as.Date('2023-03-31')
cycles[['2224']][['demos']] <- copy(branch_2019)
cycles[['2224']][['call_chg']] <- NULL
cycles[['2224']][['reg']] <- NULL
cycles[['2224']][['rate_chg']] <- 4
cycles[['2224']][['deposit_chg']] <- NULL



x_vars_c <- c("factor_age_bin","log(family_income)","dividend_frac","college_frac")#
x_vars <- paste(x_vars_c,collapse="+")


for(i in 1:length(cycles)) {
  cycle_nm <- names(cycles)[[i]]
  cycle <- cycles[[i]]
  
  call_chg <- call_data[D_DT %in% c(cycle[['st']],cycle[['ed']])]
  call_chg <- dcast(call_chg,ID_RSSD~D_DT,value.var = c("deposit_exp_deposits"))
  names(call_chg) <- gsub(as.character(cycle[['st']]),"start",names(call_chg))
  names(call_chg) <- gsub(as.character(cycle[['ed']]),"end",names(call_chg))
  call_chg[,deposit_exp_deposits_chg:=end-start]
  
  call_chg <- call_chg[,c("ID_RSSD","deposit_exp_deposits_chg")]
  
  call_chg <- call_chg[!is.na(deposit_exp_deposits_chg)]
  
  call_chg <- call_chg[  deposit_exp_deposits_chg > quantile(deposit_exp_deposits_chg,0.02,na.rm=T) &
                           deposit_exp_deposits_chg < quantile(deposit_exp_deposits_chg,0.98,na.rm=T) ]
  
  call_chg <- merge(call_chg,cycles[[cycle_nm]][['demos']],by.x="ID_RSSD",by.y = "RSSDID")
  
  bank_chars <- df[['bank_level_data']][yr==year(cycle[['st']])]
  call_chg <- merge(call_chg,bank_chars[,.(RSSDID,bank_hhi,bank_assets,trans_accts_frac_assets,ci_assets,uninsured_deposits_frac)],by.x=c("ID_RSSD"),by.y=c("RSSDID"))
  
  # call_chg <- call_chg[bank_assets > 100e6 | (deposit_exp_deposits_chg>quantile(call_chg$deposit_exp_deposits_chg,0.01) &  deposit_exp_deposits_chg < quantile(call_chg$deposit_exp_deposits_chg,0.99))]
  
  call_chg[,lag_county_deposit_hhi:=bank_hhi]
  call_chg[,deposit_beta:=deposit_exp_deposits_chg/cycles[[cycle_nm]][['rate_chg']]]
  
  cycles[[cycle_nm]][['call_chg']] <- copy(call_chg)
  
  # cycles[[cycle_nm]][['reg']] <- feols(as.formula(paste0("deposit_exp_deposits_chg~",x_vars,"+lag_county_deposit_hhi+log(bank_assets)+population_density+trans_accts_frac_assets+ci_assets+uninsured_deposits_frac")),data=call_chg) #+ci_assets+uninsured_deposits_frac
  
  cycles[[cycle_nm]][['reg']] <- feols(as.formula(paste0("deposit_exp_deposits_chg~",x_vars,"+lag_county_deposit_hhi+log(bank_assets)+population_density+trans_accts_frac_assets+uninsured_deposits_frac")),data=call_chg) #+ci_assets+uninsured_deposits_frac
  cycles[[cycle_nm]][['reg_sophisticated']] <- feols(as.formula(paste0("deposit_exp_deposits_chg~sophisticated_ed_sm_deposits_frac+factor_age_bin+log(family_income)+lag_county_deposit_hhi+log(bank_assets)+population_density+trans_accts_frac_assets+uninsured_deposits_frac")),data=call_chg) #+ci_assets+uninsured_deposits_frac
  
  # st_yr <-year(cycle[['st']])-1
  # ed_yr <- year(cycle[['ed']])
  # st <- branch_year[yr==st_yr & !is.na(UNINUMBR)]
  # ed <- branch_year[yr==ed_yr & !is.na(UNINUMBR),c("UNINUMBR","DEPSUMBR")]
  # setnames(ed,"DEPSUMBR","DEPSUMBR_end")
  # 
  # st <- merge(st,ed,by="UNINUMBR")
  # st[,change_deposits:=DEPSUMBR_end/DEPSUMBR-1]
  # st[,change_deposits:=change_deposits/(ed_yr-st_yr)] # annualize
  # st <- st[change_deposits>quantile(st$change_deposits,0.01,na.rm=T) & change_deposits<quantile(st$change_deposits,0.99,na.rm=T)]
  # 
  # cycles[[cycle_nm]][['deposit_chg']] <- copy(st)
}