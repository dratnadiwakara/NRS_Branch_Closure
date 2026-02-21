---
layout: default
title: Descriptive statistics – closure sample — NRS Branch Closure
---
## [← Index](index.html) · [1. Editor and referee comments](response-plan.html)

# Descriptive Statistics - Branch Closure Sample

Summary statistics for the branch closure analysis sample, by bank size and rate cycle. Includes bank-level characteristics, deposit beta regressions, beta distributions and correlations, univariate closure rates by deposit beta decile, and branch-level descriptive statistics (Large Banks, Small Banks) for Mid Cycle (2019) and Early Cycle (2012).

*Source: `code/analysis/desc_stats_closure_sample_02202026.qmd`*

---

## Bank-Level Characteristics by Size and Cycle

Descriptive statistics for banks by size (large vs small, CPI-adjusted asset cutoff $100M) and rate cycle (Early 2004–2006, Mid 2016–2019, Late 2022–2024). Variables: Deposit beta, Age, College frac, Stock market frac, Family income, Sophisticated frac, HHI, Pop. density. Source: `code/analysis/desc_stats_closure_sample_02202026.qmd` (tbl-bank-stats).

```
### Cycle: cycle_0406 

Number of banks by size:

   0    1 
5662   27 

|Variable                                |Mean.x|SD.x |P10.x|P90.x|Mean.y|SD.y |P10.y|P90.y|
|----------------------------------------|------|-----|-----|-----|------|-----|-----|-----|
|Age                                     |37.27 | 2.52|34.19|38.72|39.90 | 4.35|34.71|45.33|
|College educated fraction               | 0.45 | 0.10| 0.34| 0.56| 0.27 | 0.13| 0.14| 0.45|
|Deposit-weighted Pop. density           | 0.46 | 0.14| 0.31| 0.60| 0.13 | 0.20| 0.01| 0.53|
|Deposit beta                            | 0.29 | 0.10| 0.14| 0.40| 0.23 | 0.11| 0.09| 0.38|
|Family income (000)                     |59.52 |14.01|44.80|78.40|50.34 |15.65|35.00|70.00|
|Frac. deposits in sophisticated zipcodes| 0.64 | 0.25| 0.35| 0.87| 0.44 | 0.42| 0.00| 1.00|
|HHI                                     | 0.25 | 0.17| 0.15| 0.36| 0.22 | 0.12| 0.10| 0.38|
|Stock market participation frac         | 0.25 | 0.07| 0.19| 0.33| 0.20 | 0.08| 0.10| 0.29|



### Cycle: cycle_1619 

Number of banks by size:

   0    1 
5008   34 

|Variable                                |Mean.x|SD.x |P10.x|P90.x |Mean.y|SD.y |P10.y|P90.y|
|----------------------------------------|------|-----|-----|------|------|-----|-----|-----|
|Age                                     |36.59 | 4.31|30.32| 41.36|40.75 | 4.38|35.52|45.80|
|College educated fraction               | 0.50 | 0.16| 0.33|  0.71| 0.30 | 0.15| 0.16| 0.51|
|Deposit-weighted Pop. density           | 0.51 | 0.16| 0.34|  0.68| 0.16 | 0.23| 0.01| 0.60|
|Deposit beta                            | 0.24 | 0.09| 0.15|  0.37| 0.18 | 0.12| 0.03| 0.35|
|Family income (000)                     |79.94 |30.36|57.80|112.40|59.07 |19.38|40.00|83.00|
|Frac. deposits in sophisticated zipcodes| 0.67 | 0.33| 0.00|  1.00| 0.46 | 0.41| 0.00| 1.00|
|HHI                                     | 0.25 | 0.15| 0.14|  0.35| 0.23 | 0.13| 0.11| 0.38|
|Stock market participation frac         | 0.27 | 0.14| 0.13|  0.43| 0.20 | 0.09| 0.10| 0.30|



### Cycle: cycle_2224 

Number of banks by size:

   0    1 
4499   31 

|Variable                                |Mean.x|SD.x |P10.x|P90.x |Mean.y|SD.y |P10.y|P90.y|
|----------------------------------------|------|-----|-----|------|------|-----|-----|-----|
|Age                                     |36.73 | 4.33|30.84| 41.68|40.74 | 4.37|35.49|45.77|
|College educated fraction               | 0.51 | 0.16| 0.36|  0.72| 0.30 | 0.15| 0.16| 0.50|
|Deposit-weighted Pop. density           | 0.52 | 0.16| 0.33|  0.69| 0.15 | 0.22| 0.01| 0.58|
|Deposit beta                            | 0.35 | 0.16| 0.19|  0.61| 0.19 | 0.13| 0.04| 0.37|
|Family income (000)                     |80.48 |31.57|56.00|113.00|58.51 |19.01|39.00|81.00|
|Frac. deposits in sophisticated zipcodes| 0.69 | 0.32| 0.00|  1.00| 0.46 | 0.41| 0.00| 1.00|
|HHI                                     | 0.25 | 0.16| 0.14|  0.36| 0.23 | 0.13| 0.11| 0.39|
|Stock market participation frac         | 0.28 | 0.14| 0.15|  0.45| 0.20 | 0.09| 0.10| 0.30|
```



