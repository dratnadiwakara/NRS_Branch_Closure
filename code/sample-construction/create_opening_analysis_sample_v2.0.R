# ==============================================================================
# Create Branch Opening Analysis Sample 
# ==============================================================================
# Creates a dataset for analyzing branch openings. The sample includes:
# - All bank-zip-year combinations where the bank has CBSA presence but no 
#   existing branches in that zip (potential opening locations)
# - Actual new branch openings are flagged with new_branch_zip = 1
# - Properly handles both: (a) expansion within existing CBSAs, and 
#   (b) entry into new CBSAs
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
setDT(branch_year)

setnames(branch_year, "YEAR", "yr")
branch_year[, zip := str_pad(ZIPBR, 5, "left", "0")]
branch_year[, STCNTYBR := str_pad(STCNTYBR, 5, "left", "0")]

# ==============================================================================
# 2. Identify New Branches
# ==============================================================================

# Flag first year each branch appears in the data
setorder(open_data <- copy(branch_year), UNINUMBR, yr)
open_data[, new_branch := fifelse(is.na(shift(yr)), 1L, 0L), by = UNINUMBR]

# Exclude OTS-to-FDIC regulatory transfers in 2011
# Banks that appear only in 2011 (not 2004-2010) are likely regulatory transfers
banks_with_openings <- open_data[new_branch == 1 & yr %between% c(2004, 2011), 
                                 .(has_opening = 1), 
                                 by = .(RSSDID, yr)]

bank_opening_pattern <- dcast(banks_with_openings, RSSDID ~ yr, 
                              value.var = "has_opening", fill = 0)

# Identify OTS transfer banks: no openings 2004-2010, but openings in 2011
bank_opening_pattern[, no_openings_2004_2010 := 
                       `2004` == 0 & `2005` == 0 & `2006` == 0 & 
                       `2007` == 0 & `2008` == 0 & `2009` == 0 & 
                       `2010` == 0]

ots_transfer_banks <- bank_opening_pattern[
  no_openings_2004_2010 == TRUE & `2011` > 0, 
  RSSDID
]

open_data <- open_data[!RSSDID %in% ots_transfer_banks]

# 
# temp <- open_data[new_branch==1 & yr>1995,.N,by=yr]
# ggplot(temp,aes(x=yr,y=N))+geom_line()
# ==============================================================================
# 3. Load and Prepare Crosswalk Files
# ==============================================================================

# CBSA-County crosswalk
cbsa_county <- fread(file.path(data_dir, "cbsa2fipsxw.csv"))
cbsa_county[, county := paste0(str_pad(fipsstatecode, 2, "left", "0"), 
                               str_pad(fipscountycode, 3, "left", "0"))]
cbsa_county <- unique(cbsa_county[, .(cbsacode, county)])
cbsa_county <- cbsa_county[!duplicated(county)]  # One CBSA per county

# Zip-County crosswalk (keep primary county per zip based on residential ratio)
zip_county <- fread(file.path(data_dir, "ZIP_COUNTY_092020.csv"))
zip_county[, ZIP := str_pad(ZIP, 5, "left", "0")]
zip_county[, COUNTY := str_pad(COUNTY, 5, "left", "0")]
setorder(zip_county, ZIP, -RES_RATIO)
zip_county <- zip_county[!duplicated(ZIP), .(ZIP, COUNTY)]

# Add CBSA to zip-county and deduplicate
zip_county <- merge(zip_county, cbsa_county, by.x = "COUNTY", by.y = "county", all.x = TRUE)
zip_county <- unique(zip_county, by = "ZIP")

# Add CBSA to branch data
open_data <- merge(open_data, cbsa_county, by.x = "STCNTYBR", by.y = "county", all.x = TRUE)

open_data <- open_data[!is.na(cbsacode)]

# ==============================================================================
# 4. Create Reference Tables
# ==============================================================================

# All zips in CBSAs (potential opening locations)
all_zips <- unique(zip_county[!is.na(cbsacode), .(zipcode = ZIP, COUNTY, cbsacode)])

# All bank-year combinations (2000+)
all_bank_yr <- unique(open_data[yr >= 2000, .(RSSDID, yr)])

# Actual new branch openings (2000+)
new_branches <- open_data[yr >= 2000 & new_branch == 1, 
                          .(new_branch_zip = 1), 
                          by = .(RSSDID, zip, yr)]

