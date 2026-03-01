################################################################################
# DEPOSIT RATE SENSITIVITY ANALYSIS
# 
# PURPOSE: Compare how banks adjust deposit rates in response to Fed rate changes
# 
# APPROACH:
# 1. Calculate "deposit betas" from RateWatch data (how much banks change rates)
# 2. Compare with estimated deposit betas from branch-level analysis
# 3. Visualize the relationship across different time periods
#
# KEY CONCEPT: Deposit Beta = Change in Bank Rate / Change in Fed Funds Rate
#              Beta = 1.0 means bank passes through 100% of Fed rate changes
#              Beta = 0.5 means bank passes through 50% of Fed rate changes
################################################################################

# Setup -------------------------------------------------------------------------
rm(list = ls())

library(data.table)
library(ggplot2)
library(fixest)
library(gridExtra)

################################################################################
# STEP 1: LOAD DATA
################################################################################

# Branch-level data with previously estimated deposit betas
branch_betas <- readRDS("data/branch_closure_analysis_sample_with_beta_02242026.rds")

# CPI data for inflation adjustment
cpi <- readRDS(file.path("data", "cpi.rds"))
cpi[, adj_ratio := CPI / CPI[year == 2024]]
cpi[, asset_cutoff := adj_ratio * 100000000]

# Identify large banks (above $100M in 2024 dollars)
all_banks <- unique(branch_betas[, .(RSSDID, yr, bank_assets)])
all_banks <- merge(all_banks, cpi[, .(year, asset_cutoff)], 
                   by.x = "yr", by.y = "year", all.x = TRUE)
large_banks <- unique(all_banks[bank_assets > asset_cutoff]$RSSDID)

# Prepare branch-level beta data
branch_betas <- branch_betas[, .(
  branch_id = UNINUMBR,                          # Unique branch identifier
  bank_id = RSSDID,                              # Bank holding company ID
  year = yr,
  estimated_deposit_beta = deposit_beta,          # Previously calculated beta
  total_branch_deposits = DEPSUMBR
)]

# RateWatch data: actual deposit rates offered by banks
ratewatch_files <- list.files(
  "H:/RateWatch/cleaned_rate_setting_only/", 
  pattern = "_123.rds$", 
  full.names = TRUE
)
ratewatch_rates <- rbindlist(lapply(ratewatch_files, readRDS), fill = TRUE)
ratewatch_rates <- ratewatch_rates[PRODUCTDESCRIPTION %in% c("SAV2.5K", "12MCD10K", "MM25K", "INTCK2.5K")]
ratewatch_rates[, year := year(DATESURVEYED)]

# Deposit composition data: what types of deposits each bank has
deposit_composition <- readRDS("data/deposit_mix.rds")
deposit_composition[, total_time_deposits := 
                      time_deposits_below_ins_limit + time_deposits_above_ins_limit]
deposit_composition[, sum_categorized := 
                      money_market_account_bal + non_mm_savings_accounts + 
                      total_time_deposits + non_interest_bearing_deposits]
deposit_composition[, trans_accts_int_bearing := 
                      ifelse(total_deposits > sum_categorized, 
                             total_deposits - sum_categorized, 0)]
deposit_composition[, year := year(D_DT)]

deposit_composition <- deposit_composition[, .(
  bank_id = ID_RSSD,
  year,
  time_deposits = total_time_deposits,
  money_market_bal = money_market_account_bal,
  savings_bal = non_mm_savings_accounts,
  noninterest_deposits = non_interest_bearing_deposits,
  transaction_accts_interest = trans_accts_int_bearing
)]

################################################################################
# STEP 2: CALCULATE DEPOSIT-WEIGHTED AVERAGE RATE FOR EACH BANK
################################################################################

# Calculate average rate by product type for each branch
avg_rates_by_product <- ratewatch_rates[, 
                                        .(avg_rate = mean(APY, na.rm = TRUE)), 
                                        by = .(branch_id = UNINUMBR, 
                                               bank_id = RSSD_ID, 
                                               product_type = PRODUCTDESCRIPTION, 
                                               year)]

