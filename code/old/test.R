hmda_bank_county_yr <- readRDS("C:/Users/e3dxr03/OneDrive - FR Banks/Projects/deposit-franchise-bank-branches/data/hmda_bank_county_yr.rds") # C:\Users\e3dxr03\OneDrive - FR Banks\Projects\Utilities\HMDA-Avery-Link.qmd
temp <- hmda_bank_county_yr[year==2004]
for(y in 2000:2003) {
  temp[,year:=y]
  hmda_bank_county_yr <- rbind(hmda_bank_county_yr,temp)
}
hmda_bank_county_yr <- hmda_bank_county_yr %>%
                       arrange(RSSD,county_code,year) %>%
                       group_by(RSSD,county_code) %>%
                       mutate(
                         lag_bank_county_mortgage_volume = lag(bank_county_mortgage_volume,1)
                       ) %>% 
                       select(-bank_county_mortgage_volume) %>% ungroup() %>% data.table()

branch_df <- merge(branch_df,hmda_bank_county_yr,by.x=c("RSSDID","yr","STCNTYBR"),by.y=c("RSSD","year","county_code"),all.x=T)
branch_df[,lag_bank_county_mortgage_volume:=ifelse(is.na(lag_bank_county_mortgage_volume) & RSSDID %in% hmda_bank_county_yr$RSSD,0,lag_bank_county_mortgage_volume)]
branch_df[,lag_bank_county_mortgage_volume:=lag_bank_county_mortgage_volume+1]



cra_bank_county_yr <- readRDS("C:/Users/e3dxr03/OneDrive - FR Banks/Projects/deposit-franchise-bank-branches/data/cra_bank_county_yr.rds") # C:\Users\e3dxr03\OneDrive - FR Banks\Projects\Utilities\CRA-bank-county-year.qmd
temp <- cra_bank_county_yr[year==2004]
for(y in 2000:2003) {
  temp[,year:=y]
  cra_bank_county_yr <- rbind(cra_bank_county_yr,temp)
}
cra_bank_county_yr <- cra_bank_county_yr %>%
                       arrange(RSSD,county_code,year) %>%
                       group_by(RSSD,county_code) %>%
                       mutate(
                         lag_bank_county_cra_volume = lag(loan_amt,1)
                       ) %>% 
                       select(-loan_amt,-hmda_id) %>% ungroup() %>% data.table()

branch_df <- merge(branch_df,cra_bank_county_yr,by.x=c("RSSDID","yr","STCNTYBR"),by.y=c("RSSD","year","county_code"),all.x=T)
branch_df[,lag_bank_county_cra_volume:=ifelse(is.na(lag_bank_county_cra_volume) & RSSDID %in% cra_bank_county_yr$RSSD,0,lag_bank_county_cra_volume)]
branch_df[,lag_bank_county_cra_volume:=lag_bank_county_cra_volume+1]