# Count existing branches by bank-zip-year (for filtering)
existing_branches <- branch_year[, .N, by = .(RSSDID, zip, yr)]
setnames(existing_branches, "N", "n_branches")
existing_branches[, yr := yr + 1]  # Shift to represent previous year

# ==============================================================================
# 5. Identify Bank-CBSA Presence Over Time
# ==============================================================================

# Current year CBSA presence (where bank has branches)
bank_cbsa_current <- unique(open_data[!is.na(cbsacode) & yr >= 2000, 
                                      .(RSSDID, cbsacode, yr)])

# Prior year CBSA presence (lagged for expansion opportunities)
bank_cbsa_prior <- copy(bank_cbsa_current)
bank_cbsa_prior[, yr := yr + 1]

# First year in each CBSA (for new CBSA entry identification)
setorder(bank_cbsa_current, RSSDID, cbsacode, yr)
bank_cbsa_first <- bank_cbsa_current[, .(first_yr = min(yr)), by = .(RSSDID, cbsacode)]

# ==============================================================================
# 6. Create Opportunity Set: Two Scenarios
# ==============================================================================

# SCENARIO A: Expansion within existing CBSAs
# Banks with prior year presence can open in any zip in that CBSA
expansion_opps <- merge(all_bank_yr, bank_cbsa_prior, 
                        by = c("RSSDID", "yr"), 
                        allow.cartesian = TRUE)
expansion_opps <- merge(expansion_opps, all_zips, 
                        by = "cbsacode", 
                        allow.cartesian = TRUE)
expansion_opps[, new_cbsa_entry := 0L]

# SCENARIO B: Entry into new CBSAs
# Banks can enter new CBSAs in the year they first appear there
new_entry_opps <- merge(all_bank_yr, bank_cbsa_first, 
                        by.x = c("RSSDID", "yr"), 
                        by.y = c("RSSDID", "first_yr"))
new_entry_opps <- merge(new_entry_opps, all_zips, 
                        by = "cbsacode", 
                        allow.cartesian = TRUE)
new_entry_opps[, new_cbsa_entry := 1L]

# Combine both scenarios and remove duplicates
bank_zip <- rbindlist(list(expansion_opps, new_entry_opps), use.names = TRUE)
bank_zip <- unique(bank_zip, by = c("RSSDID", "yr", "zipcode"))

rm(expansion_opps, new_entry_opps)
gc()

# ==============================================================================
# 7. Add Actual Openings and Filter to Valid Opportunities
# ==============================================================================

# Merge actual new branch openings
bank_zip <- merge(bank_zip, new_branches, 
                  by.x = c("RSSDID", "yr", "zipcode"), 
                  by.y = c("RSSDID", "yr", "zip"), 
                  all.x = TRUE)
bank_zip[is.na(new_branch_zip), new_branch_zip := 0L]

# Merge existing branch counts (prior year)
bank_zip <- merge(bank_zip, existing_branches, 
                  by.x = c("RSSDID", "yr", "zipcode"), 
                  by.y = c("RSSDID", "yr", "zip"), 
                  all.x = TRUE)
bank_zip[is.na(n_branches), n_branches := 0L]

# Filter: Keep only potential opening locations
# (no existing branches, zip has appeared in branch data at least once)
bank_zip <- bank_zip[n_branches == 0 & zipcode %in% unique(branch_year$zip)]

setkey(bank_zip, zipcode, yr)
gc()

# ==============================================================================
# 8. Add Zip Demographics
# ==============================================================================

zip_demo <- readRDS(file.path(data_dir, "zip_demographics_panel.rds"))
setDT(zip_demo)
setkey(zip_demo, zip, yr)

bank_zip <- merge(bank_zip, zip_demo, 
                  by.x = c("zipcode", "yr"), 
                  by.y = c("zip", "yr"))

# Filter invalid observations and create identifiers
bank_zip <- bank_zip[median_income > 0]
bank_zip[, `:=`(
  bank_yr = paste(RSSDID, yr),
  county_yr = paste(COUNTY, yr),
  factor_age_bin = factor(age_bin)
)]

setkey(bank_zip, NULL)
gc()

# ==============================================================================
# 9. Add County Controls
# ==============================================================================