# Reshape: one row per branch-year with columns for each product type
rates_wide <- dcast(
  avg_rates_by_product[product_type %in% c("SAV2.5K", "12MCD10K", "MM25K", "INTCK2.5K")], 
  branch_id + bank_id + year ~ product_type, 
  value.var = "avg_rate"
)

# Keep only complete cases with valid IDs
rates_wide <- rates_wide[complete.cases(rates_wide) & 
                           branch_id > 0 & 
                           bank_id > 0]

# Merge with deposit composition data
rates_with_deposits <- merge(
  rates_wide, 
  deposit_composition,
  by.x = c("bank_id", "year"),
  by.y = c("bank_id", "year")
)

# Calculate weighted interest cost across deposit types
# This gives us a single "effective rate" for each bank
rates_with_deposits[, total_interest_cost := 
                      `12MCD10K` * time_deposits + 
                      MM25K * money_market_bal + 
                      `SAV2.5K` * savings_bal]

rates_with_deposits[, total_interest_bearing_deposits := 
                      time_deposits + money_market_bal + 
                      savings_bal + noninterest_deposits]

rates_with_deposits[, weighted_avg_rate := 
                      total_interest_cost / total_interest_bearing_deposits]

# Create simplified dataset for beta calculation
bank_effective_rates <- rates_with_deposits[, .(
  branch_id, 
  bank_id, 
  year, 
  effective_rate = weighted_avg_rate
)]

# Add large bank indicator
bank_effective_rates[, large_bank := ifelse(bank_id %in% large_banks, 
                                            "Large bank", 
                                            "Small bank")]

################################################################################
# STEP 2.5: DEFINE ANALYSIS PERIODS (Fed Rate Hiking Cycles)
################################################################################

rate_hiking_periods <- data.table(
  period_start = c(2004, 2016, 2022),
  period_end = c(2006, 2019, 2023),
  fed_rate_change = c(3.5, 2.5, 4.0),  # Total Fed Funds rate increase (percentage points)
  period_label = c("2004-2006 Cycle","2016-2019 Cycle", "2022-2023 Cycle")
)

################################################################################
# STEP 2.6: IDENTIFY BANKS WITH MEANINGFUL 12MCD10K RATE INCREASES (ALL CYCLES)
################################################################################

# Calculate bank-level average 12MCD10K rates for all rate hiking periods
cd_rates_all_periods <- ratewatch_rates[
  PRODUCTDESCRIPTION == "12MCD10K",
  .(avg_cd_rate = mean(APY, na.rm = TRUE)),
  by = .(bank_id = RSSD_ID, year)
]

# For each period, calculate rate changes
cd_increase_by_period <- rbindlist(lapply(1:nrow(rate_hiking_periods), function(i) {
  
  period_start_year <- rate_hiking_periods[i, period_start]
  period_end_year <- rate_hiking_periods[i, period_end]
  period_name <- rate_hiking_periods[i, period_label]
  
  # Get rates at start and end
  rates_start <- cd_rates_all_periods[year == period_start_year, 
                                      .(bank_id, cd_rate_start = avg_cd_rate)]
  rates_end <- cd_rates_all_periods[year == period_end_year, 
                                    .(bank_id, cd_rate_end = avg_cd_rate)]
  
  # Merge and calculate change
  period_cd_change <- merge(rates_start, rates_end, by = "bank_id")
  period_cd_change[, cd_rate_change := cd_rate_end - cd_rate_start]
  period_cd_change[, cd_increase_flag := ifelse(
    is.finite(cd_rate_change) & cd_rate_change >= 0.1, 
    TRUE, 
    FALSE
  )]
  period_cd_change[, period := period_name]
  
  return(period_cd_change[, .(bank_id, period, cd_rate_change, cd_increase_flag)])
}))

