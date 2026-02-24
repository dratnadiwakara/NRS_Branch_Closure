################################################################################
# Analysis of Deposit Rate Setting Behavior and Branch-Level Deposit Betas
# 
# This script:
# 1. Processes RateWatch deposit rate data for selected years
# 2. Calculates branch-level deposit rate betas from APY changes
# 3. Compares RateWatch betas with estimated deposit betas from branch sample
# 4. Generates binned scatter plots and regression analyses
#
# Author: [Your Name]
# Date: [Date]
# Last Updated: [Date]
################################################################################

# Clear workspace and load required packages
rm(list = ls())

# Load required libraries
library(data.table)  # For efficient data manipulation
library(ggplot2)     # For visualization
library(fixest)      # For econometric estimation
library(gridExtra)   # For arranging multiple plots

################################################################################
# SECTION 1: DATA PREPARATION (RateWatch)
################################################################################
# 
# NOTE: This section processes raw RateWatch data. It is commented out as
# the processed data files are already available. Uncomment to re-run from scratch.
#
# The code processes RateWatch data for years 2016, 2019, 2022, 2023
# and extracts deposit rates for months 1-3 (January-March) to capture
# rate-setting behavior during the Federal Reserve monetary policy cycles.
################################################################################

# yrs <- c(2016, 2019, 2022, 2023)
# 
# for(yr in yrs) {
#   folder_path <- paste0("H:/RateWatch/Fed/", yr)
#   
#   # Load account join data (links products to accounts)
#   acct_join <- lapply(list.files(path = paste0(folder_path, "/acct_join/"), 
#                                   full.names = TRUE), 
#                       fread,
#                       select = c("ACCT_NBR_RT", "PRD_TYP_JOIN", "ACCT_NBR_LOC"))
#   acct_join <- rbindlist(acct_join, fill = TRUE)
#   acct_join <- acct_join[!duplicated(acct_join[, c("ACCT_NBR_RT", "PRD_TYP_JOIN", "ACCT_NBR_LOC")])]
#   
#   # Load institution details (links to FDIC identifiers)
#   inst <- lapply(list.files(path = paste0(folder_path, "/InstitutionDetails/"), 
#                             full.names = TRUE), 
#                  fread,
#                  select = c("ACCT_NBR", "RSSD_ID", "CERT_NBR", "UNINUMBR"))
#   inst <- rbindlist(inst, fill = TRUE)
#   inst <- inst[!duplicated(inst[, c("ACCT_NBR", "UNINUMBR")])]
#   inst <- inst[ACCT_NBR %in% unique(acct_join$ACCT_NBR_RT)]
#   inst <- unique(inst, by = c("ACCT_NBR"))
#   
#   # Load deposit rate data
#   rates <- lapply(list.files(path = paste0(folder_path, "/depositRateData/"), 
#                               full.names = TRUE), 
#                   fread)
#   rates <- rbindlist(rates, fill = TRUE)
#   rates <- rates[year(DATESURVEYED) == yr]
#   rates[, PRD_TYP_JOIN := PRODUCTTYPE]
#   
#   # Merge rates with institution identifiers
#   deposit_rates <- merge(rates, 
#                          inst[, c("ACCT_NBR", "RSSD_ID", "CERT_NBR", "UNINUMBR")],
#                          by.x = "ACCOUNTNUMBER",
#                          by.y = "ACCT_NBR")
#   
#   # Keep only relevant columns and filter to Q1 months
#   deposit_rates <- deposit_rates[, c("PRODUCTDESCRIPTION", "DATESURVEYED", 
#                                      "APY", "UNINUMBR", "RSSD_ID")]
#   deposit_rates[, DATESURVEYED := as.Date(DATESURVEYED)]
#   deposit_rates <- deposit_rates[month(DATESURVEYED) %in% c(1, 2, 3)]
#   
#   # Save processed data
#   saveRDS(deposit_rates, 
#           file = paste0("H:/RateWatch/cleaned_rate_setting_only/cleaned_", 
#                        yr, "_123.rds"))
# }

################################################################################
# SECTION 2: LOAD AND PREPARE DATA
################################################################################

