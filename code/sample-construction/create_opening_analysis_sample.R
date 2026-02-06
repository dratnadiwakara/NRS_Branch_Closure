# ==============================================================================
# Create Branch Opening Analysis Sample
# ==============================================================================
# Creates a dataset for analyzing branch openings. The sample includes:
# - All bank-zip-year combinations where the bank has CBSA presence but no 
#   existing branches in that zip (potential opening locations)
# - Actual new branch openings are flagged with new_branch_zip = 1
# ==============================================================================

rm(list = ls())

library(data.table)
library(dplyr)
library(stringr)
library(DescTools)
library(zipcodeR)
library(tidycensus)

data_dir <- "C:/OneDrive/data/nrs_branch_closure"

# ==============================================================================
# 1. Load and Prepare Branch Data
# ==============================================================================

branch_year <- readRDS('C:/OneDrive/data/fdic_sod_1995_2025_simple.rds')
branch_year <- data.table(branch_year)

setnames(branch_year, "YEAR", "yr")
branch_year[, zip := str_pad(ZIPBR, 5, "left", "0")]
branch_year[, STCNTYBR := str_pad(STCNTYBR, 5, "left", "0")]

# ==============================================================================
# 2. Identify New Branches
# ==============================================================================

# Flag first year each branch appears in the data
open_data <- branch_year %>%
  arrange(UNINUMBR, yr) %>%
  group_by(UNINUMBR) %>%
  mutate(new_branch = ifelse(is.na(lag(yr)), 1, 0)) %>%
  ungroup() %>% 
  data.table()

# Exclude OTS-to-FDIC regulatory transfers
# In 2011, OTS was merged into FDIC. Some banks appear for the first time in 2011
# not because they're truly new, but because they switched regulators.
# We identify these as banks with new branches in 2011 but no new branches 2004-2010.
banks_with_openings <- open_data[new_branch == 1 & yr %in% 2004:2011, 
                                 .(has_opening = 1), 
                                 by = .(RSSDID, yr)]

# Check if banks have openings in 2011 but not in 2004-2010
bank_opening_pattern <- dcast(banks_with_openings, RSSDID ~ yr, 
                              value.var = "has_opening", fill = 0)

ots_transfer_banks <- bank_opening_pattern[`2004` == 0 & `2005` == 0 & `2006` == 0 & 
                                           `2007` == 0 & `2008` == 0 & `2009` == 0 & 
                                           `2010` == 0 & `2011` > 0]$RSSDID

open_data <- open_data[!RSSDID %in% ots_transfer_banks]

# temp <- open_data[new_branch==1 & yr>1995,.N,by=yr]
# ggplot(temp,aes(x=yr,y=N))+geom_line()

# ==============================================================================
# 3. Load Crosswalk Files
# ==============================================================================

# CBSA-County crosswalk
cbsa_county <- fread(file.path(data_dir, "cbsa2fipsxw.csv"))
cbsa_county[, county := paste0(str_pad(fipsstatecode, 2, "left", "0"), 
                               str_pad(fipscountycode, 3, "left", "0"))]
cbsa_county <- unique(cbsa_county[, .(cbsacode, county)])

# Zip-County crosswalk (keep primary county for each zip)
zip_county <- fread(file.path(data_dir, "ZIP_COUNTY_092020.csv"))
setorder(zip_county, ZIP, -RES_RATIO)
zip_county <- zip_county[!duplicated(ZIP), .(ZIP, COUNTY)]
zip_county[, ZIP := str_pad(ZIP, 5, "left", "0")]
zip_county[, COUNTY := str_pad(COUNTY, 5, "left", "0")]

# Add CBSA to zip-county
zip_county <- merge(zip_county, cbsa_county, by.x = "COUNTY", by.y = "county", all.x = TRUE)

# Add CBSA to branch data
open_data <- merge(open_data, cbsa_county, by.x = "STCNTYBR", by.y = "county", all.x = TRUE)

# ==============================================================================
# 4. Identify Bank-CBSA Presence by Year
# ==============================================================================

# Get unique bank-CBSA-year combinations (banks operating in each CBSA)
bank_cbsa_yr <- unique(open_data[!is.na(cbsacode), .(RSSDID, cbsacode, yr)])
bank_cbsa_yr[, yr := yr + 1]  # Shift to represent "previous year presence"
setnames(bank_cbsa_yr, "yr", "yr")

