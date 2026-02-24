# ==============================================================================
# Two-Stage Bootstrap for Branch Opening Regressions (with Checkpointing)
# ==============================================================================
# This script implements a full two-stage bootstrap that:
# 1. Re-estimates bank-level deposit beta regressions (first stage)
# 2. Re-estimates bank-zip-year opening regressions (second stage)
# This properly accounts for generated regressor uncertainty.
# Deposit beta is NOT used from the opening sample; it is re-estimated from
# the sampled banks within each bootstrap iteration (like closure_se_bootstrap).
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

# Load original deposit beta results (for benchmark regressions only)
beta_cycles_original <- readRDS(file.path(data_dir, "deposit_beta_results_v02172026.rds"))

# Load opening sample - drop deposit_beta; we will re-estimate it
# Data created by code/sample-construction/create_opening_analysis_sample_v2.0.R
opening_sample <- readRDS(file.path(data_dir, "branch_opening_analysis_sample_with_deposit_beta_v3.rds"))
# Load branch closure sample for first-stage demographic aggregation
# Data created by code/sample-construction/create_closure_analysis_sample_02172026.R
branch_sample <- readRDS(file.path(data_dir, "branch_closure_analysis_sample_02172026.rds"))

setDT(opening_sample)
opening_sample[, deposit_beta := NULL]  # Do NOT use pre-calculated deposit_beta

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
# Same logic as key_opening_results_02202026.qmd

cpi <- readRDS(file.path(data_dir, "cpi.rds"))
cpi[, adj_ratio := CPI / CPI[year == 2024]]
cpi[, asset_cutoff := adj_ratio * 100000000]

all_banks <- unique(opening_sample[, .(RSSDID, yr, bank_assets)])
all_banks <- merge(all_banks, cpi[, .(year, asset_cutoff)], by.x = "yr", by.y = "year", all.x = TRUE)
large_banks <- unique(all_banks[bank_assets > asset_cutoff]$RSSDID)

opening_sample[, large_bank := fifelse(RSSDID %in% large_banks, 1L, 0L)]

# Create state-year fixed effect variable (same as key_opening_results)
opening_sample[, state := substr(COUNTY, 1, 2)]
opening_sample[, state_yr := paste(state, yr, sep = "_")]
opening_sample[, bank_yr := paste(RSSDID, yr)]

rm(all_banks, cpi)
gc()

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
# Aggregate bank-level demographics from opening sample (bank-zip-year).
# Weight zip-level vars by zip_deposits (total deposits in zip); bank-level
# vars are constant within bank-year so take first().

