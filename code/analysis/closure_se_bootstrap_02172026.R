# ==============================================================================
# Two-Stage Bootstrap for Branch Closure Regressions (with Checkpointing)
# ==============================================================================
# This script implements a full two-stage bootstrap that:
# 1. Re-estimates bank-level deposit beta regressions (first stage)
# 2. Re-estimates branch-level closure regressions (second stage)
# This properly accounts for generated regressor uncertainty
# 
# INCLUDES: Checkpoint saving to resume after crashes
# ==============================================================================

rm(list = ls())
gc()

library(data.table)
library(dplyr)
library(fixest)
library(modelsummary)
library(ggplot2)
library(lubridate)

# Suppress warnings and messages from fixest
options(fixest_warn = FALSE)
options(warn = -1)

data_dir <- "C:/OneDrive/data/nrs_branch_closure"

# ==============================================================================
# 1. Load Data
# ==============================================================================

# Load original deposit beta results
beta_cycles_original <- readRDS(file.path(data_dir, "deposit_beta_results_v02172026.rds"))

# Load branch sample
branch_sample <- readRDS(file.path(data_dir, "branch_closure_analysis_sample_02172026.rds"))

# Load call report data (needed for first-stage bootstrap)
call_data <- readRDS(file.path(data_dir, "call_data_02172026.rds"))

# Clean call data
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
# 2. Define Large Banks
# ==============================================================================

cpi <- readRDS(file.path(data_dir, "cpi.rds"))
cpi[, adj_ratio := CPI / CPI[year == 2024]]
cpi[, asset_cutoff := adj_ratio * 100000000]

all_banks <- rbindlist(lapply(names(beta_cycles_original), function(cycle_name) {
  dt <- copy(beta_cycles_original[[cycle_name]]$data)
  dt[, cycle := cycle_name]
  dt[, year := ifelse(cycle == "cycle_0406", 2006,
                      ifelse(cycle == "cycle_1619", 2019, 2023))]
  return(dt)
}))

all_banks <- merge(all_banks, cpi[, .(year, asset_cutoff)], by = "year", all.x = TRUE)
large_banks <- unique(all_banks[bank_assets > asset_cutoff]$ID_RSSD)

# Add large_bank indicator to branch sample
branch_sample[, large_bank := ifelse(RSSDID %in% large_banks, 1, 0)]

# ==============================================================================
# 3. Define Interest Rate Cycles (for first stage)
# ==============================================================================

cycles_definition <- list(
  cycle_0406 = list(
    start_date = as.Date("2004-03-31"),
    end_date = as.Date("2006-03-31"),
    rate_change = 3.5,
    demo_year = 2012
  ),
  cycle_1619 = list(
    start_date = as.Date("2016-03-31"),
    end_date = as.Date("2019-03-31"),
    rate_change = 2.5,
    demo_year = 2019
  ),
  cycle_2224 = list(
    start_date = as.Date("2022-03-31"),
    end_date = as.Date("2023-03-31"),
    rate_change = 4.0,
    demo_year = 2019
  )
)

# ==============================================================================
# 4. Helper Functions for First Stage
# ==============================================================================