# ==============================================================================
# 5. Create All Possible Bank-Zip-Year Combinations
# ==============================================================================

# Get all zips in CBSAs
all_zips <- zip_county[!is.na(cbsacode), .(zipcode = ZIP, COUNTY, cbsacode)]

# Get all bank-year combinations
all_bank_yr <- unique(open_data[yr >= 1999, .(RSSDID, yr)])

# Create bank-zip-year combinations for banks with CBSA presence
# Join banks to CBSAs they operate in, then to all zips in those CBSAs
bank_zip <- merge(all_bank_yr, bank_cbsa_yr, by = c("RSSDID", "yr"), allow.cartesian = TRUE)
bank_zip <- merge(bank_zip, all_zips, by = "cbsacode", allow.cartesian = TRUE)
gc()

# ==============================================================================
# 6. Add Actual Branch Openings and Filter
# ==============================================================================

# Count new branches by bank-zip-year
new_branches <- open_data[yr >= 1999 & new_branch == 1, 
                          .(new_branch_zip = 1), 
                          by = .(RSSDID, zip, yr)]

# Merge actual openings
bank_zip <- merge(bank_zip, new_branches, 
                  by.x = c("RSSDID", "yr", "zipcode"), 
                  by.y = c("RSSDID", "yr", "zip"), 
                  all.x = TRUE)
bank_zip[is.na(new_branch_zip), new_branch_zip := 0]

# Count existing branches by bank-zip in previous year
existing_branches <- branch_year[, .(n_branches = .N), by = .(RSSDID, zip, yr)]
existing_branches[, yr := yr + 1]  # Shift to represent previous year

bank_zip <- merge(bank_zip, existing_branches, 
                  by.x = c("RSSDID", "yr", "zipcode"), 
                  by.y = c("RSSDID", "yr", "zip"), 
                  all.x = TRUE)
bank_zip[is.na(n_branches), n_branches := 0]

# Keep only zips where bank has no existing branches (potential opening locations)
bank_zip <- bank_zip[n_branches == 0]
bank_zip <- bank_zip[zipcode %in% unique(branch_year$zip)]
setindex(bank_zip,zipcode,yr)
gc()

# ==============================================================================
# 7. Add Zip Demographics
# ==============================================================================

zip_demo <- readRDS(file.path(data_dir, "zip_demographics_panel.rds"))
setindex(zip_demo,zip,yr)

bank_zip <- merge(bank_zip, zip_demo, 
                  by.x = c("zipcode", "yr"), by.y = c("zip", "yr"))
setindex(bank_zip,NULL)

# Filter out invalid observations
bank_zip <- bank_zip[median_income > 0]

# Create fixed effect identifiers
bank_zip[, bank_yr := paste(RSSDID, yr)]
bank_zip[, county_yr := paste(COUNTY, yr)]
bank_zip[, factor_age_bin := factor(age_bin)]
gc()
# ==============================================================================
# 8. Add County Controls
# ==============================================================================

county_controls <- readRDS(file.path(data_dir, "county_controls_panel.rds"))
county_controls <- unique(county_controls,by=c("county_code", "year"))
setindex(county_controls,county_code,year)

setindex(bank_zip,COUNTY,yr)
bank_zip <- merge(bank_zip, county_controls, 
                  by.x = c("COUNTY", "yr"), by.y = c("county_code", "year"), 
                  all.x = TRUE)
setindex(bank_zip,NULL)
gc()

# ==============================================================================
# 9. Add Bank-Level Data
# ==============================================================================
# Bank-level weighted HHI (weighted average of county-level HHI by deposit share)

# County-level deposit HHI
county_hhi <- branch_year[, .(deposits = sum(DEPSUMBR, na.rm = TRUE)), 
                          by = .(RSSDID, STCNTYBR, yr)]
county_hhi[, total_county_dep := sum(deposits), by = .(STCNTYBR, yr)]
county_hhi[, share_sq := (deposits / total_county_dep)^2]
county_hhi <- county_hhi[, .(county_hhi = sum(share_sq)), by = .(STCNTYBR, yr)]

# Bank deposits by county
bank_county_dep <- branch_year[, .(bank_county_dep = sum(DEPSUMBR)), 
                               by = .(RSSDID, STCNTYBR, yr)]
