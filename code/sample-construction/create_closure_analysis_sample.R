# ==============================================================================
# Create Final Branch-Year Closure Analysis Sample
# ==============================================================================
# This script merges branch closure panel with demographics, county controls,
# foot traffic data, and bank-level financial data
# ==============================================================================

rm(list=ls())

library(data.table)
library(dplyr)
library(stringr)

data_dir <- "C:/OneDrive/data/nrs_branch_closure"

# ==============================================================================
# 1. Load Pre-constructed Panel Data
# ==============================================================================

# Branch-year panel with closure indicators (created by create_branch_closure_panel.R)
branch_df <- readRDS(file.path(data_dir, "branch_closure_panel.rds"))

# Zip-year demographics (ACS + IRS) (created by create_zip_demographics_panel.R)
zip_demo_data <- readRDS(file.path(data_dir, "zip_demographics_panel.rds"))

# County-year controls (HMDA, CRA, CBP, GDP, LMI) (created by create_county_controls_panel.R)
county_control_df <- readRDS(file.path(data_dir, "county_controls_panel.rds"))

# Branch visits data (SafeGraph)
branch_visits <- readRDS(file.path(data_dir, "bank_branch_visits_count_2019_2022.rds"))

# Call report data
call_reports <- readRDS(file.path(data_dir, "call_data_01282026.rds"))
setnames(call_reports, "total_assets", "bank_assets")

# SOD data for calculating bank HHI
# Data created by: https://github.com/dratnadiwakara/r-utilities/blob/main/fdic-api/sod_download_all_data_to_rds.R
branch_year <- readRDS('C:/OneDrive/data/fdic_sod_2000_2025_simple.rds')
branch_year <- data.table(branch_year)
if("YEAR" %in% names(branch_year)) setnames(branch_year, "YEAR", "yr")
branch_year[, STCNTYBR := str_pad(STCNTYBR, 5, "left", "0")]

# ==============================================================================
# 2. Prepare Branch Visits Data
# ==============================================================================

branch_visits <- data.table(branch_visits)
branch_visits[, yr := year(DATE_RANGE_START)]

# Filter to 2021 and aggregate to branch level
branch_visits <- branch_visits[yr %in% c(2021), 
                               c("UNINUMBR", "MEDIAN_DWELL", "DISTANCE_FROM_HOME", 
                                 "RAW_VISITOR_COUNTS", "RAW_VISIT_COUNTS")]

setnames(branch_visits, 
         c("MEDIAN_DWELL", "DISTANCE_FROM_HOME", "RAW_VISITOR_COUNTS", "RAW_VISIT_COUNTS"),
         c("time_spent_min", "distance_from_home_km", "no_of_visitors", "no_of_visits"))

branch_visits[, distance_from_home_km := distance_from_home_km / 1000]

branch_visits <- branch_visits[, .(
  time_spent_min = mean(time_spent_min, na.rm = TRUE),
  distance_from_home_km = mean(distance_from_home_km, na.rm = TRUE),
  no_of_visitors = mean(no_of_visitors, na.rm = TRUE),
  no_of_visits = mean(no_of_visits, na.rm = TRUE)
), by = .(UNINUMBR)]

# ==============================================================================
# 3. Calculate Bank-Level HHI
# ==============================================================================
# Based on Drechsler, Savov, and Schnabl (2021) "Banking on Deposits: Maturity 
# Transformation without Interest Rate Risk" Journal of Finance

# County-level deposit HHI
hhi <- branch_year[, .(deposits = sum(DEPSUMBR, na.rm = TRUE)), by = .(RSSDID, STCNTYBR, yr)]
hhi[, total_deposits := sum(deposits, na.rm = TRUE), by = .(STCNTYBR, yr)]
hhi[, deposit_share := deposits / total_deposits]
hhi[, deposit_share := deposit_share * deposit_share]
hhi <- hhi[, .(deposits_state_hhi = sum(deposit_share)), by = .(STCNTYBR, yr)]

# Bank-level weighted HHI
bank_hhi <- branch_year[, c("RSSDID", "DEPSUMBR", "STCNTYBR", "yr")]
bank_hhi <- bank_hhi[, .(bank_county_deposits = sum(DEPSUMBR)), by = .(yr, STCNTYBR, RSSDID)]
bank_hhi[, bank_deposits := sum(bank_county_deposits), by = .(yr, RSSDID)]
bank_hhi[, deposits_share := bank_county_deposits / bank_deposits]
bank_hhi <- merge(bank_hhi, hhi, by = c("STCNTYBR", "yr"))
bank_hhi[, w_hhi := deposits_share * deposits_state_hhi]

hhi_bank_level <- bank_hhi[, .(bank_hhi = sum(w_hhi)), by = .(RSSDID, yr)]
hhi_bank_level <- hhi_bank_level[yr >= 2000]

# ==============================================================================
# 4. Prepare Call Reports and Create Bank-Level Data
# ==============================================================================

# Extract year from date and keep only Q4 (December) data
call_reports[, yr := year(D_DT)]
call_reports[, month := month(D_DT)]
call_reports <- call_reports[month == 12]
call_reports[, ci_assets := ci_loans/bank_assets]
call_reports[, uninsured_deposits_frac := deposits_uninsured/(deposits_uninsured + deposits_insured)]

