# ==============================================================================
# Calculate Deposit Betas During Interest Rate Cycles
# ==============================================================================
# Deposit beta = change in deposit expense / change in Fed Funds rate
# This measures how sensitive banks' deposit costs are to interest rate changes
# ==============================================================================

rm(list=ls())

library(data.table)
library(dplyr)
library(fixest)
library(lubridate)

data_dir <- "C:/OneDrive/data/nrs_branch_closure"

# ==============================================================================
# 1. Load Data
# ==============================================================================

# Branch analysis sample (created by create_closure_analysis_sample.R)
branch_df <- readRDS(file.path(data_dir, "branch_closure_analysis_sample_02172026.rds"))

# Call report data with deposit expense ratios
call_data <- readRDS(file.path(data_dir, "call_data_02172026.rds"))

# Replace missing values with closest available value after current date (backward fill) per bank
setDT(call_data)
call_data[, D_DT := as.Date(D_DT)]
setorder(call_data, ID_RSSD, D_DT)
cols_na <- names(call_data)[sapply(call_data, function(x) any(is.na(x)))]
for (col in cols_na) {
  if (is.numeric(call_data[[col]])) {
    call_data[, (col) := nafill(get(col), type = "nocb"), by = ID_RSSD]
  }
}


# ==============================================================================
# 2. Aggregate Branch Demographics to Bank Level (Deposit-Weighted)
# ==============================================================================

aggregate_bank_demographics <- function(data, yr_filter) {
  
  dt <- data[yr == yr_filter]
  
  # Deposit weights within each bank
  dt[, deposit_weight := DEPSUMBR / sum(DEPSUMBR, na.rm = TRUE), by = RSSDID]
  
  # Weighted aggregation to bank level
  bank_agg <- dt[, .(
    college_frac = sum(college_frac * deposit_weight, na.rm = TRUE) + 0.01,
    dividend_frac = sum(dividend_frac * deposit_weight, na.rm = TRUE) + 0.01,
    family_income = sum(family_income * deposit_weight, na.rm = TRUE) + 1,
    population_density = sum(population_density * deposit_weight, na.rm = TRUE),
    age = sum(age * deposit_weight, na.rm = TRUE),
    age_bin = floor(median(age_bin, na.rm = TRUE)),
    sophisticated_frac = sum(sophisticated * deposit_weight, na.rm = TRUE),
    # Bank-level vars (already constant within bank-year, just take first)
    bank_hhi = first(bank_hhi),
    bank_assets = first(bank_assets),
    trans_accts_frac_assets = first(trans_accts_frac_assets),
    core_deposits_assets = first(core_deposits_assets),
    time_deposits_assets = first(time_deposits_assets),
    ci_assets = first(ci_assets),
    brokered_deposits_assets = first(brokered_deposits_assets),
    uninsured_deposits_frac = first(uninsured_deposits_frac)
  ), by = RSSDID]
  
  bank_agg[, factor_age_bin := factor(age_bin)]
  
  return(bank_agg)
}

# ==============================================================================
# 3. Calculate Deposit Beta for a Rate Cycle
# ==============================================================================

calculate_cycle_beta <- function(call_data, bank_demos, start_date, end_date) {
  
  # Get deposit expense at start and end of cycle
  cycle_data <- call_data[D_DT %in% c(start_date, end_date)]
  
  # Reshape wide: one row per bank with start/end values
  cycle_wide <- dcast(cycle_data, ID_RSSD ~ D_DT, value.var = "deposit_exp_deposits")
  setnames(cycle_wide, c("ID_RSSD", "dep_exp_start", "dep_exp_end"))
  
  # Change in deposit expense ratio
  cycle_wide[, deposit_exp_chg := dep_exp_end - dep_exp_start]
  cycle_wide <- cycle_wide[!is.na(deposit_exp_chg)]
  
  # Winsorize at 2/98 percentiles
  q02 <- quantile(cycle_wide$deposit_exp_chg, 0.01, na.rm = TRUE)
  q98 <- quantile(cycle_wide$deposit_exp_chg, 0.99, na.rm = TRUE)
  cycle_wide <- cycle_wide[deposit_exp_chg > q02 & deposit_exp_chg < q98]
  
  # Merge with bank demographics
  merged <- merge(cycle_wide[, .(ID_RSSD, deposit_exp_chg)], 
                  bank_demos, 
                  by.x = "ID_RSSD", by.y = "RSSDID")
  
  return(merged)
}

