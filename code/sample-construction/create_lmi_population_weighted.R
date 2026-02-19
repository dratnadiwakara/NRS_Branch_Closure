# ==============================================================================
# Create County-Year Population-Weighted LMI (Low-Income Area) Panel
# ==============================================================================
# Output: lmi_population_weighted.rds with columns county, yr, pop_w_lmi.
# Data lineage: LYA from FHFA Underserved Areas (https://www.fhfa.gov/data/underserved-areas-data);
# tract population from Census ACS 5-year B01003_001 via tidycensus.
# ==============================================================================

rm(list = ls())

library(data.table)
library(stringr)
library(tidycensus)

data_path <- "C:/OneDrive/data/nrs_branch_closure"
lya_path  <- "C:/OneDrive/data/lmi-lya/"

# ==============================================================================
# 1. Tract population (ACS 5-year, single vintage for all LYA years)
# ==============================================================================
# Cached file created by this script; source: Census API via tidycensus (B01003_001).
tract_pop_path <- file.path(data_path, "tract_population_acs5_2013.rds")

if (file.exists(tract_pop_path)) {
  tract_pop <- readRDS(tract_pop_path)
} else {
  # ACS 5-year total population at tract level (year 2013 to align with LYA backfill).
  # Tracts with zero/NA population excluded from weighting denominator later.
  states_acs <- c(state.abb, "DC", "PR")
  tract_pop_list <- list()
  for (st in states_acs) {
    tryCatch({
      d <- get_acs(
        geography = "tract",
        variables = "B01003_001",
        state = st,
        year = 2019,
        survey = "acs5",
        output = "wide"
      )
      tract_pop_list[[st]] <- data.table(
        tract_id = d$GEOID,
        population = d$B01003_001E
      )
    }, error = function(e) {
      message("State ", st, ": ", conditionMessage(e))
    })
  }
  tract_pop <- rbindlist(tract_pop_list)
  tract_pop <- tract_pop[!(is.na(population) | population < 0)]
  saveRDS(tract_pop, tract_pop_path)
}

# ==============================================================================
# 2. Read LYA tract files (FHFA Underserved Areas)
# ==============================================================================
# LYA files from FHFA Underserved Areas (https://www.fhfa.gov/data/underserved-areas-data).
# LYA=1 low-income, LYA=0 not, LYA=9 missing; we treat LYA=9 as 0 for weighting.
lmi_files <- list.files(path = lya_path, full.names = TRUE)
lmi_list <- list()

for (f in lmi_files) {
  temp <- fread(f, select = c("STATE", "CNTY", "TRACT", "LYA"))
  temp[, yr := as.numeric(str_extract(f, "\\d{4}"))]
  lmi_list[[f]] <- temp
}
lmi <- rbindlist(lmi_list)

# County FIPS (5-digit) and tract ID (11-digit GEOID) for joining to Census.
lmi[, county := paste0(str_pad(STATE, 2, "left", "0"), str_pad(CNTY, 3, "left", "0"))]
# LYA TRACT is 6-digit with 2 decimals implied; ensure 6-digit string to match GEOID.
tract_num <- as.numeric(lmi$TRACT)
mult <- if (any(tract_num != floor(tract_num), na.rm = TRUE)) 100 else 1
lmi[, tract_id := paste0(
  str_pad(STATE, 2, "left", "0"),
  str_pad(CNTY, 3, "left", "0"),
  str_pad(round(tract_num * mult), 6, "left", "0")
)]
lmi[, c("STATE", "CNTY", "TRACT") := NULL]
lmi[, LYA := fifelse(LYA == 9L, 0L, LYA)]

# ==============================================================================
# 3. Join LYA to tract population and aggregate to county-year
# ==============================================================================
# Full (county, yr) grid from LYA so we can assign NA where no population.
county_yr_grid <- unique(lmi[, .(county, yr)])

# Tracts with no match or zero/NA population excluded from numerator and
# denominator so they do not distort the ratio (effectively weight = 0).
lmi <- merge(lmi, tract_pop, by = "tract_id", all.x = TRUE)
lmi <- lmi[!(is.na(population) | population <= 0)]

# Population-weighted LMI: sum(LYA * pop) / sum(pop) by county-year.
# Counties with no tracts or zero total population get NA (restored via merge below).
lmi_agg <- lmi[, .(
  pop_w_lmi = sum(as.numeric(LYA) * population, na.rm = TRUE) / sum(population, na.rm = TRUE)
), by = .(county, yr)]
lmi_agg[is.nan(pop_w_lmi) | is.infinite(pop_w_lmi), pop_w_lmi := NA_real_]

lmi <- merge(county_yr_grid, lmi_agg, by = c("county", "yr"), all.x = TRUE)

# ==============================================================================
# 4. Backfill 2000-2012 from 2013 (same as equal-weight LMI pipeline)
# ==============================================================================
existing_yrs <- unique(lmi$yr)
missing_yrs <- setdiff(2000:2012, existing_yrs)
if (length(missing_yrs) > 0) {
  temp1 <- lmi[yr == 2013]
  for (y in missing_yrs) {
    temp <- copy(temp1)
    temp[, yr := y]
    lmi <- rbind(lmi, temp)
  }
}
setorder(lmi, county, yr)

# ==============================================================================
# 5. Save output (created by this script; for downstream use)
# ==============================================================================
lmi_out <- lmi[, .(county, yr, pop_w_lmi)]
saveRDS(lmi_out, file.path(data_path, "lmi_population_weighted.rds"))