---
## Distribution of Deposit Betas

- **Bank-level:** Density of deposit betas by bank size and cycle. Source: fig-beta-density-bank.

![Bank-level deposit beta distribution by size and cycle](NRS_Branch_Closure/figures/beta_density_bank.jpg)

- **Branch-level:** Density of deposit betas at branch level by size and cycle. Source: fig-beta-density-branch.

![Branch-level deposit beta distribution by size and cycle](NRS_Branch_Closure/figures/beta_density_branch.jpg)

---

## Beta Correlations Across Cycles

### Branch-level: Mid Cycle vs Late Cycle

![Branch-level deposit beta: Mid vs Late cycle](NRS_Branch_Closure/figures/df_scatter_branch_mid_late.jpg)

### Branch-level: Early Cycle vs Mid Cycle

![Branch-level deposit beta: Early vs Mid cycle](NRS_Branch_Closure/figures/df_scatter_branch_early_mid.jpg)

### Bank-level: Early Cycle vs Mid Cycle

![Bank-level deposit beta: Early vs Mid cycle](NRS_Branch_Closure/figures/df_scatter_bank_early_mid.jpg)

### Bank-level: Mid Cycle vs Late Cycle

![Bank-level deposit beta: Mid vs Late cycle](NRS_Branch_Closure/figures/df_scatter_bank_mid_late.jpg)

---

## Univariate: Closure Rates by Deposit Beta Decile

Branch closure rates by deposit beta decile across cycles. Source: `code/analysis/desc_stats_closure_sample_02202026.qmd` (fig-univariate-beta-closure).

![Branch closure rates by deposit beta decile across cycles](NRS_Branch_Closure/figures/univar_branch_closure.jpg)

---

## Descriptive Statistics - Large Banks (Panel A)

Descriptive statistics for large banks (CPI-adjusted assets ≥ $100M). Mid Cycle (2019) vs Early Cycle (2012). Variables: Closure, Deposit Beta, log(Zip Deposits), county-level growth/level controls. SD (within) for Deposit Beta and log(Zip Deposits). Source: tbl-desc-stats-large-banks.