bank_county_dep[, bank_total_dep := sum(bank_county_dep), by = .(RSSDID, yr)]
bank_county_dep[, weight := bank_county_dep / bank_total_dep]

# Weighted bank HHI
bank_county_dep <- merge(bank_county_dep, county_hhi, by = c("STCNTYBR", "yr"))
bank_hhi <- bank_county_dep[, .(bank_hhi = sum(weight * county_hhi)), by = .(RSSDID, yr)]

# Load call report data
call_data <- readRDS(file.path(data_dir, "call_data_01282026.rds"))
setnames(call_data, "total_assets", "bank_assets")
call_data[, yr := year(D_DT)]
call_data[, month := month(D_DT)]
call_data <- call_data[month == 12]
call_data[, ci_assets := ci_loans/bank_assets]
call_data[, uninsured_deposits_frac := deposits_uninsured/(deposits_uninsured + deposits_insured)]

call_data <- call_data[, .(ID_RSSD, yr, bank_assets, trans_accts_frac_assets, 
                           ci_assets, uninsured_deposits_frac)]
setorder(call_data, ID_RSSD, yr)
call_data[, uninsured_deposits_frac := nafill(uninsured_deposits_frac, type = "nocb"), 
          by = ID_RSSD]

# Merge bank-level data
bank_level <- merge(bank_hhi, call_data, 
                    by.x = c("RSSDID", "yr"), by.y = c("ID_RSSD", "yr"), 
                    all.x = TRUE)
setindex(bank_level,RSSDID,yr)
setindex(bank_zip,RSSDID,yr)
bank_zip <- merge(bank_zip, bank_level, by = c("RSSDID", "yr"))
bank_zip <- bank_zip[!is.na(bank_assets)]
setindex(bank_zip,NULL)
gc()
# ==============================================================================
# 10. Add Zip-Level Deposits
# ==============================================================================

zip_deposits <- branch_year[, .(zip_deposits = sum(DEPSUMBR, na.rm = TRUE)), by = .(zip, yr)]
setindex(zip_deposits,zip,yr)
setindex(bank_zip,zipcode,yr)

bank_zip <- merge(bank_zip, zip_deposits, 
                  by.x = c("zipcode", "yr"), by.y = c("zip", "yr"), 
                  all.x = TRUE)
bank_zip[is.na(zip_deposits) | zip_deposits == 0, zip_deposits := 1]
bank_zip[, log_zip_deposits := log(zip_deposits)]
setindex(bank_zip,NULL)
gc()

# ==============================================================================
# 11. Add County-Level HMDA and CRA Volumes
# ==============================================================================

# # HMDA county-level mortgage volume
# hmda <- readRDS(file.path(data_dir, "hmda_bank_county_yr.rds"))
# hmda_county <- hmda[, .(mortgage_vol = sum(bank_county_mortgage_volume, na.rm = TRUE)), 
#                     by = .(county_code, year)]
# hmda_county <- hmda_county %>%
#   arrange(county_code, year) %>%
#   group_by(county_code) %>%
#   mutate(lag_county_mortgage_vol = lag(mortgage_vol)) %>%
#   ungroup() %>%
#   select(county_code, year, lag_county_mortgage_vol) %>%
#   data.table()
# 
# # Backfill 2000-2003
# hmda_2004 <- hmda_county[year == 2005]  # 2005 has lag from 2004
# for (y in 2001:2004) {
#   temp <- copy(hmda_2004)
#   temp[, year := y]
#   hmda_county <- rbind(hmda_county, temp)
# }
# 
# bank_zip <- merge(bank_zip, hmda_county, 
#                   by.x = c("COUNTY", "yr"), by.y = c("county_code", "year"), 
#                   all.x = TRUE)
# bank_zip[is.na(lag_county_mortgage_vol), lag_county_mortgage_vol := 0]
# 
# # CRA county-level small business lending
# cra <- readRDS(file.path(data_dir, "cra_bank_county_yr.rds"))
# cra_county <- cra[, .(cra_vol = sum(loan_amt, na.rm = TRUE)), by = .(county_code, year)]
# cra_county <- cra_county %>%
#   arrange(county_code, year) %>%
#   group_by(county_code) %>%
#   mutate(lag_county_cra_vol = lag(cra_vol)) %>%
#   ungroup() %>%
#   select(county_code, year, lag_county_cra_vol) %>%
#   data.table()
# 
# # Backfill 2000-2003
# cra_2004 <- cra_county[year == 2005]
# for (y in 2001:2004) {
#   temp <- copy(cra_2004)
#   temp[, year := y]
#   cra_county <- rbind(cra_county, temp)
# }
# 
# bank_zip <- merge(bank_zip, cra_county, 
#                   by.x = c("COUNTY", "yr"), by.y = c("county_code", "year"), 
#                   all.x = TRUE)
# bank_zip[is.na(lag_county_cra_vol), lag_county_cra_vol := 0]