county_controls <- readRDS(file.path(data_dir, "county_controls_panel_02192026.rds"))
setDT(county_controls)
county_controls <- unique(county_controls, by = c("county_code", "year"))
setkey(county_controls, county_code, year)

setkey(bank_zip, COUNTY, yr)
bank_zip <- merge(bank_zip, county_controls, 
                  by.x = c("COUNTY", "yr"), 
                  by.y = c("county_code", "year"))
setkey(bank_zip, NULL)
gc()

# ==============================================================================
# 10. Add Bank-Level Data
# ==============================================================================

# County-level deposit HHI
county_hhi <- branch_year[, .(deposits = sum(DEPSUMBR, na.rm = TRUE)), 
                          by = .(RSSDID, STCNTYBR, yr)]
county_hhi[, total_county_dep := sum(deposits), by = .(STCNTYBR, yr)]
county_hhi[, share_sq := (deposits / total_county_dep)^2]
county_hhi <- county_hhi[, .(county_hhi = sum(share_sq)), by = .(STCNTYBR, yr)]

# Bank-level weighted HHI (weighted by bank's deposit share in each county)
bank_county_dep <- branch_year[, .(bank_county_dep = sum(DEPSUMBR)), 
                               by = .(RSSDID, STCNTYBR, yr)]
bank_county_dep[, bank_total_dep := sum(bank_county_dep), by = .(RSSDID, yr)]
bank_county_dep[, weight := bank_county_dep / bank_total_dep]
bank_county_dep <- merge(bank_county_dep, county_hhi, by = c("STCNTYBR", "yr"))
bank_hhi <- bank_county_dep[, .(bank_hhi = sum(weight * county_hhi)), by = .(RSSDID, yr)]

# Load and prepare call report data
call_data <- readRDS(file.path(data_dir, "call_data_02172026.rds"))
setDT(call_data)
setnames(call_data, "total_assets", "bank_assets")
call_data[, `:=`(
  yr = year(D_DT),
  month = month(D_DT)
)]
call_data <- call_data[month == 12]

call_data[, ci_assets := ci_loans/bank_assets]
call_data[, uninsured_deposits_frac := deposits_uninsured/(deposits_uninsured + deposits_insured)]

call_data[,core_deposits_assets:=core_deposits/bank_assets]
call_data[,time_deposits_assets:=(time_deposits_below_ins_limit+time_deposits_above_ins_limit)/bank_assets]
call_data[,brokered_deposits_assets:=brokered_deposits/bank_assets]

# Winsorize ratio variables at 1 (max)
call_data[, ci_assets := pmin(ci_assets, 1)]
call_data[, uninsured_deposits_frac := pmin(uninsured_deposits_frac, 1)]
call_data[, core_deposits_assets := pmin(core_deposits_assets, 1)]
call_data[, time_deposits_assets := pmin(time_deposits_assets, 1)]
call_data[, brokered_deposits_assets := pmin(brokered_deposits_assets, 1)]


# Fill forward uninsured deposits fraction where missing
call_data <- call_data[, .(yr, ID_RSSD, trans_accts_frac_assets, ci_assets, 
                                 bank_assets, uninsured_deposits_frac, core_deposits_assets,
                                 time_deposits_assets, brokered_deposits_assets)]
setorder(call_data, ID_RSSD, yr)

# Forward fill uninsured deposits fraction
call_data[, uninsured_deposits_frac := nafill(uninsured_deposits_frac, type = "nocb"), by = ID_RSSD]
call_data[, brokered_deposits_assets := nafill(brokered_deposits_assets, type = "nocb"), by = ID_RSSD]
call_data[, core_deposits_assets := nafill(core_deposits_assets, type = "nocb"), by = ID_RSSD]
call_data[, time_deposits_assets := nafill(time_deposits_assets, type = "nocb"), by = ID_RSSD]
call_data[, trans_accts_frac_assets := nafill(trans_accts_frac_assets, type = "nocb"), by = ID_RSSD]
call_data[, ci_assets := nafill(ci_assets, type = "nocb"), by = ID_RSSD]


# Merge bank-level data
bank_level <- merge(bank_hhi, call_data, 
                    by.x = c("RSSDID", "yr"), 
                    by.y = c("ID_RSSD", "yr"), 
                    all.x = TRUE)

