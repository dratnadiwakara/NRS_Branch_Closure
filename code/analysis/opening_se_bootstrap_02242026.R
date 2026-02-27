

# ==============================================================================
# Two-Stage Bootstrap for Branch Opening Regressions
# ==============================================================================
# Stage 1: Bootstrap bank-level deposit beta regressions
# Stage 2: Bootstrap bank opening regressions using predicted deposit betas
# ==============================================================================

rm(list = ls())
gc()

library(data.table)
library(fixest)

options(fixest_warn = FALSE, warn = -1)

data_dir <- "data/"

# ==============================================================================
# 1. LOAD AND PREPARE DATA
# ==============================================================================

# Load data
beta_cycles_original <- readRDS(file.path(data_dir, "deposit_beta_results_v02172026.rds"))
opening_sample <- readRDS(file.path(data_dir, "branch_opening_analysis_sample_with_deposit_beta_v3.rds"))
setDT(opening_sample)

# Define large banks (>$100M in 2024 dollars)
cpi <- readRDS(file.path(data_dir, "cpi.rds"))
cpi[, asset_cutoff := (CPI / CPI[year == 2024]) * 100000000]

all_banks <- unique(opening_sample[, .(RSSDID, yr, bank_assets)])
all_banks <- merge(all_banks, cpi[, .(year, asset_cutoff)], by.x = "yr", by.y = "year")
large_banks <- unique(all_banks[bank_assets > asset_cutoff]$RSSDID)

opening_sample[, `:=`(
  large_bank = fifelse(RSSDID %in% large_banks, 1L, 0L),
  state = substr(COUNTY, 1, 2),
  factor_age_bin = as.factor(age_bin)
)]
opening_sample[, `:=`(state_yr = paste(state, yr, sep = "_"),
                      bank_yr = paste(RSSDID, yr))]

rm(all_banks, cpi)
gc()

# ==============================================================================
# 2. DEFINE INTEREST RATE CYCLES
# ==============================================================================

cycles_definition <- list(
  cycle_0406 = list(rate_change = 3.5),
  cycle_1619 = list(rate_change = 2.5),
  cycle_2224 = list(rate_change = 4.0)
)

# ==============================================================================
# 3. CONTROL VARIABLES FOR SECOND STAGE
# ==============================================================================

setFixest_fml(
  ..ctrl = ~ log_zip_deposits + lag_county_deposit_gr + lag_hmda_mtg_amt_gr + 
    lag_cra_loan_amount_amt_lt_1m_gr + lag_establishment_gr + lag_payroll_gr + lmi +
    log1p(lag_county_cra_volume) + log1p(lag_county_mortgage_volume) + 
    log1p(family_income) | state_yr + bank_yr
)

# ==============================================================================
# 4. ORIGINAL REGRESSIONS (FOR COMPARISON)
# ==============================================================================

reg_large_original <- feols(new_branch_zip ~ deposit_beta + ..ctrl,
                            data = opening_sample[large_bank == 1], vcov = ~RSSDID)
reg_small_original <- feols(new_branch_zip ~ deposit_beta + ..ctrl,
                            data = opening_sample[large_bank == 0], vcov = ~RSSDID)

cat("\n=== ORIGINAL RESULTS ===\n")
cat("Large banks - Coef:", coef(reg_large_original)["deposit_beta"],
    "SE:", se(reg_large_original)["deposit_beta"], "\n")
cat("Small banks - Coef:", coef(reg_small_original)["deposit_beta"],
    "SE:", se(reg_small_original)["deposit_beta"], "\n")

gc()

# ==============================================================================
# 5. TWO-STAGE BOOTSTRAP FUNCTION
# ==============================================================================