aggregate_bank_demographics <- function(data, yr_filter) {
  dt <- data[yr == yr_filter]
  dt[, deposit_weight := DEPSUMBR / sum(DEPSUMBR, na.rm = TRUE), by = RSSDID]
  
  bank_agg <- dt[, .(
    college_frac = sum(college_frac * deposit_weight, na.rm = TRUE) + 0.01,
    dividend_frac = sum(dividend_frac * deposit_weight, na.rm = TRUE) + 0.01,
    family_income = sum(family_income * deposit_weight, na.rm = TRUE) + 1,
    population_density = sum(population_density * deposit_weight, na.rm = TRUE),
    age = sum(age * deposit_weight, na.rm = TRUE),
    age_bin = floor(median(age_bin, na.rm = TRUE)),
    sophisticated_frac = sum(sophisticated * deposit_weight, na.rm = TRUE),
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

calculate_cycle_beta <- function(call_data, bank_demos, start_date, end_date) {
  cycle_data <- call_data[D_DT %in% c(start_date, end_date)]
  cycle_wide <- dcast(cycle_data, ID_RSSD ~ D_DT, value.var = "deposit_exp_deposits")
  setnames(cycle_wide, c("ID_RSSD", "dep_exp_start", "dep_exp_end"))
  
  cycle_wide[, deposit_exp_chg := dep_exp_end - dep_exp_start]
  cycle_wide <- cycle_wide[!is.na(deposit_exp_chg)]
  
  q02 <- quantile(cycle_wide$deposit_exp_chg, 0.01, na.rm = TRUE)
  q98 <- quantile(cycle_wide$deposit_exp_chg, 0.99, na.rm = TRUE)
  cycle_wide <- cycle_wide[deposit_exp_chg > q02 & deposit_exp_chg < q98]
  
  merged <- merge(cycle_wide[, .(ID_RSSD, deposit_exp_chg)], 
                  bank_demos, 
                  by.x = "ID_RSSD", by.y = "RSSDID")
  
  return(merged)
}

# ==============================================================================
# 5. Define Control Variables for Second Stage
# ==============================================================================

setFixest_fml(
  ..ctrl_state_closure = ~ log(lag_branch_deposit_amount) + same_zip_prior_3yr_branches + 
    legacy_branch + lag_county_deposit_gr + 
    lag_hmda_mtg_amt_gr + lag_cra_loan_amount_amt_lt_1m_gr + 
    lag_establishment_gr + lag_payroll_gr + lmi + 
    log(lag_bank_county_mortgage_volume) + log(lag_bank_county_cra_volume) + 
    log1p(family_income) | state_yr + bank_yr
)

# ==============================================================================
# 6. Run Original Regressions (for comparison)
# ==============================================================================

# Create fixed effects in branch sample
branch_sample[, state_yr := paste0(substr(STCNTYBR, 1, 2), "_", yr)]
branch_sample[, bank_yr := paste0(RSSDID, "_", yr)]
branch_sample[, factor_age_bin := as.factor(age_bin)]

# Predict branch-level betas using original regressions
for(i in 1:length(beta_cycles_original)) {
  cycle_nm <- names(beta_cycles_original)[i]
  branch_sample[, pred_int_exp_chg := predict(beta_cycles_original[[i]]$reg, 
                                              newdata = branch_sample)]
  setnames(branch_sample, "pred_int_exp_chg", paste0("pred_int_exp_chg_", cycle_nm))
}

branch_sample[, deposit_beta := ifelse(yr <= 2014, pred_int_exp_chg_cycle_0406 / 3.5,
                                       ifelse(yr <= 2019, pred_int_exp_chg_cycle_1619 / 2.5,
                                              pred_int_exp_chg_cycle_2224 / 4))]

# Run original regressions
reg_large_original <- feols(closed ~ deposit_beta + ..ctrl_state_closure, 
                            data = branch_sample[large_bank == 1], vcov = ~RSSDID)

reg_small_original <- feols(closed ~ deposit_beta + ..ctrl_state_closure, 
                            data = branch_sample[large_bank == 0], vcov = ~RSSDID)

cat("\n=== ORIGINAL RESULTS ===\n")
cat("Large banks - Coefficient:", coef(reg_large_original)["deposit_beta"], 
    "SE:", se(reg_large_original)["deposit_beta"], "\n")
cat("Small banks - Coefficient:", coef(reg_small_original)["deposit_beta"], 
    "SE:", se(reg_small_original)["deposit_beta"], "\n")

# ==============================================================================
# 7. Two-Stage Bootstrap Function (with Checkpointing)
# ==============================================================================

# ==============================================================================
# Two-Stage Bootstrap Function (with Complete Checkpointing)
# ==============================================================================

bootstrap_two_stage <- function(branch_data, call_data, cycles_def, 
                                bank_size = "large", n_boot = 500, seed = 123,
                                checkpoint_file = NULL, checkpoint_freq = 10) {
  
  set.seed(seed)
  
  # Filter branch data by bank size
  if(bank_size == "large") {
    analysis_data <- branch_data[large_bank == 1]
  } else if(bank_size == "small") {
    analysis_data <- branch_data[large_bank == 0]
  } else {
    analysis_data <- branch_data
  }
  
  # Get unique banks from branch sample
  branch_banks <- unique(analysis_data$RSSDID)
  n_branch_banks <- length(branch_banks)
  
  # Store bootstrap coefficients
  boot_coefs <- rep(NA, n_boot)
  
  # Check for existing checkpoint file
  start_iter <- 1
  if(!is.null(checkpoint_file) && file.exists(checkpoint_file)) {
    cat("\nFound existing checkpoint file:", checkpoint_file, "\n")
    checkpoint_data <- fread(checkpoint_file)
    
    # Validate checkpoint file has required columns
    if(all(c("iteration", "coefficient") %in% names(checkpoint_data))) {
      boot_coefs[checkpoint_data$iteration] <- checkpoint_data$coefficient
      completed_iters <- checkpoint_data[!is.na(coefficient), iteration]
      
      if(length(completed_iters) > 0) {
        start_iter <- max(completed_iters) + 1
        cat("Loaded", length(completed_iters), "completed iterations\n")
        cat("Resuming from iteration:", start_iter, "\n")
        
        # Show current progress
        current_se <- sd(boot_coefs[1:(start_iter-1)], na.rm = TRUE)
        current_ci <- quantile(boot_coefs[1:(start_iter-1)], c(0.025, 0.975), na.rm = TRUE)
        cat("Current bootstrap SE:", round(current_se, 4), "\n")
        cat("Current 95% CI: [", round(current_ci[1], 4), ",", round(current_ci[2], 4), "]\n")
      }
    } else {
      cat("Warning: Checkpoint file missing required columns. Starting fresh.\n")
      start_iter <- 1
    }
  } else if(!is.null(checkpoint_file)) {
    cat("\nNo checkpoint file found. Starting fresh.\n")
    cat("Will save checkpoints to:", checkpoint_file, "\n")
  }
  
  cat("\nStarting", n_boot, "bootstrap iterations for", bank_size, "banks...\n")
  
  # Bootstrap loop
  for(b in start_iter:n_boot) {
    if(b %% 10 == 0) {
      cat("Iteration:", b, "/", n_boot)
      # Show running SE and CI every 50 iterations
      if(b >= 50 && b %% 50 == 0) {
        running_se <- sd(boot_coefs[1:b], na.rm = TRUE)
        running_ci <- quantile(boot_coefs[1:b], c(0.025, 0.975), na.rm = TRUE)
        cat(" | Running SE:", round(running_se, 4), 
            "| CI: [", round(running_ci[1], 4), ",", round(running_ci[2], 4), "]")
      }
      cat("\n")
    }
    
    tryCatch({
      
      # ===== STAGE 1: Re-estimate bank-level deposit beta regressions =====
      
      boot_beta_cycles <- list()
      
      for(cycle_name in names(cycles_def)) {
        
        cycle <- cycles_def[[cycle_name]]
        
        # Aggregate demographics for this cycle
        suppressMessages({
          bank_demos <- aggregate_bank_demographics(branch_data, cycle$demo_year)
        })
        
        # Get unique banks from demographics
        demo_banks <- unique(bank_demos$RSSDID)
        n_demo_banks <- length(demo_banks)
        
        # Resample banks with replacement
        boot_demo_banks <- sample(demo_banks, n_demo_banks, replace = TRUE)
        
        # Create bootstrap bank demographics sample
        boot_bank_demos <- rbindlist(lapply(boot_demo_banks, function(bank_id) {
          bank_demos[RSSDID == bank_id]
        }))
        
        # Calculate deposit expense changes for bootstrap sample
        boot_cycle_data <- calculate_cycle_beta(call_data, boot_bank_demos, 
                                                cycle$start_date, cycle$end_date)
        
        # Re-estimate regression (suppress warnings and messages)
        suppressWarnings(suppressMessages({
          boot_reg <- feols(
            deposit_exp_chg ~ factor_age_bin + dividend_frac + college_frac + log(family_income) +
              bank_hhi + log(bank_assets) + population_density + 
              trans_accts_frac_assets + uninsured_deposits_frac + time_deposits_assets,
            data = boot_cycle_data,
            warn = FALSE,
            notes = FALSE
          )
        }))
        
        # Store bootstrap cycle results
        boot_beta_cycles[[cycle_name]] <- list(
          reg = boot_reg,
          data = boot_cycle_data
        )
      }
      
      # ===== STAGE 2: Predict branch-level betas and run closure regression =====
      
      # Resample banks for second stage
      boot_branch_banks <- sample(branch_banks, n_branch_banks, replace = TRUE)
      
      # Create bootstrap branch sample
      boot_branch_sample <- rbindlist(lapply(boot_branch_banks, function(bank_id) {
        analysis_data[RSSDID == bank_id]
      }))
      
      # Create factor variables for prediction
      boot_branch_sample[, factor_age_bin := as.factor(age_bin)]
      
      # Predict deposit betas using bootstrap regressions
      for(i in 1:length(boot_beta_cycles)) {
        cycle_nm <- names(boot_beta_cycles)[i]
        
        # Predict using bootstrap regression
        suppressWarnings({
          boot_branch_sample[, pred_int_exp_chg := predict(boot_beta_cycles[[i]]$reg, 
                                                           newdata = boot_branch_sample)]
        })
        setnames(boot_branch_sample, "pred_int_exp_chg", 
                 paste0("pred_int_exp_chg_", cycle_nm))
      }
      
      # Calculate deposit beta based on year and rate changes
      boot_branch_sample[, deposit_beta := ifelse(yr <= 2014, 
                                                  pred_int_exp_chg_cycle_0406 / 3.5,
                                                  ifelse(yr <= 2019, 
                                                         pred_int_exp_chg_cycle_1619 / 2.5,
                                                         pred_int_exp_chg_cycle_2224 / 4))]
      
      # Re-create fixed effects
      boot_branch_sample[, state_yr := paste0(substr(STCNTYBR, 1, 2), "_", yr)]
      boot_branch_sample[, bank_yr := paste0(RSSDID, "_", yr)]
      
      # Run closure regression (suppress warnings and messages)
      suppressWarnings(suppressMessages({
        boot_closure_reg <- feols(closed ~ deposit_beta + ..ctrl_state_closure, 
                                  data = boot_branch_sample, 
                                  warn = FALSE,
                                  notes = FALSE)
      }))
      
      # Store coefficient
      boot_coefs[b] <- coef(boot_closure_reg)["deposit_beta"]
      
      # Save checkpoint every N iterations
      if(!is.null(checkpoint_file) && (b %% checkpoint_freq == 0 || b == n_boot)) {
        
        # Create checkpoint data with full bootstrap results
        checkpoint_dt <- data.table(
          iteration = 1:b,
          coefficient = boot_coefs[1:b],
          is_complete = !is.na(boot_coefs[1:b]),
          timestamp = Sys.time()
        )
        
        # Calculate current statistics (only from completed iterations)
        completed_coefs <- boot_coefs[1:b][!is.na(boot_coefs[1:b])]
        if(length(completed_coefs) > 0) {
          current_se <- sd(completed_coefs, na.rm = TRUE)
          current_ci <- quantile(completed_coefs, c(0.025, 0.975), na.rm = TRUE)
          current_mean <- mean(completed_coefs, na.rm = TRUE)
          
          # Add summary statistics as attributes (saved in CSV header comments)
          setattr(checkpoint_dt, "n_completed", length(completed_coefs))
          setattr(checkpoint_dt, "current_se", current_se)
          setattr(checkpoint_dt, "current_ci_lower", current_ci[1])
          setattr(checkpoint_dt, "current_ci_upper", current_ci[2])
          setattr(checkpoint_dt, "current_mean", current_mean)
        }
        
        # Write checkpoint file
        fwrite(checkpoint_dt, checkpoint_file)
        
        # Also save a summary statistics file
        if(length(completed_coefs) > 0) {
          summary_file <- gsub("\\.csv$", "_summary.csv", checkpoint_file)
          summary_dt <- data.table(
            bank_size = bank_size,
            total_iterations = n_boot,
            completed_iterations = length(completed_coefs),
            current_iteration = b,
            bootstrap_mean = current_mean,
            bootstrap_se = current_se,
            ci_lower = current_ci[1],
            ci_upper = current_ci[2],
            timestamp = Sys.time()
          )
          fwrite(summary_dt, summary_file)
        }
        
        if(b %% 50 == 0) cat("  Checkpoint saved at iteration", b, "\n")
      }
      
    }, error = function(e) {
      cat("Error in iteration", b, ":", conditionMessage(e), "\n")
      boot_coefs[b] <- NA
      
      # Save checkpoint even on error
      if(!is.null(checkpoint_file)) {
        checkpoint_dt <- data.table(
          iteration = 1:b,
          coefficient = boot_coefs[1:b],
          is_complete = !is.na(boot_coefs[1:b]),
          timestamp = Sys.time()
        )
        fwrite(checkpoint_dt, checkpoint_file)
        
        # Save summary even on error
        completed_coefs <- boot_coefs[1:b][!is.na(boot_coefs[1:b])]
        if(length(completed_coefs) > 0) {
          summary_file <- gsub("\\.csv$", "_summary.csv", checkpoint_file)
          summary_dt <- data.table(
            bank_size = bank_size,
            total_iterations = n_boot,
            completed_iterations = length(completed_coefs),
            current_iteration = b,
            bootstrap_mean = mean(completed_coefs, na.rm = TRUE),
            bootstrap_se = sd(completed_coefs, na.rm = TRUE),
            ci_lower = quantile(completed_coefs, 0.025, na.rm = TRUE),
            ci_upper = quantile(completed_coefs, 0.975, na.rm = TRUE),
            timestamp = Sys.time(),
            error_at_iteration = b
          )
          fwrite(summary_dt, summary_file)
        }
      }
    })
  }
  
  # Calculate final bootstrap statistics
  boot_se <- sd(boot_coefs, na.rm = TRUE)
  boot_ci <- quantile(boot_coefs, c(0.025, 0.975), na.rm = TRUE)
  boot_mean <- mean(boot_coefs, na.rm = TRUE)
  n_successful <- sum(!is.na(boot_coefs))
  
  cat("\nBootstrap complete:", n_successful, "/", n_boot, "iterations successful\n")
  
  # Save final summary
  if(!is.null(checkpoint_file)) {
    final_summary_file <- gsub("\\.csv$", "_final_summary.csv", checkpoint_file)
    final_summary_dt <- data.table(
      bank_size = bank_size,
      total_iterations = n_boot,
      successful_iterations = n_successful,
      bootstrap_mean = boot_mean,
      bootstrap_se = boot_se,
      ci_lower = boot_ci[1],
      ci_upper = boot_ci[2],
      seed = seed,
      timestamp = Sys.time()
    )
    fwrite(final_summary_dt, final_summary_file)
    cat("Final summary saved to:", final_summary_file, "\n")
  }
  
  return(list(
    boot_coefs = boot_coefs,
    boot_se = boot_se,
    boot_ci = boot_ci,
    boot_mean = boot_mean,
    n_successful = n_successful
  ))
}

# ==============================================================================
# 8. Run Bootstrap with Checkpointing
# ==============================================================================

# Large banks
cat("\n=== BOOTSTRAPPING LARGE BANKS ===\n")
boot_large <- bootstrap_two_stage(
  branch_data = branch_sample,
  call_data = call_data,
  cycles_def = cycles_definition,
  bank_size = "large",
  n_boot = 500,
  seed = 123,
  checkpoint_file = file.path(data_dir, "bootstrap_checkpoint_large.csv"),
  checkpoint_freq = 10  # Save every 10 iterations
)

# Small banks
cat("\n=== BOOTSTRAPPING SMALL BANKS ===\n")
boot_small <- bootstrap_two_stage(
  branch_data = branch_sample,
  call_data = call_data,
  cycles_def = cycles_definition,
  bank_size = "small",
  n_boot = 500,
  seed = 456,
  checkpoint_file = file.path(data_dir, "bootstrap_checkpoint_small.csv"),
  checkpoint_freq = 10  # Save every 10 iterations
)



# ==============================================================================
# 9. Display Results
# ==============================================================================

cat("\n" , rep("=", 80), "\n", sep = "")
cat("FINAL RESULTS\n")
cat(rep("=", 80), "\n", sep = "")

cat("\nLARGE BANKS:\n")
cat("  Original coefficient:", round(coef(reg_large_original)["deposit_beta"], 4), "\n")
cat("  Original SE (clustered):", round(se(reg_large_original)["deposit_beta"], 4), "\n")
cat("  Bootstrap SE (two-stage):", round(boot_large$boot_se, 4), "\n")
cat("  Bootstrap 95% CI: [", round(boot_large$boot_ci[1], 4), ",", 
    round(boot_large$boot_ci[2], 4), "]\n")
cat("  SE inflation factor:", round(boot_large$boot_se / se(reg_large_original)["deposit_beta"], 2), "\n")
cat("  T-stat (original):", round(coef(reg_large_original)["deposit_beta"] / 
                                    se(reg_large_original)["deposit_beta"], 2), "\n")
cat("  T-stat (bootstrap):", round(coef(reg_large_original)["deposit_beta"] / 
                                     boot_large$boot_se, 2), "\n")

cat("\nSMALL BANKS:\n")
cat("  Original coefficient:", round(coef(reg_small_original)["deposit_beta"], 4), "\n")
cat("  Original SE (clustered):", round(se(reg_small_original)["deposit_beta"], 4), "\n")
cat("  Bootstrap SE (two-stage):", round(boot_small$boot_se, 4), "\n")
cat("  Bootstrap 95% CI: [", round(boot_small$boot_ci[1], 4), ",", 
    round(boot_small$boot_ci[2], 4), "]\n")
cat("  SE inflation factor:", round(boot_small$boot_se / se(reg_small_original)["deposit_beta"], 2), "\n")
cat("  T-stat (original):", round(coef(reg_small_original)["deposit_beta"] / 
                                    se(reg_small_original)["deposit_beta"], 2), "\n")
cat("  T-stat (bootstrap):", round(coef(reg_small_original)["deposit_beta"] / 
                                     boot_small$boot_se, 2), "\n")

# Create comparison table
comparison_table <- data.table(
  Bank_Size = c("Large", "Small"),
  Coefficient = c(coef(reg_large_original)["deposit_beta"],
                  coef(reg_small_original)["deposit_beta"]),
  SE_Clustered = c(se(reg_large_original)["deposit_beta"],
                   se(reg_small_original)["deposit_beta"]),
  SE_Bootstrap = c(boot_large$boot_se, boot_small$boot_se),
  CI_Lower = c(boot_large$boot_ci[1], boot_small$boot_ci[1]),
  CI_Upper = c(boot_large$boot_ci[2], boot_small$boot_ci[2]),
  N_Bootstrap = c(boot_large$n_successful, boot_small$n_successful)
)

comparison_table[, SE_Inflation := SE_Bootstrap / SE_Clustered]
comparison_table[, T_Stat_Original := Coefficient / SE_Clustered]
comparison_table[, T_Stat_Bootstrap := Coefficient / SE_Bootstrap]

cat("\n")
print(comparison_table)

# ==============================================================================
# 10. Visualize Bootstrap Distributions
# ==============================================================================

boot_dist <- data.table(
  coefficient = c(boot_large$boot_coefs, boot_small$boot_coefs),
  bank_size = c(rep("Large Banks", length(boot_large$boot_coefs)),
                rep("Small Banks", length(boot_small$boot_coefs)))
)
boot_dist <- boot_dist[!is.na(coefficient)]

orig_estimates <- data.table(
  bank_size = c("Large Banks", "Small Banks"),
  estimate = c(coef(reg_large_original)["deposit_beta"],
               coef(reg_small_original)["deposit_beta"])
)

p <- ggplot(boot_dist, aes(x = coefficient)) +
  geom_histogram(bins = 50, fill = "dodgerblue4", alpha = 0.7) +
  geom_vline(data = orig_estimates, aes(xintercept = estimate), 
             color = "red", linetype = "dashed", linewidth = 1) +
  facet_wrap(~bank_size, scales = "free") +
  labs( x = "Coefficient on Deposit Beta",
       y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

print(p)

# Save plot
ggsave(file.path("../../docs/figures/bootstrap_distribution.png"), 
       plot = p, width = 10, height = 6, dpi = 300)

# ==============================================================================
# 11. Save Results
# ==============================================================================

bootstrap_results <- list(
  large_banks = boot_large,
  small_banks = boot_small,
  comparison_table = comparison_table,
  original_regs = list(
    large = reg_large_original,
    small = reg_small_original
  )
)

saveRDS(bootstrap_results, 
        file = file.path(data_dir, "bootstrap_results_two_stage.rds"))

cat("\nResults saved to:", file.path(data_dir, "bootstrap_results_two_stage.rds"), "\n")

# Clean up checkpoint files (optional - comment out if you want to keep them)
# file.remove(file.path(data_dir, "bootstrap_checkpoint_large.csv"))
# file.remove(file.path(data_dir, "bootstrap_checkpoint_small.csv"))