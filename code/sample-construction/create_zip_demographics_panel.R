# ==============================================================================
# Create Zip-Year Demographics Panel (ACS + IRS)
# ==============================================================================

rm(list=ls())

library(data.table)
library(dplyr)
library(stringr)
library(tidycensus)

data_dir <- "C:/OneDrive/data/nrs_branch_closure"

# ==============================================================================
# 1. Download and Process ACS Data
# ==============================================================================

states <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
            "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
            "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
            "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
            "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")

# ACS variables to retrieve
acs_vars <- c(
  median_income = "B19013_001",          # Median household income
  pct_college_educated = "B23006_023",   # Bachelor's degree (age 25+)
  total_education = "B23006_001",        # Total population 25+
  median_age = "B01002_001"              # Median age
)

# Download ACS data for all states and years
all_states_data <- list()

for(yr in 2010:2023) {
  for (state in states) {
    state_yr <- paste(state, yr)
    message("Getting data for state: ", state_yr)
    
    state_data <- get_acs(
      geography = "tract",
      variables = acs_vars,
      state = state,
      year = yr,
      survey = "acs5",
      output = "wide"
    )
    
    state_data <- data.table(state_data)
    state_data[, yr := yr]
    
    all_states_data[[state_yr]] <- state_data
  }
}

acs_data_combined <- rbindlist(all_states_data, fill = TRUE)

# Process ACS data
acs_data <- acs_data_combined %>%
  mutate(
    pct_college_educated = 100 * (pct_college_educatedE / total_educationE),
    median_income = median_incomeE,
    median_age = median_ageE
  ) %>%
  select(yr, GEOID, median_income, pct_college_educated, median_age) %>%
  rename(tract = GEOID) %>%
  data.table()

# ZIP-Tract crosswalk (HUD - https://www.huduser.gov/portal/datasets/usps_crosswalk.html)
tract_zip_crosswalk <- fread(file.path(data_dir, "ZIP_TRACT_032019.csv"))
tract_zip_crosswalk[, zip := str_pad(zip, 5, "left", "0")]
tract_zip_crosswalk[, tract := as.character(tract)]
tract_zip_crosswalk[, tract := str_pad(tract, 11, "left", "0")]

# IRS SOI data (IRS - https://www.irs.gov/statistics/soi-tax-stats-individual-income-tax-statistics-zip-code-data-soi)
irs_data <- readRDS(file.path(data_dir, "irs_data.rds"))
irs_data[, zipcode := str_pad(zipcode, 5, "left", "0")]

# Extend IRS data to 2023 using 2022 values
temp_2022 <- irs_data[yr == 2022]
temp_2023 <- copy(temp_2022)
temp_2023[, yr := 2023]
irs_data <- rbind(irs_data, temp_2023)

# ==============================================================================
# 2. Aggregate ACS from Tract to Zip Level
# ==============================================================================

# Join ACS data with ZIP-tract crosswalk
acs_with_zip <- acs_data %>%
  left_join(tract_zip_crosswalk[, c("zip", "tract", "tot_ratio")], by = c("tract" = "tract"))

# Aggregate to zip level using weighted averages
zip_aggregated_data <- acs_with_zip %>%
  group_by(zip, yr) %>%
  summarize(
    median_income = sum(median_income * tot_ratio, na.rm = TRUE),
    pct_college_educated = sum(pct_college_educated * tot_ratio, na.rm = TRUE),
    median_age = sum(median_age * tot_ratio, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  data.table()

# ==============================================================================
# 3. Merge ACS and IRS Data
# ==============================================================================

zip_demo_data <- merge(zip_aggregated_data, irs_data,
                       by.x = c("zip", "yr"),
                       by.y = c("zipcode", "yr"),
                       all.x = TRUE)

# ==============================================================================
# 4. Create Sophistication Indicators
# ==============================================================================

key_chars <- c("median_income", "median_age", "pct_college_educated", "capital_gain_frac", "dividend_frac")

# Create quintile bins by year
zip_demo_data[, paste0(key_chars, "_q") := lapply(.SD, function(x) ntile(x, 2)), 
              by = yr, .SDcols = key_chars]

# Sophistication indicator (high income + high education + high investment income)
zip_demo_data[, sophisticated_old := ifelse(
  !is.na(dividend_frac) & median_income_q == 2 & pct_college_educated_q == 2 & 
    (dividend_frac_q == 2 | capital_gain_frac_q == 2), 1,
  ifelse(!is.na(dividend_frac), 0, NA)
)]

# Sophistication (education + investment income only)
zip_demo_data[, sophisticated := ifelse(
  !is.na(dividend_frac) & pct_college_educated_q == 2 & 
    (dividend_frac_q == 2 | capital_gain_frac_q == 2), 1,
  ifelse(!is.na(dividend_frac), 0, NA)
)]

# Sophistication using only ACS variables
zip_demo_data[, sophisticated_acs_only := ifelse(
  median_income_q == 2 & pct_college_educated_q == 2, 1, 0
)]

# Age bins
zip_demo_data[, age_bin := ntile(median_age, 4), by = yr]

# Keep only final variables
zip_demo_data <- zip_demo_data[, c("zip", "yr", "median_income", "median_age", 
                                   "pct_college_educated", "capital_gain_frac", 
                                   "dividend_frac", "sophisticated", 
                                   "sophisticated_acs_only", "sophisticated_old",
                                   "age_bin")]

# ==============================================================================
# 5. Extend Data Backward (2000-2009) and Forward (2023-2025)
# ==============================================================================

# Backward fill: Use 2010 data for 2000-2009
temp_2010 <- zip_demo_data[yr == 2010]
for(y in 2000:2009) {
  temp <- copy(temp_2010)
  temp[, yr := y]
  zip_demo_data <- rbind(zip_demo_data, temp)
}


# Extend 2023 to 2024-2025
temp_2023 <- zip_demo_data[yr == 2023]
for(y in 2024:2025) {
  temp <- copy(temp_2023)
  temp[, yr := y]
  zip_demo_data <- rbind(zip_demo_data, temp)
}

# ==============================================================================
# 6. Save Output
# ==============================================================================

saveRDS(zip_demo_data, file = file.path(data_dir, "zip_demographics_panel.rds"))