```
|Variable                   |Mean.mid|SD.mid |SD (within).mid|P10.mid|P90.mid|Mean.early|SD.early|SD (within).early|P10.early|P90.early|
|---------------------------|--------|-------|---------------|-------|-------|----------|--------|-----------------|---------|---------|
|Closed                     |  0.04  |   0.19|        NA     | 0.00  |  0.00 |  0.02    |   0.15 |        NA       | 0.00    |  0.00   |
|Deposit Beta               |  0.24  |   0.04|0.02411757     | 0.19  |  0.29 |  0.33    |   0.04 |0.02056336       | 0.29    |  0.38   |
|log(Deposits)              | 11.22  |   1.04|0.91452132     |10.10  | 12.32 | 10.67    |   1.10 |0.99765970       | 9.46    | 11.82   |
|Acq. branch/presence       |  0.00  |   0.07|        NA     | 0.00  |  0.00 |  0.02    |   0.12 |        NA       | 0.00    |  0.00   |
|Branch owned 3plus years   |  0.98  |   0.15|        NA     | 1.00  |  1.00 |  0.82    |   0.39 |        NA       | 0.00    |  1.00   |
|Deposit 3yr growth         |  0.05  |   0.03|        NA     | 0.01  |  0.09 |  0.09    |   0.08 |        NA       | 0.00    |  0.20   |
|CRA 3yr growth             |  0.04  |   0.06|        NA     |-0.02  |  0.11 | -0.11    |   0.05 |        NA       |-0.16    | -0.06   |
|Establishments 3yr growth  |  0.01  |   0.01|        NA     | 0.00  |  0.03 | -0.01    |   0.01 |        NA       |-0.02    |  0.00   |
|Low to Moderate Income Area|  0.31  |   0.15|        NA     | 0.10  |  0.50 |  0.30    |   0.15 |        NA       | 0.10    |  0.48   |
|Mortgage 3yr growth        |  0.04  |   0.07|        NA     |-0.04  |  0.12 |  0.01    |   0.09 |        NA       |-0.09    |  0.15   |
|Payroll 3yr growth         |  0.04  |   0.02|        NA     | 0.02  |  0.07 |  0.00    |   0.02 |        NA       |-0.02    |  0.02   |
|Population density (1k km) |  0.41  |   0.28|        NA     | 0.04  |  0.75 |  0.37    |   0.26 |        NA       | 0.04    |  0.69   |
|Deposits (mn)              |209.76  |3270.37|        NA     |23.00  |216.00 |118.94    |1817.36 |        NA       |12.00    |134.00   |
```

---

## Descriptive Statistics - Small Banks (Panel B)

Descriptive statistics for small banks (CPI-adjusted assets < $100M). Same structure as Panel A. Source: tbl-desc-stats-small-banks.

```
|Variable                   |Mean.mid|SD.mid|SD (within).mid|P10.mid|P90.mid|Mean.early|SD.early|SD (within).early|P10.early|P90.early|
|---------------------------|--------|------|---------------|-------|-------|----------|--------|-----------------|---------|---------|
|Closed                     | 0.02   |  0.14|        NA     | 0.00  |  0.00 | 0.02     |  0.15  |        NA       | 0.00    |  0.00   |
|Deposit Beta               | 0.19   |  0.06|0.01699767     | 0.11  |  0.27 | 0.26     |  0.05  |0.01592801       | 0.20    |  0.32   |
|log(Deposits)              |10.54   |  1.25|0.95129472     | 9.15  | 11.86 |10.21     |  1.28  |0.96826362       | 8.81    | 11.56   |
|Acq. branch/presence       | 0.01   |  0.10|        NA     | 0.00  |  0.00 | 0.01     |  0.08  |        NA       | 0.00    |  0.00   |
|Branch owned 3plus years   | 0.91   |  0.29|        NA     | 1.00  |  1.00 | 0.90     |  0.30  |        NA       | 1.00    |  1.00   |
|Deposit 3yr growth         | 0.04   |  0.03|        NA     | 0.00  |  0.08 | 0.08     |  0.07  |        NA       | 0.00    |  0.18   |
|CRA 3yr growth             | 0.05   |  0.12|        NA     |-0.04  |  0.16 |-0.10     |  0.07  |        NA       |-0.17    | -0.03   |
|Establishments 3yr growth  | 0.01   |  0.01|        NA     |-0.01  |  0.03 |-0.01     |  0.01  |        NA       |-0.02    |  0.00   |
|Low to Moderate Income Area| 0.26   |  0.18|        NA     | 0.00  |  0.48 | 0.26     |  0.17  |        NA       | 0.00    |  0.47   |
|Mortgage 3yr growth        | 0.04   |  0.07|        NA     |-0.04  |  0.12 | 0.00     |  0.08  |        NA       |-0.09    |  0.10   |
|Payroll 3yr growth         | 0.04   |  0.03|        NA     | 0.00  |  0.07 | 0.00     |  0.03  |        NA       |-0.02    |  0.03   |
|Population density (1k km) | 0.22   |  0.26|        NA     | 0.01  |  0.75 | 0.22     |  0.25  |        NA       | 0.01    |  0.69   |
|Deposits (mn)              |84.09   |719.79|        NA     | 9.00  |136.00 |56.19     |341.95  |        NA       | 6.00    |102.40   |
```