bootstrap_two_stage <- function(opening_data, beta_original, cycles_def,
                                bank_size = "large", n_boot = 500, seed = 123,
                                checkpoint_file = NULL, checkpoint_freq = 10) {
  
  set.seed(seed)
  
  # Filter by bank size
  analysis_data <- if (bank_size == "large") {
    opening_data[large_bank == 1]
  } else if (bank_size == "small") {
    opening_data[large_bank == 0]
  } else {
    opening_data
  }
  
  opening_banks <- unique(analysis_data$RSSDID)
  n_banks <- length(opening_banks)
  boot_coefs <- rep(NA, n_boot)
  
  # Load checkpoint if exists
  start_iter <- 1
  if (!is.null(checkpoint_file) && file.exists(checkpoint_file)) {
    checkpoint_data <- fread(checkpoint_file)
    if (all(c("iteration", "coefficient") %in% names(checkpoint_data))) {
      boot_coefs[checkpoint_data$iteration] <- checkpoint_data$coefficient
      completed <- checkpoint_data[!is.na(coefficient), iteration]
      if (length(completed) > 0) {
        start_iter <- max(completed) + 1
        cat("Resuming from iteration", start_iter, "\n")
      }
    }
  }
  
  cat("Starting", n_boot, "bootstrap iterations for", bank_size, "banks\n")
  
  # Bootstrap loop
  for (b in start_iter:n_boot) {
    if (b %% 10 == 0) cat("Iteration:", b, "/", n_boot, "\n")
    
    tryCatch({
      
      # ===== STAGE 1: Bootstrap deposit beta regressions =====
      boot_beta_models <- list()
      
      for (cycle_name in names(cycles_def)) {
        # Get original bank demographics for this cycle
        bank_demos <- beta_original[[cycle_name]]$data
        demo_banks <- unique(bank_demos$ID_RSSD)
        
        # Bootstrap sample banks with replacement
        boot_banks <- sample(demo_banks, length(demo_banks), replace = TRUE)
        boot_demos <- rbindlist(lapply(boot_banks, function(id) bank_demos[ID_RSSD == id]))
        
        # Re-estimate deposit beta regression
        suppressWarnings(suppressMessages({
          boot_reg <- feols(
            deposit_exp_chg ~ factor_age_bin + dividend_frac + college_frac + 
              log(family_income) + bank_hhi + log(bank_assets) + population_density +
              trans_accts_frac_assets + uninsured_deposits_frac + time_deposits_assets,
            data = boot_demos,
            warn = FALSE, notes = FALSE
          )
        }))
        
        boot_beta_models[[cycle_name]] <- boot_reg
      }
      
      # ===== STAGE 2: Bootstrap opening regression =====
      # Resample banks
      boot_opening_banks <- sample(opening_banks, n_banks, replace = TRUE)
      boot_sample <- rbindlist(lapply(boot_opening_banks, function(id) {
        analysis_data[RSSDID == id]
      }))
      
      # Predict deposit beta for each cycle
      for (i in seq_along(boot_beta_models)) {
        cycle_nm <- names(boot_beta_models)[i]
        suppressWarnings({
          boot_sample[, pred := predict(boot_beta_models[[i]], newdata = boot_sample)]
        })
        setnames(boot_sample, "pred", paste0("pred_", cycle_nm))
      }
      
      # Assign deposit_beta based on year
      boot_sample[, deposit_beta := fcase(
        yr <= 2014, pred_cycle_0406 / cycles_def$cycle_0406$rate_change,
        yr <= 2019, pred_cycle_1619 / cycles_def$cycle_1619$rate_change,
        default = pred_cycle_2224 / cycles_def$cycle_2224$rate_change
      )]
      
      # Run opening regression
      suppressWarnings(suppressMessages({
        boot_reg <- feols(new_branch_zip ~ deposit_beta + ..ctrl,
                          data = boot_sample, warn = FALSE, notes = FALSE)
      }))
      
      boot_coefs[b] <- coef(boot_reg)["deposit_beta"]
      
      # Save checkpoint
      if (!is.null(checkpoint_file) && (b %% checkpoint_freq == 0 || b == n_boot)) {
        save_checkpoint(checkpoint_file, boot_coefs[1:b], b, bank_size, n_boot)
      }
      
    }, error = function(e) {
      cat("Error in iteration", b, ":", conditionMessage(e), "\n")
      boot_coefs[b] <- NA
      if (!is.null(checkpoint_file)) {
        save_checkpoint(checkpoint_file, boot_coefs[1:b], b, bank_size, n_boot)
      }
    })
  }
  
  # Calculate results
  boot_se <- sd(boot_coefs, na.rm = TRUE)
  boot_ci <- quantile(boot_coefs, c(0.025, 0.975), na.rm = TRUE)
  n_successful <- sum(!is.na(boot_coefs))
  
  cat("\nBootstrap complete:", n_successful, "/", n_boot, "successful\n")
  cat("SE:", round(boot_se, 4), "| 95% CI: [", 
      round(boot_ci[1], 4), ",", round(boot_ci[2], 4), "]\n")
  
  # Save final summary
  if (!is.null(checkpoint_file)) {
    final_file <- gsub("\\.csv$", "_final.csv", checkpoint_file)
    fwrite(data.table(
      bank_size = bank_size,
      n_boot = n_boot,
      n_successful = n_successful,
      mean = mean(boot_coefs, na.rm = TRUE),
      se = boot_se,
      ci_lower = boot_ci[1],
      ci_upper = boot_ci[2],
      timestamp = Sys.time()
    ), final_file)
  }
  
  return(list(
    coefs = boot_coefs,
    se = boot_se,
    ci = boot_ci,
    n_successful = n_successful
  ))
}