cat("\n========================================\n")
cat("12-MONTH CD RATE CHANGE SUMMARY (ALL CYCLES)\n")
cat("========================================\n")
for(period_name in unique(cd_increase_by_period$period)) {
  period_data <- cd_increase_by_period[period == period_name]
  cat("\n", period_name, ":\n", sep = "")
  cat("  Total banks with CD data:", nrow(period_data), "\n")
  cat("  Banks with rate increase >= 0.1 pp:", sum(period_data$cd_increase_flag), "\n")
  cat("  Banks with rate increase < 0.1 pp:", sum(!period_data$cd_increase_flag), "\n")
  cat("  Mean CD rate change:", round(mean(period_data$cd_rate_change, na.rm = TRUE), 3), "pp\n")
  cat("  Median CD rate change:", round(median(period_data$cd_rate_change, na.rm = TRUE), 3), "pp\n")
}

################################################################################
# STEP 3: CALCULATE DEPOSIT BETAS FROM RATEWATCH DATA
################################################################################

# For each period, calculate how much each bank changed its deposit rates
# Beta = (Rate at End - Rate at Start) / Fed Funds Change

ratewatch_betas <- rbindlist(lapply(1:nrow(rate_hiking_periods), function(i) {
  
  period_start_year <- rate_hiking_periods[i, period_start]
  period_end_year <- rate_hiking_periods[i, period_end]
  fed_change <- rate_hiking_periods[i, fed_rate_change]
  period_name <- rate_hiking_periods[i, period_label]
  
  # Extract rates at start and end of period
  # **Include large_bank indicator from start of period**
  rates_at_start <- bank_effective_rates[year == period_start_year, 
                                         .(branch_id, bank_id, 
                                           rate_at_start = effective_rate,
                                           large_bank)]
  
  rates_at_end <- bank_effective_rates[year == period_end_year, 
                                       .(branch_id, bank_id, 
                                         rate_at_end = effective_rate)]
  
  # Merge and calculate beta
  period_betas <- merge(rates_at_start, rates_at_end, 
                        by = c("branch_id", "bank_id"))
  
  period_betas[, rate_change := rate_at_end - rate_at_start]
  period_betas[, ratewatch_beta := rate_change / fed_change]
  period_betas[, period := period_name]
  period_betas[, period_start_year := period_start_year]
  period_betas[, period_end_year := period_end_year]
  
  return(period_betas)
}))

################################################################################
# STEP 4: CALCULATE AVERAGE ESTIMATED BETAS FOR EACH PERIOD
################################################################################

# Average the branch-level estimated betas across each period
branch_betas_by_period <- rbindlist(lapply(1:nrow(rate_hiking_periods), function(i) {
  
  period_start_year <- rate_hiking_periods[i, period_start]
  period_end_year <- rate_hiking_periods[i, period_end]
  period_name <- rate_hiking_periods[i, period_label]
  
  # Filter to years in this period
  period_data <- branch_betas[year >= period_start_year & year <= period_end_year]
  
  # Calculate average beta for each branch across the period
  avg_betas <- period_data[, .(
    avg_estimated_beta = mean(estimated_deposit_beta, na.rm = TRUE),
    avg_deposits = mean(total_branch_deposits, na.rm = TRUE)
  ), by = .(branch_id, bank_id)]
  
  avg_betas[, period := period_name]
  
  return(avg_betas)
}))

################################################################################
# STEP 5: MERGE RATEWATCH BETAS WITH ESTIMATED BETAS
################################################################################

# Combine the two beta measures for comparison
comparison_data <- merge(
  ratewatch_betas, 
  branch_betas_by_period, 
  by.x = c("branch_id", "bank_id", "period"), 
  by.y = c("branch_id", "bank_id", "period")
)

# Keep only valid (finite) observations
comparison_data <- comparison_data[is.finite(avg_estimated_beta) & 
                                     is.finite(ratewatch_beta)]

################################################################################
# STEP 6: CREATE BINNED SCATTER PLOTS (SEPARATE BINS FOR LARGE VS SMALL BANKS)
################################################################################