setkey(bank_level, RSSDID, yr)
setkey(bank_zip, RSSDID, yr)
bank_zip <- merge(bank_zip, bank_level, by = c("RSSDID", "yr"))
bank_zip <- bank_zip[!is.na(bank_assets)]  # Require valid bank data
setkey(bank_zip, NULL)
gc()

# ==============================================================================
# 11. Add Zip-Level Deposits
# ==============================================================================

zip_deposits <- branch_year[, .(zip_deposits = sum(DEPSUMBR, na.rm = TRUE)), 
                            by = .(zip, yr)]
setkey(zip_deposits, zip, yr)
setkey(bank_zip, zipcode, yr)

bank_zip <- merge(bank_zip, zip_deposits, 
                  by.x = c("zipcode", "yr"), 
                  by.y = c("zip", "yr"), 
                  all.x = TRUE)
bank_zip[is.na(zip_deposits) | zip_deposits == 0, zip_deposits := 1]
bank_zip[, log_zip_deposits := log(zip_deposits)]
setkey(bank_zip, NULL)
gc()

# ==============================================================================
# 12. Add County-Level HMDA and CRA Volumes
# ==============================================================================

# Helper function to backfill and forward-fill county-level data
backfill_county_data <- function(dt, value_col, lag_col) {
  # Create lagged values
  setorder(dt, county_code, year)
  dt[, (lag_col) := shift(get(value_col)), by = county_code]
  result <- dt[, .(county_code, year, get(lag_col))]
  setnames(result, "V3", lag_col)
  
  # Backfill 2000: Use 2001 actual as lag for 2000
  fill_2000 <- dt[year == 2001, .(county_code, year = 2000, fill_val = get(value_col))]
  setnames(fill_2000, "fill_val", lag_col)
  result <- rbindlist(list(result, fill_2000), use.names = TRUE)
  
  # Backfill 2001-2004: Use 2005's lag value (which is from 2004)
  fill_template <- result[year == 2005]
  fill_early <- rbindlist(lapply(2001:2004, function(y) {
    temp <- copy(fill_template)
    temp[, year := y]
    temp
  }))
  result <- rbindlist(list(result, fill_early), use.names = TRUE)
  
  # Forward-fill 2024-2025: Use 2023's lag value (which is from 2022)
  fill_template_late <- result[year == 2023]
  if (nrow(fill_template_late) > 0) {
    fill_late <- rbindlist(lapply(2024:2025, function(y) {
      temp <- copy(fill_template_late)
      temp[, year := y]
      temp
    }))
    result <- rbindlist(list(result, fill_late), use.names = TRUE)
  }
  
  # Remove duplicates and return
  unique(result, by = c("county_code", "year"))
}

# HMDA county-level mortgage volume
hmda <- readRDS(file.path(data_dir, "hmda_bank_county_yr.rds"))
setDT(hmda)
hmda_county <- hmda[, .(mortgage_vol = sum(bank_county_mortgage_volume, na.rm = TRUE)), 
                    by = .(county_code, year)]
hmda_county <- backfill_county_data(hmda_county, "mortgage_vol", "lag_county_mortgage_volume")

setkey(hmda_county, county_code, year)
setkey(bank_zip, COUNTY, yr)
bank_zip <- merge(bank_zip, hmda_county, 
                  by.x = c("COUNTY", "yr"), 
                  by.y = c("county_code", "year"), 
                  all.x = TRUE)
bank_zip[is.na(lag_county_mortgage_volume), lag_county_mortgage_volume := 0]

# CRA county-level small business lending
cra <- readRDS(file.path(data_dir, "cra_bank_county_yr.rds"))
setDT(cra)
cra_county <- cra[, .(cra_vol = sum(loan_amt, na.rm = TRUE)), 
                  by = .(county_code, year)]
cra_county <- backfill_county_data(cra_county, "cra_vol", "lag_county_cra_volume")

setkey(cra_county, county_code, year)
setkey(bank_zip, COUNTY, yr)
bank_zip <- merge(bank_zip, cra_county, 
                  by.x = c("COUNTY", "yr"), 
                  by.y = c("county_code", "year"), 
                  all.x = TRUE)
bank_zip[is.na(lag_county_cra_volume), lag_county_cra_volume := 0]

setkey(bank_zip, NULL)
gc()

# ==============================================================================
# 13. Final Cleanup and Save
# ==============================================================================