aggregate_bank_demographics_from_opening <- function(data, yr_filter) {
  dt <- data[yr == yr_filter]
  dt[, zip_weight := zip_deposits / sum(zip_deposits, na.rm = TRUE), by = RSSDID]

  bank_agg <- dt[, .(
    college_frac = sum(college_frac * zip_weight, na.rm = TRUE) + 0.01,
    dividend_frac = sum(dividend_frac * zip_weight, na.rm = TRUE) + 0.01,
    family_income = sum(family_income * zip_weight, na.rm = TRUE) + 1,
    population_density = sum(population_density * zip_weight, na.rm = TRUE),
    sophisticated_frac = sum(sophisticated * deposit_weight, na.rm = TRUE),
    core_deposits_assets = first(core_deposits_assets),
    age_bin = floor(median(age_bin, na.rm = TRUE)),
    bank_hhi = first(bank_hhi),
    ci_assets = first(ci_assets),
    brokered_deposits_assets = first(brokered_deposits_assets),
    bank_assets = first(bank_assets),
    trans_accts_frac_assets = first(trans_accts_frac_assets),
    time_deposits_assets = first(time_deposits_assets),
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
  ..ctrl_state_opening = ~ log_zip_deposits + lag_county_deposit_gr +
    lag_hmda_mtg_amt_gr + lag_cra_loan_amount_amt_lt_1m_gr +
    lag_establishment_gr + lag_payroll_gr + lmi +
    log1p(lag_county_cra_volume) + log1p(lag_county_mortgage_volume) + log1p(family_income) |
    state_yr + bank_yr
)

# ==============================================================================
# 6. Run Original Regressions (for comparison)
# ==============================================================================
# Compute deposit_beta from original beta_cycles (not from opening sample)

opening_sample[, factor_age_bin := as.factor(age_bin)]

for (i in seq_along(beta_cycles_original)) {
  cycle_nm <- names(beta_cycles_original)[i]
  suppressWarnings({
    opening_sample[, pred_int_exp_chg := predict(beta_cycles_original[[i]]$reg,
                                                  newdata = opening_sample)]
  })
  setnames(opening_sample, "pred_int_exp_chg", paste0("pred_int_exp_chg_", cycle_nm))
}

opening_sample[, deposit_beta := ifelse(yr <= 2014, pred_int_exp_chg_cycle_0406 / 3.5,
                                       ifelse(yr <= 2019, pred_int_exp_chg_cycle_1619 / 2.5,
                                              pred_int_exp_chg_cycle_2224 / 4))]

# Filter to rows with valid deposit_beta for original regressions
opening_valid <- opening_sample[!is.na(deposit_beta)]

reg_large_original <- feols(new_branch_zip ~ deposit_beta + ..ctrl_state_opening,
                            data = opening_valid[large_bank == 1], vcov = ~RSSDID)

reg_small_original <- feols(new_branch_zip ~ deposit_beta + ..ctrl_state_opening,
                            data = opening_valid[large_bank == 0], vcov = ~RSSDID)

cat("\n=== ORIGINAL RESULTS ===\n")
cat("Large banks - Coefficient:", coef(reg_large_original)["deposit_beta"],
    "SE:", se(reg_large_original)["deposit_beta"], "\n")
cat("Small banks - Coefficient:", coef(reg_small_original)["deposit_beta"],
    "SE:", se(reg_small_original)["deposit_beta"], "\n")

# Remove pred columns from opening_sample before bootstrap (we'll recompute)
opening_sample[, c("pred_int_exp_chg_cycle_0406", "pred_int_exp_chg_cycle_1619",
                   "pred_int_exp_chg_cycle_2224", "deposit_beta") := NULL]
gc()

# ==============================================================================
# 7. Two-Stage Bootstrap Function (with Checkpointing)
# ==============================================================================

bootstrap_two_stage_opening <- function(opening_data, call_data, cycles_def,
                                        bank_size = "large", n_boot = 500, seed = 123,
                                        checkpoint_file = NULL, checkpoint_freq = 10) {

  set.seed(seed)

  # Filter opening data by bank size
  if (bank_size == "large") {
    analysis_data <- opening_data[large_bank == 1]
  } else if (bank_size == "small") {
    analysis_data <- opening_data[large_bank == 0]
  } else {
    analysis_data <- opening_data
  }

  opening_banks <- unique(analysis_data$RSSDID)
  n_opening_banks <- length(opening_banks)

  boot_coefs <- rep(NA, n_boot)

  # Check for existing checkpoint file
  start_iter <- 1
  if (!is.null(checkpoint_file) && file.exists(checkpoint_file)) {
    cat("\nFound existing checkpoint file:", checkpoint_file, "\n")
    checkpoint_data <- fread(checkpoint_file)

    if (all(c("iteration", "coefficient") %in% names(checkpoint_data))) {
      boot_coefs[checkpoint_data$iteration] <- checkpoint_data$coefficient
      completed_iters <- checkpoint_data[!is.na(coefficient), iteration]

      if (length(completed_iters) > 0) {
        start_iter <- max(completed_iters) + 1
        cat("Loaded", length(completed_iters), "completed iterations\n")
        cat("Resuming from iteration:", start_iter, "\n")
        current_se <- sd(boot_coefs[1:(start_iter - 1)], na.rm = TRUE)
        current_ci <- quantile(boot_coefs[1:(start_iter - 1)], c(0.025, 0.975), na.rm = TRUE)
        cat("Current bootstrap SE:", round(current_se, 4), "\n")
        cat("Current 95% CI: [", round(current_ci[1], 4), ",", round(current_ci[2], 4), "]\n")
      }
    } else {
      cat("Warning: Checkpoint file missing required columns. Starting fresh.\n")
      start_iter <- 1
    }
  } else if (!is.null(checkpoint_file)) {
    cat("\nNo checkpoint file found. Starting fresh.\n")
    cat("Will save checkpoints to:", checkpoint_file, "\n")
  }

  cat("\nStarting", n_boot, "bootstrap iterations for", bank_size, "banks (opening)...\n")

  for (b in start_iter:n_boot) {
    if (b %% 10 == 0) {
      cat("Iteration:", b, "/", n_boot)
      if (b >= 50 && b %% 50 == 0) {
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

      for (cycle_name in names(cycles_def)) {
        cycle <- cycles_def[[cycle_name]]

        suppressMessages({
          bank_demos <- aggregate_bank_demographics_from_opening(opening_data, cycle$demo_year)
        })

        demo_banks <- unique(bank_demos$RSSDID)
        n_demo_banks <- length(demo_banks)
        boot_demo_banks <- sample(demo_banks, n_demo_banks, replace = TRUE)

        boot_bank_demos <- rbindlist(lapply(boot_demo_banks, function(bank_id) {
          bank_demos[RSSDID == bank_id]
        }))

        boot_cycle_data <- calculate_cycle_beta(call_data, boot_bank_demos,
                                                cycle$start_date, cycle$end_date)

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

        boot_beta_cycles[[cycle_name]] <- list(reg = boot_reg, data = boot_cycle_data)
      }

      # ===== STAGE 2: Resample banks, predict deposit_beta, run opening regression =====
      boot_opening_banks <- sample(opening_banks, n_opening_banks, replace = TRUE)
      boot_opening_sample <- rbindlist(lapply(boot_opening_banks, function(bank_id) {
        analysis_data[RSSDID == bank_id]
      }))

      boot_opening_sample[, factor_age_bin := as.factor(age_bin)]

      for (i in seq_along(boot_beta_cycles)) {
        cycle_nm <- names(boot_beta_cycles)[i]
        suppressWarnings({
          boot_opening_sample[, pred_int_exp_chg := predict(boot_beta_cycles[[i]]$reg,
                                                            newdata = boot_opening_sample)]
        })
        setnames(boot_opening_sample, "pred_int_exp_chg", paste0("pred_int_exp_chg_", cycle_nm))
      }

      boot_opening_sample[, deposit_beta := ifelse(yr <= 2014,
                                                   pred_int_exp_chg_cycle_0406 / 3.5,
                                                   ifelse(yr <= 2019,
                                                          pred_int_exp_chg_cycle_1619 / 2.5,
                                                          pred_int_exp_chg_cycle_2224 / 4))]

      suppressWarnings(suppressMessages({
        boot_open_reg <- feols(new_branch_zip ~ deposit_beta + ..ctrl_state_opening,
                               data = boot_opening_sample,
                               warn = FALSE,
                               notes = FALSE)
      }))

      boot_coefs[b] <- coef(boot_open_reg)["deposit_beta"]

      # Save checkpoint
      if (!is.null(checkpoint_file) && (b %% checkpoint_freq == 0 || b == n_boot)) {
        checkpoint_dt <- data.table(
          iteration = 1:b,
          coefficient = boot_coefs[1:b],
          is_complete = !is.na(boot_coefs[1:b]),
          timestamp = Sys.time()
        )
        fwrite(checkpoint_dt, checkpoint_file)

        completed_coefs <- boot_coefs[1:b][!is.na(boot_coefs[1:b])]
        if (length(completed_coefs) > 0) {
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
            timestamp = Sys.time()
          )
          fwrite(summary_dt, summary_file)
        }
        if (b %% 50 == 0) cat("  Checkpoint saved at iteration", b, "\n")
      }

    }, error = function(e) {
      cat("Error in iteration", b, ":", conditionMessage(e), "\n")
      boot_coefs[b] <- NA
      if (!is.null(checkpoint_file)) {
        checkpoint_dt <- data.table(
          iteration = 1:b,
          coefficient = boot_coefs[1:b],
          is_complete = !is.na(boot_coefs[1:b]),
          timestamp = Sys.time()
        )
        fwrite(checkpoint_dt, checkpoint_file)
        completed_coefs <- boot_coefs[1:b][!is.na(boot_coefs[1:b])]
        if (length(completed_coefs) > 0) {
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

  boot_se <- sd(boot_coefs, na.rm = TRUE)
  boot_ci <- quantile(boot_coefs, c(0.025, 0.975), na.rm = TRUE)
  boot_mean <- mean(boot_coefs, na.rm = TRUE)
  n_successful <- sum(!is.na(boot_coefs))

  cat("\nBootstrap complete:", n_successful, "/", n_boot, "iterations successful\n")

  if (!is.null(checkpoint_file)) {
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

  branch_data = branch_sample,
cat("\n=== BOOTSTRAPPING LARGE BANKS (OPENING) ===\n")
boot_large <- bootstrap_two_stage_opening(
  opening_data = opening_sample,
  call_data = call_data,
  cycles_def = cycles_definition,
  bank_size = "large",
  n_boot = 500,
  seed = 123,
  checkpoint_file = file.path(data_dir, "bootstrap_checkpoint_opening_large.csv"),
  checkpoint_freq = 10
)
  branch_data = branch_sample,

cat("\n=== BOOTSTRAPPING SMALL BANKS (OPENING) ===\n")
boot_small <- bootstrap_two_stage_opening(
  opening_data = opening_sample,
  call_data = call_data,
  cycles_def = cycles_definition,
  bank_size = "small",
  n_boot = 500,
  seed = 456,
  checkpoint_file = file.path(data_dir, "bootstrap_checkpoint_opening_small.csv"),
  checkpoint_freq = 10
)

# ==============================================================================
# 9. Display Results
# ==============================================================================

cat("\n", rep("=", 80), "\n", sep = "")
cat("FINAL RESULTS (OPENING)\n")
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
  labs(x = "Coefficient on Deposit Beta (Opening)",
       y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

print(p)

# Save plot per workspace conventions (relative to code/analysis)
dat_suffix <- format(Sys.Date(), "%m%d%Y")
ggsave(
  filename = paste0("../../docs/figures/bootstrap_distribution_opening_", dat_suffix, ".png"),
  plot = p,
  width = 8,
  height = 6,
  bg = "transparent"
)

# ==============================================================================
# 11. Save Results
# ==============================================================================

bootstrap_results_opening <- list(
  large_banks = boot_large,
  small_banks = boot_small,
  comparison_table = comparison_table,
  original_regs = list(
    large = reg_large_original,
    small = reg_small_original
  )
)

saveRDS(bootstrap_results_opening,
        file = file.path(data_dir, "bootstrap_results_opening_two_stage.rds"))

cat("\nResults saved to:", file.path(data_dir, "bootstrap_results_opening_two_stage.rds"), "\n")