# FILTERING OPTION: Set to TRUE to only include banks with CD rate increase >= 0.1 pp
# Set to FALSE to include all banks
FILTER_BY_CD_INCREASE <- TRUE  # Change to TRUE to apply filter

if(FILTER_BY_CD_INCREASE) {
  cat("\n========================================\n")
  cat("APPLYING FILTER: Only banks with 12MCD10K rate increase >= 0.1 pp\n")
  cat("========================================\n")
  
  # Merge CD increase flags with comparison data
  comparison_data <- comparison_data[!bank_id %in% unique(cd_increase_by_period[cd_increase_flag==FALSE]$bank_id)]
  
  cat("Observations after filtering:\n")
  for(period_name in unique(comparison_data$period)) {
    n_obs <- nrow(comparison_data[period == period_name])
    cat("  ", period_name, ": ", n_obs, " observations\n", sep = "")
  }
} else {
  cat("\n========================================\n")
  cat("NO FILTER APPLIED: Including all banks\n")
  cat("========================================\n")
}

# Get unique periods for analysis
unique_periods <- unique(comparison_data[, .(period)])

# Storage for plots and regressions
scatter_plots <- list()
regression_models <- list()
regression_models_by_size <- list()

for(i in 1:nrow(unique_periods)) {
  
  current_period <- unique_periods[i, period]
  
  # Filter to current period
  period_subset <- comparison_data[period == current_period]
  
  # Optional: winsorize at extreme values (currently no winsorization)
  beta_limits <- quantile(period_subset$avg_estimated_beta, 
                          probs = c(0, 1), na.rm = TRUE)
  period_subset[, estimated_beta_winsorized := 
                  pmax(pmin(avg_estimated_beta, beta_limits[2]), beta_limits[1])]
  
  ratewatch_limits <- quantile(period_subset$ratewatch_beta, 
                               probs = c(0, 1), na.rm = TRUE)
  period_subset[, ratewatch_beta_winsorized := 
                  pmax(pmin(ratewatch_beta, ratewatch_limits[2]), ratewatch_limits[1])]
  
  # CREATE SEPARATE BINS FOR LARGE AND SMALL BANKS
  # Split data by bank size
  large_bank_data <- period_subset[large_bank == "Large bank"]
  small_bank_data <- period_subset[large_bank == "Small bank"]
  
  # Create 20 bins for LARGE banks based on their distribution
  if(nrow(large_bank_data) > 0) {
    bin_breaks_large <- unique(quantile(
      large_bank_data$estimated_beta_winsorized, 
      probs = seq(0, 1, length.out = 11), 
      na.rm = TRUE
    ))
    
    if(length(bin_breaks_large) > 1) {
      large_bank_data[, beta_bin := cut(
        estimated_beta_winsorized, 
        breaks = bin_breaks_large,
        include.lowest = TRUE,
        labels = FALSE
      )]
    }
  }
  
  # Create 20 bins for SMALL banks based on their distribution
  if(nrow(small_bank_data) > 0) {
    bin_breaks_small <- unique(quantile(
      small_bank_data$estimated_beta_winsorized, 
      probs = seq(0, 1, length.out = 21), 
      na.rm = TRUE
    ))
    
    if(length(bin_breaks_small) > 1) {
      small_bank_data[, beta_bin := cut(
        estimated_beta_winsorized, 
        breaks = bin_breaks_small,
        include.lowest = TRUE,
        labels = FALSE
      )]
    }
  }
  
  # Combine the binned data back together
  period_subset_binned <- rbindlist(list(large_bank_data, small_bank_data), 
                                    fill = TRUE)
  
  # Calculate mean values within each bin for each bank size
  binned_means <- period_subset_binned[, .(
    mean_estimated_beta = mean(estimated_beta_winsorized, na.rm = TRUE),
    mean_ratewatch_beta = mean(ratewatch_beta_winsorized, na.rm = TRUE),
    n_observations = .N
  ), by = .(beta_bin, large_bank)]
  
  # Run regression on individual-level data (all banks)
  regression <- feols(
    ratewatch_beta_winsorized ~ estimated_beta_winsorized, 
    data = period_subset
  )
  
  regression_models[[current_period]] <- regression
  
  # Run separate regressions by bank size
  if(nrow(large_bank_data) > 0) {
    reg_large <- feols(
      ratewatch_beta_winsorized ~ estimated_beta_winsorized, 
      data = large_bank_data
    )
    regression_models_by_size[[paste0(current_period, " - Large")]] <- reg_large
  }
  
  if(nrow(small_bank_data) > 0) {
    reg_small <- feols(
      ratewatch_beta_winsorized ~ estimated_beta_winsorized, 
      data = small_bank_data
    )
    regression_models_by_size[[paste0(current_period, " - Small")]] <- reg_small
  }
  
    # Create scatter plot with separate colors/shapes for large vs small banks
  scatter_plots[[current_period]] <- 
    ggplot(binned_means, aes(x = mean_estimated_beta, 
                             y = mean_ratewatch_beta,
                             color = large_bank,
                             shape = large_bank)) +
    geom_point(alpha = 0.7, size = 3) +
    geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
    scale_color_manual(values = c("Large bank" = "dodgerblue4", 
                                  "Small bank" = "tan2"),
                       name = "Bank Size") +
    scale_shape_manual(values = c("Large bank" = 16,    # Circle
                                  "Small bank" = 17),   # Triangle
                       name = "Bank Size") +
    labs(
      x = "Estimated Deposit Beta",
      y = "RateWatch Beta"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 12),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 9)
    )
}