# Load branch-level deposit beta estimates
# This dataset contains estimated deposit betas from branch-level analysis
branch_sample <- readRDS("data/branch_closure_analysis_sample_with_beta_02242026.rds")
branch_sample <- branch_sample[, .(UNINUMBR, RSSDID, yr, deposit_beta)]

# Load and combine processed RateWatch data
rds_files <- list.files("H:/RateWatch/cleaned_rate_setting_only/", 
                        pattern = "_123.rds$", 
                        full.names = TRUE)
combined_data <- rbindlist(lapply(rds_files, readRDS), fill = TRUE)
combined_data[, year := year(DATESURVEYED)]

################################################################################
# SECTION 3: CALCULATE ANNUAL AVERAGE APY BY BRANCH-PRODUCT
################################################################################

# Calculate mean APY for each branch-product-year combination
# Uses all observations without trimming to preserve full variation
mean_apy <- combined_data[, .(mean_apy = mean(APY, na.rm = TRUE)), 
                          by = .(UNINUMBR, RSSD_ID, PRODUCTDESCRIPTION, year)]

################################################################################
# SECTION 4: DEFINE ANALYSIS PERIODS
################################################################################

# Define two monetary policy cycles for analysis:
# 1. 2016-2019: Fed tightening cycle (2.5 percentage point increase in Fed Funds)
# 2. 2022-2023: Recent tightening cycle (4 percentage point increase in Fed Funds)
periods <- data.table(
  start_year = c(2016, 2022),
  end_year = c(2019, 2023),
  divisor = c(2.5, 4),  # Total change in Fed Funds rate during period
  period_name = c("2016-2019", "2022-2023")
)

################################################################################
# SECTION 5: CALCULATE RATEWATCH DEPOSIT BETAS
################################################################################

# Calculate deposit rate sensitivity (beta) for each period
# Beta = Change in deposit rate / Change in Fed Funds rate
beta_results <- rbindlist(lapply(1:nrow(periods), function(i) {
  start_yr <- periods[i, start_year]
  end_yr <- periods[i, end_year]
  div <- periods[i, divisor]
  period <- periods[i, period_name]
  
  # Get APY at start and end of period
  start_apy <- mean_apy[year == start_yr, 
                        .(UNINUMBR, RSSD_ID, PRODUCTDESCRIPTION, 
                          start_apy = mean_apy)]
  end_apy <- mean_apy[year == end_yr, 
                      .(UNINUMBR, RSSD_ID, PRODUCTDESCRIPTION, 
                        end_apy = mean_apy)]
  
  # Merge and calculate beta
  result <- merge(start_apy, end_apy, 
                  by = c("UNINUMBR", "RSSD_ID", "PRODUCTDESCRIPTION"), 
                  all = FALSE)
  result[, apy_change := end_apy - start_apy]
  result[, beta := apy_change / div]
  result[, period := period]
  result[, start_year := start_yr]
  result[, end_year := end_yr]
  
  return(result)
}))

################################################################################
# SECTION 6: CALCULATE MEAN DEPOSIT BETAS FROM BRANCH SAMPLE
################################################################################

# Calculate mean deposit beta across each period for each branch
# This averages the estimated betas across all years within each period
branch_sample_period <- rbindlist(lapply(1:nrow(periods), function(i) {
  start_yr <- periods[i, start_year]
  end_yr <- periods[i, end_year]
  period <- periods[i, period_name]
  
  # Filter branch sample data for years in this period
  period_data <- branch_sample[yr >= start_yr & yr <= end_yr]
  
  # Calculate mean deposit_beta across the period
  mean_deposit <- period_data[, .(mean_deposit_beta = mean(deposit_beta, na.rm = TRUE)),
                              by = .(UNINUMBR, RSSDID)]
  mean_deposit[, period := period]
  
  return(mean_deposit)
}))

################################################################################
# SECTION 7: MERGE RATEWATCH BETAS WITH DEPOSIT BETAS
################################################################################

# Merge RateWatch betas with estimated deposit betas
merged_data <- merge(beta_results, 
                     branch_sample_period, 
                     by.x = c("UNINUMBR", "RSSD_ID", "period"), 
                     by.y = c("UNINUMBR", "RSSDID", "period"),
                     all.x = FALSE)

