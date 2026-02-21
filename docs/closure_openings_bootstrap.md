---
layout: default
title: Closure and openings bootstrap — NRS Branch Closure
---
## [← Index](index.html) · [3. Key closure results](key-closure-results.html)

# Two-Stage Bootstrap Standard Errors for Branch Closure Regressions

This document collects results from the two-stage bootstrap that accounts for **generated regressor uncertainty** in the branch closure regressions. The first stage re-estimates bank-level deposit beta regressions; the second stage re-estimates branch-level closure regressions. Standard errors from clustered OLS underestimate uncertainty because deposit beta is predicted from the first stage. The bootstrap provides corrected inference.

*Source: `code/analysis/closure_se_bootstrap_02172026.R`*

---

## Methodology

1. **Stage 1 (bootstrap):** Resample banks with replacement; re-estimate bank-level deposit expense sensitivity regressions for each rate cycle (2004–2006, 2016–2019, 2022–2024).
2. **Stage 2 (bootstrap):** Resample banks with replacement; predict branch-level deposit betas from Stage 1; run closure regression with controls and fixed effects.
3. **Repeat** 500 times; compute bootstrap SE and 95% CI from the distribution of deposit beta coefficients.

---

## Results

### Large Banks

| Statistic | Value |
|-----------|-------|
| Original coefficient | *(paste from script output)* |
| Original SE (clustered) | *(paste)* |
| Bootstrap SE (two-stage) | *(paste)* |
| Bootstrap 95% CI | *(paste)* |
| SE inflation factor | *(paste)* |
| T-stat (original) | *(paste)* |
| T-stat (bootstrap) | *(paste)* |

### Small Banks

| Statistic | Value |
|-----------|-------|
| Original coefficient | *(paste from script output)* |
| Original SE (clustered) | *(paste)* |
| Bootstrap SE (two-stage) | *(paste)* |
| Bootstrap 95% CI | *(paste)* |
| SE inflation factor | *(paste)* |
| T-stat (original) | *(paste)* |
| T-stat (bootstrap) | *(paste)* |

### Comparison Table

```
Bank_Size  Coefficient  SE_Clustered  SE_Bootstrap  CI_Lower  CI_Upper  N_Bootstrap  SE_Inflation  T_Stat_Original  T_Stat_Bootstrap
 Large      ...          ...           ...           ...       ...       ...          ...           ...               ...
 Small      ...          ...           ...           ...       ...       ...          ...           ...               ...
```

*Run `code/analysis/closure_se_bootstrap_02172026.R` and paste results above.*

---

## Bootstrap Distribution

![Bootstrap distribution of deposit beta coefficients by bank size](../figures/bootstrap_distribution.png)

Bootstrap distributions of the deposit beta coefficient for large and small banks. Red dashed line: original point estimate. Histograms show the distribution across 500 two-stage bootstrap replications.

---

## Opening Bootstrap (placeholder)

Same two-stage bootstrap procedure applied to **branch opening** regressions. Placeholder for results.

*Source: `code/analysis/opening_se_bootstrap_XXXXXX.R` (to be created)*

### Large Banks

| Statistic | Value |
|-----------|-------|
| Original coefficient | *(paste from script output)* |
| Original SE (clustered) | *(paste)* |
| Bootstrap SE (two-stage) | *(paste)* |
| Bootstrap 95% CI | *(paste)* |
| SE inflation factor | *(paste)* |
| T-stat (original) | *(paste)* |
| T-stat (bootstrap) | *(paste)* |

### Small Banks

| Statistic | Value |
|-----------|-------|
| Original coefficient | *(paste from script output)* |
| Original SE (clustered) | *(paste)* |
| Bootstrap SE (two-stage) | *(paste)* |
| Bootstrap 95% CI | *(paste)* |
| SE inflation factor | *(paste)* |
| T-stat (original) | *(paste)* |
| T-stat (bootstrap) | *(paste)* |

### Comparison Table

```
Bank_Size  Coefficient  SE_Clustered  SE_Bootstrap  CI_Lower  CI_Upper  N_Bootstrap  SE_Inflation  T_Stat_Original  T_Stat_Bootstrap
 Large      ...          ...           ...           ...       ...       ...          ...           ...               ...
 Small      ...          ...           ...           ...       ...       ...          ...           ...               ...
```

### Bootstrap Distribution

*(Add figure when available: `figures/bootstrap_distribution_opening.png`)*