call_reports <- call_reports[, .(yr, ID_RSSD, trans_accts_frac_assets, ci_assets, 
                                 bank_assets, uninsured_deposits_frac)]
setorder(call_reports, ID_RSSD, yr)

# Forward fill uninsured deposits fraction
call_reports[, uninsured_deposits_frac := nafill(uninsured_deposits_frac, type = "nocb"), by = ID_RSSD]

# Merge HHI with call reports
bank_level_data <- merge(hhi_bank_level, call_reports, 
                         by.x = c("RSSDID", "yr"), 
                         by.y = c("ID_RSSD", "yr"), 
                         all.x = TRUE)
bank_level_data <- bank_level_data[!is.na(bank_assets)]

# ==============================================================================
# 5. Prepare Bank-County Level HMDA and CRA Data
# ==============================================================================

# Ensure STCNTYBR is formatted as 5-digit character string in branch_df
branch_df[, STCNTYBR := str_pad(STCNTYBR, 5, "left", "0")]

# HMDA bank-county-year data
hmda_bank_county_yr <- readRDS(file.path(data_dir, "hmda_bank_county_yr.rds"))

# Backfill 2000-2003 with 2004 values
temp <- hmda_bank_county_yr[year == 2004]
for(y in 2000:2003) {
  temp[, year := y]
  hmda_bank_county_yr <- rbind(hmda_bank_county_yr, temp)
}

# Create lagged mortgage volume
hmda_bank_county_yr <- hmda_bank_county_yr %>%
  arrange(RSSD, county_code, year) %>%
  group_by(RSSD, county_code) %>%
  mutate(
    lag_bank_county_mortgage_volume = lag(bank_county_mortgage_volume, 1)
  ) %>% 
  select(-bank_county_mortgage_volume) %>% 
  ungroup() %>% 
  data.table()

# Merge with branch data
branch_df <- merge(branch_df, hmda_bank_county_yr, 
                  by.x = c("RSSDID", "yr", "STCNTYBR"), 
                  by.y = c("RSSD", "year", "county_code"), 
                  all.x = TRUE)

# Handle missing values: set to 0 if bank appears in HMDA, then add 1 for log
branch_df[, lag_bank_county_mortgage_volume := 
          ifelse(is.na(lag_bank_county_mortgage_volume) , 0, lag_bank_county_mortgage_volume)]
branch_df[, lag_bank_county_mortgage_volume := lag_bank_county_mortgage_volume + 1]

# CRA bank-county-year data
cra_bank_county_yr <- readRDS(file.path(data_dir, "cra_bank_county_yr.rds"))

# Backfill 2000-2003 with 2004 values
temp <- cra_bank_county_yr[year == 2004]
for(y in 2000:2003) {
  temp[, year := y]
  cra_bank_county_yr <- rbind(cra_bank_county_yr, temp)
}

# Create lagged CRA volume
cra_bank_county_yr <- cra_bank_county_yr %>%
  arrange(RSSD, county_code, year) %>%
  group_by(RSSD, county_code) %>%
  mutate(
    lag_bank_county_cra_volume = lag(loan_amt, 1)
  ) %>% 
  select(-loan_amt, -hmda_id) %>% 
  ungroup() %>% 
  data.table()

# Merge with branch data
branch_df <- merge(branch_df, cra_bank_county_yr, 
                  by.x = c("RSSDID", "yr", "STCNTYBR"), 
                  by.y = c("RSSD", "year", "county_code"), 
                  all.x = TRUE)

# Handle missing values: set to 0 if bank appears in CRA, then add 1 for log
branch_df[, lag_bank_county_cra_volume := 
          ifelse(is.na(lag_bank_county_cra_volume) , 0, lag_bank_county_cra_volume)]
branch_df[, lag_bank_county_cra_volume := lag_bank_county_cra_volume + 1]

# ==============================================================================
# 6. Merge All Data Sources
# ==============================================================================

# Lag zip demographics by 1 year
zip_demo_data[, yr := yr + 1]

# Merge branch data with zip demographics
final_sample <- merge(branch_df, zip_demo_data, 
                      by.x = c("zip", "yr"), 
                      by.y = c("zip", "yr"))

# Ensure STCNTYBR is formatted as 5-digit character string
final_sample[, STCNTYBR := str_pad(STCNTYBR, 5, "left", "0")]

# Merge with county controls
final_sample <- merge(final_sample, county_control_df, 
                      by.x = c("STCNTYBR", "yr"), 
                      by.y = c("county_code", "year"))

# Merge with branch visits
final_sample <- merge(final_sample, branch_visits, 
                      by = "UNINUMBR", all.x = TRUE)

# Merge with bank-level data
final_sample <- merge(final_sample, bank_level_data, 
                      by.x = c("RSSDID", "yr"), 
                      by.y = c("RSSDID", "yr"))


# Sort by branch and year
setorder(final_sample, UNINUMBR, yr)

# Forward fill uninsured deposits fraction within branch
final_sample[, uninsured_deposits_frac := nafill(uninsured_deposits_frac, type = "nocb"), by = UNINUMBR]

# ==============================================================================
# 7. Create Final Variables
# ==============================================================================

final_sample[, college_frac := pct_college_educated / 100]
final_sample[, family_income := median_income]
final_sample[, age := median_age]

# ==============================================================================
# 8. Save Output
# ==============================================================================

saveRDS(final_sample, file = file.path(data_dir, "branch_closure_analysis_sample.rds"))