# ==============================================================================
# HELPER: Save checkpoint
# ==============================================================================

save_checkpoint <- function(checkpoint_file, coefs, current_iter, bank_size, n_boot) {
  # Save iteration-level data
  fwrite(data.table(
    iteration = 1:current_iter,
    coefficient = coefs,
    timestamp = Sys.time()
  ), checkpoint_file)
  
  # Save summary
  completed_coefs <- coefs[!is.na(coefs)]
  if (length(completed_coefs) > 0) {
    summary_file <- gsub("\\.csv$", "_summary.csv", checkpoint_file)
    fwrite(data.table(
      bank_size = bank_size,
      total_iterations = n_boot,
      completed_iterations = length(completed_coefs),
      current_iteration = current_iter,
      mean = mean(completed_coefs),
      se = sd(completed_coefs),
      ci_lower = quantile(completed_coefs, 0.025),
      ci_upper = quantile(completed_coefs, 0.975),
      timestamp = Sys.time()
    ), summary_file)
  }
}

# ==============================================================================
# 6. RUN BOOTSTRAP
# ==============================================================================

# Example usage:
# results_large <- bootstrap_two_stage(
#   opening_sample, 
#   beta_original = beta_cycles_original, 
#   cycles_definition,
#   bank_size = "large", 
#   n_boot = 500,
#   checkpoint_file = "bootstrap_large.csv"
# )



cat("\n=== BOOTSTRAPPING LARGE BANKS (OPENING) ===\n")
boot_large <- bootstrap_two_stage(
  opening_sample,
  beta_original = beta_cycles_original,
  cycles_definition,
  bank_size = "large",
  n_boot = 500,
  checkpoint_file = file.path(data_dir, "bootstrap_checkpoint_opening_large.csv")
)


cat("\n=== BOOTSTRAPPING SMALL BANKS (OPENING) ===\n")
boot_small <- bootstrap_two_stage(
  opening_sample,
  beta_original = beta_cycles_original,
  cycles_definition,
  bank_size = "small",
  n_boot = 110,
  checkpoint_file = file.path(data_dir, "bootstrap_checkpoint_opening_small.csv")
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
cat("  Bootstrap SE (two-stage):", round(boot_large$se, 4), "\n")
cat("  Bootstrap 95% CI: [", round(boot_large$ci[1], 4), ",",
    round(boot_large$ci[2], 4), "]\n")
cat("  SE inflation factor:", round(boot_large$se / se(reg_large_original)["deposit_beta"], 2), "\n")
cat("  T-stat (original):", round(coef(reg_large_original)["deposit_beta"] /
                                    se(reg_large_original)["deposit_beta"], 2), "\n")
cat("  T-stat (bootstrap):", round(coef(reg_large_original)["deposit_beta"] /
                                     boot_large$se, 2), "\n")

cat("\nSMALL BANKS:\n")
cat("  Original coefficient:", round(coef(reg_small_original)["deposit_beta"], 4), "\n")
cat("  Original SE (clustered):", round(se(reg_small_original)["deposit_beta"], 4), "\n")
cat("  Bootstrap SE (two-stage):", round(boot_small$se, 4), "\n")
cat("  Bootstrap 95% CI: [", round(boot_small$ci[1], 4), ",",
    round(boot_small$ci[2], 4), "]\n")
cat("  SE inflation factor:", round(boot_small$se / se(reg_small_original)["deposit_beta"], 2), "\n")
cat("  T-stat (original):", round(coef(reg_small_original)["deposit_beta"] /
                                    se(reg_small_original)["deposit_beta"], 2), "\n")
cat("  T-stat (bootstrap):", round(coef(reg_small_original)["deposit_beta"] /
                                     boot_small$se, 2), "\n")

comparison_table <- data.table(
  Bank_Size = c("Large", "Small"),
  Coefficient = c(coef(reg_large_original)["deposit_beta"],
                  coef(reg_small_original)["deposit_beta"]),
  SE_Clustered = c(se(reg_large_original)["deposit_beta"],
                   se(reg_small_original)["deposit_beta"]),
  SE_Bootstrap = c(boot_large$se, boot_small$se),
  CI_Lower = c(boot_large$ci[1], boot_small$ci[1]),
  CI_Upper = c(boot_large$ci[2], boot_small$ci[2]),
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
  coefficient = c(boot_large$coefs, boot_small$coefs),
  bank_size = c(rep("Large Banks", length(boot_large$coefs)),
                rep("Small Banks", length(boot_small$coefs)))
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