# ==============================================================================
# 4. Define Interest Rate Hiking Cycles
# ==============================================================================

cycles <- list(
  # 2004-2006: Fed Funds 1% -> 4.5% (+3.5pp)
  # Note: Using 2012 demographics since zip data backfilled from 2010
  cycle_0406 = list(
    start_date = as.Date("2004-03-31"),
    end_date = as.Date("2006-03-31"),
    rate_change = 3.5,
    demo_year = 2012
  ),
  # 2016-2019: Fed Funds 0.25% -> 2.75% (+2.5pp)
  cycle_1619 = list(
    start_date = as.Date("2016-03-31"),
    end_date = as.Date("2019-03-31"),
    rate_change = 2.5,
    demo_year = 2019
  ),
  # 2022-2023: Fed Funds 0.25% -> 4.25% (+4pp)
  cycle_2224 = list(
    start_date = as.Date("2022-03-31"),
    end_date = as.Date("2023-03-31"),
    rate_change = 4.0,
    demo_year = 2019
  )
)

# ==============================================================================
# 5. Run Analysis for Each Cycle
# ==============================================================================

results <- list()

for(cycle_name in names(cycles)) {

  # cycle_name = 'cycle_0406'
  
  cycle <- cycles[[cycle_name]]
  cat("\n", cycle_name, ": ", as.character(cycle$start_date), " to ", as.character(cycle$end_date), "\n", sep = "")
  
  # Aggregate demographics for this cycle's base year
  bank_demos <- aggregate_bank_demographics(branch_df, cycle$demo_year)
  
  # Calculate deposit expense changes
  cycle_data <- calculate_cycle_beta(call_data, bank_demos, cycle$start_date, cycle$end_date)
  
  # Deposit beta = change in deposit expense / change in rates
  cycle_data[, deposit_beta := deposit_exp_chg / cycle$rate_change]
  
  # Regression: demographics -> deposit beta
  # reg <- feols(
  #   deposit_exp_chg ~ factor_age_bin + log(family_income) + dividend_frac + college_frac +
  #     bank_hhi + log(bank_assets) + population_density + trans_accts_frac_assets + uninsured_deposits_frac,
  #   data = cycle_data,
  # )
  reg <- feols(
    deposit_exp_chg ~ factor_age_bin + dividend_frac + college_frac +  log(family_income) +
      bank_hhi + log(bank_assets) + population_density + trans_accts_frac_assets + 
      uninsured_deposits_frac + time_deposits_assets,
    data = cycle_data,
  )
  
  # Regression: sophistication -> deposit beta
  reg_soph <- feols(
    deposit_exp_chg ~ sophisticated_frac + factor_age_bin +  log(family_income) +
      bank_hhi + log(bank_assets) + population_density + trans_accts_frac_assets + 
      uninsured_deposits_frac + time_deposits_assets,
    data = cycle_data
  )
  
  results[[cycle_name]] <- list(
    data = cycle_data,
    reg = reg,
    reg_sophisticated = reg_soph
  )
  
  cat("  N =", nrow(cycle_data), ", Mean beta =", round(mean(cycle_data$deposit_beta, na.rm = TRUE), 4), "\n")
}

# ==============================================================================
# 6. Save Results
# ==============================================================================

saveRDS(results, file = file.path(data_dir, "deposit_beta_results_v02172026.rds"))

etable(results$cycle_0406$reg,results$cycle_1619$reg,results$cycle_2224$reg)
etable(results$cycle_0406$reg_soph,results$cycle_1619$reg_soph,results$cycle_2224$reg_soph)