# Remove intermediate columns if needed
bank_zip[, c("n_branches") := NULL]

# Save the final dataset
saveRDS(bank_zip, file.path(data_dir, "temp_branch_opening_analysis_sample.rds"))

message("Dataset creation complete!")
message("Final observations: ", nrow(bank_zip))
message("New branch openings: ", sum(bank_zip$new_branch_zip))
message("New CBSA entries: ", sum(bank_zip$new_cbsa_entry))

rm(list=ls())
library(data.table)
library(dplyr)

data_dir <- "C:/OneDrive/data/nrs_branch_closure"

bank_zip <- readRDS(file.path(data_dir, "temp_branch_opening_analysis_sample.rds"))

# Filter observations
bank_zip <- bank_zip[!is.na(sophisticated)]
bank_zip <- bank_zip[yr %in% 2000:2025]
bank_zip <- bank_zip[!is.na(trans_accts_frac_assets)]
setnames(bank_zip,c("median_income","pct_college_educated"),c("family_income","college_frac"))
bank_zip[,college_frac:=college_frac/100]


# Load deposit beta models
beta_cycles <- readRDS(file.path(data_dir, "deposit_beta_results_v02172026.rds"))



cat("Predicting deposit betas...\n")

# Split bank_zip by time period to match beta cycles
setindex(bank_zip,yr)
bank_zip_early <- bank_zip[yr <= 2014]  # Use 2004-2006 cycle
bank_zip_mid <- bank_zip[yr > 2014 & yr <= 2019]  # Use 2016-2019 cycle
bank_zip_late <- bank_zip[yr > 2019]  # Use 2022-2024 cycle
rm(bank_zip)
gc()

# Process each period separately
cat("  Processing early period (yr <= 2014)...\n")
cycle_data <- beta_cycles[["cycle_0406"]]$data
bank_zip_early[, pred_int_exp_chg_cycle_0406 := predict(
  beta_cycles[["cycle_0406"]]$reg, 
  newdata = bank_zip_early
)]
bank_zip_early[, deposit_beta := pred_int_exp_chg_cycle_0406 / 3.5]
bank_zip_early[, pred_int_exp_chg_cycle_0406 := NULL]  # Remove to save memory
gc()

cat("  Processing mid period (2015-2019)...\n")
cycle_data <- beta_cycles[["cycle_1619"]]$data
bank_zip_mid[, pred_int_exp_chg_cycle_1619 := predict(
  beta_cycles[["cycle_1619"]]$reg, 
  newdata = bank_zip_mid
)]
bank_zip_mid[, deposit_beta := pred_int_exp_chg_cycle_1619 / 2.5]
bank_zip_mid[, pred_int_exp_chg_cycle_1619 := NULL]
gc()

cat("  Processing late period (yr > 2019)...\n")
cycle_data <- beta_cycles[["cycle_2224"]]$data
bank_zip_late[, pred_int_exp_chg_cycle_2224 := predict(
  beta_cycles[["cycle_2224"]]$reg, 
  newdata = bank_zip_late
)]
bank_zip_late[, deposit_beta := pred_int_exp_chg_cycle_2224 / 4.0]
bank_zip_late[, pred_int_exp_chg_cycle_2224 := NULL]
gc()

# Recombine the datasets
cat("  Combining periods...\n")
bank_zip <- rbindlist(list(bank_zip_early, bank_zip_mid, bank_zip_late), 
                      use.names = TRUE, fill = TRUE)

# Clean up
rm(bank_zip_early, bank_zip_mid, bank_zip_late)
gc()

output_path <- file.path(data_dir, "branch_opening_analysis_sample_with_deposit_beta_v3.rds")
saveRDS(bank_zip, output_path)

cat("Deposit beta prediction complete.\n")



library(data.table)

n_parts <- 6L
n <- nrow(bank_zip)

base <- n %/% n_parts
rem  <- n %%  n_parts
sizes <- base + as.integer(seq_len(n_parts) <= rem)

starts <- cumsum(c(1L, head(sizes, -1L)))
ends   <- cumsum(sizes)

for (i in 1:n_parts) {
  fn <- file.path(data_dir,sprintf("dt_part_%02d_of_%02d.rds", i, n_parts))
  saveRDS(bank_zip[starts[i]:ends[i]], file = fn)
}