# Storage for combined plots (without size split)
scatter_plots_combined <- list()

for(i in 1:nrow(unique_periods)) {
  
  current_period <- unique_periods[i, period]
  
  # Filter to current period
  period_subset <- comparison_data[period == current_period]
  
  # Winsorize
  beta_limits <- quantile(period_subset$avg_estimated_beta, 
                          probs = c(0, 1), na.rm = TRUE)
  period_subset[, estimated_beta_winsorized := 
                  pmax(pmin(avg_estimated_beta, beta_limits[2]), beta_limits[1])]
  
  ratewatch_limits <- quantile(period_subset$ratewatch_beta, 
                               probs = c(0, 1), na.rm = TRUE)
  period_subset[, ratewatch_beta_winsorized := 
                  pmax(pmin(ratewatch_beta, ratewatch_limits[2]), ratewatch_limits[1])]
  
  # Create 20 bins for ALL banks (not split by size)
  bin_breaks_combined <- unique(quantile(
    period_subset$estimated_beta_winsorized, 
    probs = seq(0, 1, length.out = 21), 
    na.rm = TRUE
  ))
  
  if(length(bin_breaks_combined) > 1) {
    period_subset[, beta_bin := cut(
      estimated_beta_winsorized, 
      breaks = bin_breaks_combined,
      include.lowest = TRUE,
      labels = FALSE
    )]
  }
  
  # Calculate mean values within each bin (all banks together)
  binned_means_combined <- period_subset[, .(
    mean_estimated_beta = mean(estimated_beta_winsorized, na.rm = TRUE),
    mean_ratewatch_beta = mean(ratewatch_beta_winsorized, na.rm = TRUE),
    n_observations = .N
  ), by = .(beta_bin)]
  
  # Create scatter plot without size split
  scatter_plots_combined[[current_period]] <- 
    ggplot(binned_means_combined, aes(x = mean_estimated_beta, 
                                      y = mean_ratewatch_beta)) +
    geom_point(alpha = 0.7, size = 3, color = "dodgerblue4") +
    geom_smooth(method = "lm", se = TRUE, linewidth = 1, color = "dodgerblue4") +
    labs(
      x = "Estimated Deposit Beta",
      y = "RateWatch Beta"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 12),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10)
    )
}

################################################################################
# STEP 7: DISPLAY RESULTS
################################################################################

# Show all scatter plots in a grid
do.call(grid.arrange, c(scatter_plots_combined, ncol = 1))
do.call(grid.arrange, c(scatter_plots, ncol = 1))