# Rename for consistency
setnames(merged_data, "mean_deposit_beta", "deposit_beta")

# Keep only observations with finite deposit betas
merged_data <- merged_data[is.finite(deposit_beta)]

################################################################################
# SECTION 8: BINNED SCATTER PLOT ANALYSIS
################################################################################

# Specify deposit products for analysis
# 12MCD10K: 12-month Certificate of Deposit with $10,000 minimum
# MM25K: Money Market account with $25,000 minimum
products_to_analyze <- c("12MCD10K", "MM25K")

# Get unique combinations of period and product
combinations <- unique(merged_data[!is.na(deposit_beta) & !is.na(beta) & 
                                     PRODUCTDESCRIPTION %in% products_to_analyze, 
                                   .(period, PRODUCTDESCRIPTION)])

# Initialize storage for results
plot_list <- list()
regression_list <- list()

# Loop through each period-product combination
for(i in 1:nrow(combinations)) {
  period_i <- combinations[i, period]
  product_i <- combinations[i, PRODUCTDESCRIPTION]
  
  # Subset data for this specific period-product combination
  data_subset <- merged_data[period == period_i & 
                               PRODUCTDESCRIPTION == product_i & 
                               !is.na(deposit_beta) & 
                               !is.na(beta)]
  
  # Winsorize variables (no winsorization applied here, but framework in place)
  # Using 0th and 100th percentiles means no actual winsorization
  q_deposit_beta <- quantile(data_subset$deposit_beta, probs = c(0, 1), na.rm = TRUE)
  data_subset[, deposit_beta_w := pmax(pmin(deposit_beta, q_deposit_beta[2]), 
                                       q_deposit_beta[1])]
  
  q_beta <- quantile(data_subset$beta, probs = c(0, 1), na.rm = TRUE)
  data_subset[, beta_w := pmax(pmin(beta, q_beta[2]), q_beta[1])]
  
  # Create 20 bins based on deposit_beta distribution
  # Using unique() to handle potential duplicate quantile values
  breaks <- unique(quantile(data_subset$deposit_beta_w, 
                            probs = seq(0, 1, length.out = 21), 
                            na.rm = TRUE))
  
  if(length(breaks) > 1) {
    # Assign observations to bins
    data_subset[, bin := cut(deposit_beta_w, 
                             breaks = breaks,
                             include.lowest = TRUE,
                             labels = FALSE)]
    
    # Calculate mean values within each bin for plotting
    binned_data <- data_subset[, .(mean_deposit_beta = mean(deposit_beta_w, na.rm = TRUE),
                                   mean_beta = mean(beta_w, na.rm = TRUE),
                                   n = .N),
                               by = bin]
    
    # Run regression on individual-level data (not binned)
    reg_model <- feols(beta_w ~ deposit_beta_w, data = data_subset)
    
    # Store regression results
    regression_list[[paste0(period_i, "_", product_i)]] <- reg_model
    
    # Create binned scatter plot
    plot_list[[paste0(period_i, "_", product_i)]] <- 
      ggplot(binned_data, aes(x = mean_deposit_beta, y = mean_beta)) +
      geom_point(alpha = 0.6, color = "dodgerblue4", size = 3) +
      geom_smooth(method = "lm", se = TRUE, color = "tan2", size = 1) +
      labs(title = paste0(product_i, " - ", period_i),
           x = "Estimated Deposit Beta",
           y = "RateWatch Beta") +
      theme_bw() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"),
            axis.title = element_text(size = 11),
            axis.text = element_text(size = 10))
  }
}

################################################################################
# SECTION 9: OUTPUT RESULTS
################################################################################

# Display all plots in a 2-column grid
do.call(grid.arrange, c(plot_list, ncol = 2))

# Display regression results table
# This shows the relationship between deposit betas and RateWatch betas
etable(regression_list)

################################################################################
# END OF SCRIPT
################################################################################

# Additional notes for data editor:
# 1. All data files referenced in this script are available in the replication package
# 2. Raw RateWatch data (Section 1, commented out) requires licensed access
# 3. Processed files are provided to ensure reproducibility
# 4. Branch sample data contains estimated deposit betas from separate analysis
# 5. All monetary policy cycle dates are based on Federal Reserve policy announcements
################################################################################