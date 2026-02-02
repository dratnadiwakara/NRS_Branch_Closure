# ==============================================================================
# Create Branch Closure Panel from FDIC SOD Data
# ==============================================================================

rm(list=ls())

library(data.table)
library(dplyr)
library(stringr)
library(ggplot2)


# ==============================================================================
# 1. Load and Prepare Data
# ==============================================================================

# Data created by: https://github.com/dratnadiwakara/r-utilities/blob/main/fdic-api/sod_download_all_data_to_rds.R
branch_year <- readRDS('C:/OneDrive/data/fdic_sod_1995_2025_simple.rds')
branch_year <- data.table(branch_year)

# Standardize column names
if("YEAR" %in% names(branch_year)) setnames(branch_year, "YEAR", "yr")
if("ZIPBR" %in% names(branch_year)) setnames(branch_year, "ZIPBR", "zip")

# Format zip codes (5 digits with leading zeros)
branch_year[, zip := str_pad(zip, 5, "left", "0")]

# ==============================================================================
# 2. Create Closure Data
# ==============================================================================

# Get global max year for closure detection
max_year <- max(branch_year$yr, na.rm = TRUE)

closure_data <- branch_year %>%
  arrange(UNINUMBR, yr) %>%
  group_by(UNINUMBR) %>%
  mutate(
    # Merger indicator (bank ID changed from prior year)
    lag1_bank = lag(RSSDID, 1),
    lag3_bank = lag(RSSDID, 3),
    merged_1_year = ifelse(RSSDID != lag1_bank, 1, 0),
    merged_last_3_yrs = ifelse(merged_1_year == 1 | lag(merged_1_year, 1) == 1 | lag(merged_1_year, 2) == 1, 1, 0),
    
    # Closure indicator (branch disappears before final year in dataset)
    closed = ifelse(is.na(lead(yr)) & yr < max_year, 1, 0),
    
    # Deposit growth
    lag_branch_deposit_amount = lag(DEPSUMBR),
    deposit_gr_3yrs_branch = lag(DEPSUMBR) * 100 / lag(DEPSUMBR, 3),
    
    # Legacy branch (same bank for 3+ years)
    legacy_branch = ifelse(lag3_bank == RSSDID, 1, 0),
    
    # Keep only observations before first closure
    keep = lag(cumsum(closed == 1), default = 0) <= 0
  ) %>%
  filter(keep) %>%
  select(-keep, -lag1_bank, -lag3_bank) %>%
  ungroup() %>%
  data.table()

# Replace NAs with 0 for indicator variables
closure_data[is.na(merged_1_year), merged_1_year := 0]
closure_data[is.na(merged_last_3_yrs), merged_last_3_yrs := 0]
closure_data[is.na(legacy_branch), legacy_branch := 1] # ~90% of branches are legacy branches
closure_data <- closure_data[yr < 2025] 
# ==============================================================================
# 3. Create Closure Rate Plot
# ==============================================================================

closure_by_year <- closure_data[, .(
  total_branches = .N,
  closed_branches = sum(closed, na.rm = TRUE),
  pct_closed = 100 * sum(closed, na.rm = TRUE) / .N
), by = yr]

p1 <- ggplot(closure_by_year, aes(x = yr, y = pct_closed)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  labs(
    title = "Branch Closure Rate by Year",
    x = "Year",
    y = "Percent of Branches Closed (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 11)
  )

p2 <- ggplot(closure_by_year, aes(x = yr, y = closed_branches)) +
  geom_line(linewidth = 1, color = "darkred") +
  geom_point(size = 2, color = "darkred") +
  labs(
    title = "Number of Branch Closures by Year",
    x = "Year",
    y = "Number of Branches Closed"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 11)
  )

print(p1)
print(p2)

# ==============================================================================
# 4. Identify Same-Zip Prior Branches (for merged branches)
# ==============================================================================
# Check if acquiring bank had other branches in same zip within prior 3 years

merged_branches <- which(closure_data$merged_1_year == 1)
closure_data[, same_zip_prior_branches := 0]

pb <- txtProgressBar(min = 0, max = length(merged_branches), style = 3)

for(idx in seq_along(merged_branches)) {
  i <- merged_branches[idx]
  setTxtProgressBar(pb, idx)
  
  # Check for same bank's branches in same zip in prior 3 years
  has_prior <- closure_data[
    yr >= (closure_data[i,]$yr - 3) & yr <= (closure_data[i,]$yr - 1) &
    zip == closure_data[i,]$zip &
    RSSDID == closure_data[i,]$RSSDID &
    UNINUMBR != closure_data[i,]$UNINUMBR,
    .N
  ] > 0
  
  if(has_prior) closure_data[i, same_zip_prior_branches := 1]
}
close(pb)

# ==============================================================================
# 5. Create Final Panel
# ==============================================================================

branch_df <- closure_data %>%
  arrange(UNINUMBR, yr) %>%
  group_by(UNINUMBR) %>%
  mutate(
    # 3-year window for same-zip prior branches
    same_zip_prior_3yr_branches = ifelse(
      same_zip_prior_branches == 1 | lag(same_zip_prior_branches, 1) == 1 | lag(same_zip_prior_branches, 2) == 1, 
      1, 0
    )
  ) %>%
  ungroup() %>%
  data.table()

branch_df[is.na(same_zip_prior_3yr_branches), same_zip_prior_3yr_branches := 0]

# ==============================================================================
# 6. Save Output
# ==============================================================================

# Restrict to years 2000-2024 for final output
branch_df <- branch_df[yr >= 2000 & yr <= 2024]

saveRDS(branch_df, file = "C:/OneDrive/data/nrs_branch_closure/branch_closure_panel.rds")
