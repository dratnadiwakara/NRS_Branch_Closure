# ==============================================================================
# Create County-Year Control Variables Panel
# ==============================================================================

rm(list=ls())

library(data.table)
library(dplyr)
library(stringr)
library(DescTools)

data_dir <- "C:/OneDrive/data/nrs_branch_closure"

# ==============================================================================
# 1. Load Pre-processed Data Files
# ==============================================================================

# County Business Patterns - establishment and payroll growth (https://www.census.gov/programs-surveys/cbp/data/datasets.html)
cbp <- readRDS(file.path(data_dir, "cbp_county_gr.rds"))

# County-level GDP growth (https://www.bea.gov/data/gdp/gdp-county-metro-and-other-areas)
county_gdp <- readRDS(file.path(data_dir, "county_gdp.rds"))

# CRA small business lending growth (FFIEC) (https://www.ffiec.gov/data/cra/flat-files)
cra <- readRDS(file.path(data_dir, "cra_county_loan_gr.rds"))

# HMDA mortgage lending data (https://ffiec.cfpb.gov/data-publication/modified-lar/2024)
hmda <- readRDS(file.path(data_dir, "hmda_county_loan_gr.rds"))

# Low-to-Moderate Income indicator (FHFA - https://www.fhfa.gov/data/underserved-areas-data)
# equal weighted tract level LMI dummy. Interpretation frac of tracts within county that is LMI
lmi <- readRDS(file.path(data_dir, "lmi.rds"))

# Population-weighted LMI (created by code/sample-construction/create_lmi_population_weighted.R)
lmi_pop_weighted <- readRDS(file.path(data_dir, "lmi_population_weighted.rds"))

# County population density
county_population_density <- readRDS(file.path(data_dir, "county_population_density.rds"))

# ==============================================================================
# 2. Load Branch Data for County Deposits & HHI
# ==============================================================================

# Data created by: https://github.com/dratnadiwakara/r-utilities/blob/main/fdic-api/sod_download_all_data_to_rds.R
branch_year <- readRDS('C:/OneDrive/data/fdic_sod_2000_2025_simple.rds')
branch_year <- data.table(branch_year)

if("YEAR" %in% names(branch_year)) setnames(branch_year, "YEAR", "yr")

# Format STCNTYBR as 5-digit character string
branch_year[, STCNTYBR := str_pad(STCNTYBR, 5, "left", "0")]

# County deposits growth
county_deposits <- branch_year[, .(county_deposits = sum(DEPSUMBR, na.rm = TRUE)), by = .(STCNTYBR, yr)]
county_deposits <- county_deposits %>%
  arrange(STCNTYBR, yr) %>%
  group_by(STCNTYBR) %>%
  mutate(
    county_deposits_lag3 = lag(county_deposits, 3),
    county_deposit_gr = (county_deposits - county_deposits_lag3) / county_deposits_lag3,
    lag_county_deposit_gr = lag(county_deposit_gr) / 3
  ) %>%
  select(STCNTYBR, yr, lag_county_deposit_gr) %>%
  ungroup() %>%
  data.table()

# County deposit HHI
hhi <- branch_year[, c("DEPSUMBR", "STCNTYBR", "yr")]
hhi[, sum_deposits := sum(DEPSUMBR), by = .(STCNTYBR, yr)]
hhi[, mkt_share := (DEPSUMBR / sum_deposits)^2]
hhi <- hhi[, .(county_deposit_hhi = sum(mkt_share) + 0.01), by = .(STCNTYBR, yr)]

county_hhi <- hhi %>%
  arrange(STCNTYBR, yr) %>%
  group_by(STCNTYBR) %>%
  mutate(lag_county_deposit_hhi = lag(county_deposit_hhi)) %>%
  select(STCNTYBR, yr, lag_county_deposit_hhi) %>%
  ungroup() %>%
  data.table()

county_hhi <- county_hhi[!is.na(lag_county_deposit_hhi)]

# ==============================================================================
# 3. Merge All County Controls
# ==============================================================================

# Start with HMDA as base (adjust column names as needed based on actual data)
county_control_df <- copy(hmda)

# Standardize column names if needed
if("YEAR" %in% names(county_control_df)) setnames(county_control_df, "YEAR", "year")

# Filter out invalid county codes (must be 5-digit numeric strings)
county_control_df <- county_control_df[grepl("^\\d{5}$", county_code)]

# Merge county GDP
county_control_df <- merge(county_control_df, county_gdp, 
                           by = c("county_code", "year"), all.x = TRUE)

# Merge CRA
county_control_df <- merge(county_control_df, cra, 
                           by = c("county_code", "year"), all.x = TRUE)

# Merge LMI
county_control_df <- merge(county_control_df, lmi, 
                           by.x = c("county_code", "year"), 
                           by.y = c("county", "yr"), all.x = TRUE)

# Merge population-weighted LMI
county_control_df <- merge(county_control_df, lmi_pop_weighted, 
                           by.x = c("county_code", "year"), 
                           by.y = c("county", "yr"), all.x = TRUE)

# Merge population density
county_control_df <- merge(county_control_df, county_population_density,
                           by.x = c("county_code", "year"),
                           by.y = c("county", "yr"), all.x = TRUE)

# Merge CBP
county_control_df <- merge(county_control_df, cbp, 
                           by = c("county_code", "year"), all.x = TRUE)

# Merge county deposits
county_control_df <- merge(county_control_df, county_deposits, 
                           by.x = c("county_code", "year"), 
                           by.y = c("STCNTYBR", "yr"), all.x = TRUE)

# Merge county HHI
county_control_df <- merge(county_control_df, county_hhi, 
                           by.x = c("county_code", "year"), 
                           by.y = c("STCNTYBR", "yr"), all.x = TRUE)

# ==============================================================================
# 4. Fill Missing Values and Extend to Complete Panel
# ==============================================================================

# Get all unique counties
all_counties <- unique(county_control_df$county_code)

# Create complete county-year panel (2000-2025)
complete_panel <- CJ(county_code = all_counties, year = 2000:2025)

# Merge with existing data
county_control_df <- merge(complete_panel, county_control_df, 
                           by = c("county_code", "year"), all.x = TRUE)

# Identify all control variables
control_vars <- c("lag_hmda_mtg_amt_gr", "lag_cra_loan_amount_amt_lt_1m_gr",
                  "lag_county_deposit_gr", "lag_county_deposit_hhi", "lmi", "population_density", 
                  "lag_establishment_gr", "lag_payroll_gr", "log_population_density")

# Keep only variables that exist in the data
control_vars <- control_vars[control_vars %in% names(county_control_df)]

# Fill missing values within each county using forward then backward fill
county_control_df <- county_control_df[order(county_code, year)]

for(var in control_vars) {
  # Forward fill (last observation carried forward)
  county_control_df[, (var) := nafill(get(var), type = "locf"), by = county_code]
  # Backward fill for any remaining NAs at the start
  county_control_df[, (var) := nafill(get(var), type = "nocb"), by = county_code]
  # Do another forward fill pass to ensure 2024-2025 are filled
  county_control_df[, (var) := nafill(get(var), type = "locf"), by = county_code]
}

# ==============================================================================
# 5. Winsorize Control Variables
# ==============================================================================

# Winsorize after filling missing values
county_control_df[, (control_vars) := lapply(.SD, function(x) {
  Winsorize(x, quantile(x, probs=c(0.025, 0.975), na.rm = T))
}), by = year, .SDcols = control_vars]

# ==============================================================================
# 6. Save Output
# ==============================================================================

saveRDS(county_control_df, file = file.path(data_dir, "county_controls_panel_02192026.rds"))