# ==============================================================================
# 12. Add Deposit Betas and Final Cleanup
# ==============================================================================

# Remove temporary columns
bank_zip[, n_branches := NULL]

# Load deposit beta models
beta_cycles <- readRDS(file.path(data_dir, "deposit_beta_results.rds"))

# Load CPI data to define large banks
cpi <- readRDS(file.path(data_dir, "cpi.rds"))
cpi[, adj_ratio := CPI / CPI[year == 2024]]
cpi[, asset_cutoff := adj_ratio * 100000000]

all_banks <- rbindlist(lapply(names(beta_cycles), function(cycle_name) {
  dt <- copy(beta_cycles[[cycle_name]]$data)
  dt[, cycle := cycle_name]
  dt[, year := ifelse(cycle == "cycle_0406", 2006,
                      ifelse(cycle == "cycle_1619", 2019, 2023))]
  dt
}))
all_banks <- merge(all_banks, cpi[, .(year, asset_cutoff)], by = "year", all.x = TRUE)
large_banks <- unique(all_banks[bank_assets > asset_cutoff]$ID_RSSD)

# Add large_bank indicator
bank_zip[, large_bank := fifelse(RSSDID %in% large_banks, 1L, 0L)]

# Filter observations
bank_zip <- bank_zip[!is.na(sophisticated)]
bank_zip <- bank_zip[yr %in% 2000:2025]
bank_zip <- bank_zip[!is.na(trans_accts_frac_assets)]
gc()

cat("Predicting deposit betas...\n")

# Predict deposit expense changes for each cycle
for (i in 1:length(beta_cycles)) {
  cat("  Cycle", i, "of", length(beta_cycles), "...\n")
  cycle_nm <- names(beta_cycles)[i]
  bank_zip[, pred_int_exp_chg := predict(beta_cycles[[i]]$reg, newdata = bank_zip)]
  setnames(bank_zip, "pred_int_exp_chg", paste0("pred_int_exp_chg_", cycle_nm))
  gc()
}

# Calculate deposit beta based on the rate cycle
bank_zip[, deposit_beta := fifelse(
  yr <= 2014,
  pred_int_exp_chg_cycle_0406 / 3.5,
  fifelse(
    yr <= 2019,
    pred_int_exp_chg_cycle_1619 / 2.5,
    pred_int_exp_chg_cycle_2224 / 4.0
  )
)]

# Calculate deposit franchise value per dollar
bank_zip[, df_per_dollar := (1 - deposit_beta) * (1 - (1 / (1.025)^10))]

# Create deposit beta deciles
bank_zip[, beta_decile_within_bank := dplyr::ntile(deposit_beta, 10), by = .(RSSDID, yr)]
bank_zip[, beta_decile_within_year := dplyr::ntile(deposit_beta, 10), by = yr]

# Handle missing values in county lending volumes
bank_zip[is.na(lag_county_mortgage_volume), lag_county_mortgage_volume := 0]
bank_zip[is.na(lag_county_cra_volume), lag_county_cra_volume := 0]
bank_zip[, lag_county_mortgage_volume := lag_county_mortgage_volume + 1]
bank_zip[, lag_county_cra_volume := lag_county_cra_volume + 1]

# Save final sample with deposit betas
output_path <- file.path(data_dir, "branch_opening_analysis_sample_with_beta.rds")
saveRDS(bank_zip, output_path)

cat("\nBranch opening analysis sample created successfully!\n")
cat("Output:", output_path, "\n")
cat("Observations:", format(nrow(bank_zip), big.mark = ","), "\n")
cat("Years:", min(bank_zip$yr), "-", max(bank_zip$yr), "\n")
cat("Actual openings:", format(sum(bank_zip$new_branch_zip), big.mark = ","), "\n")
cat("Opening rate:", sprintf("%.4f%%", 100 * mean(bank_zip$new_branch_zip)), "\n")
