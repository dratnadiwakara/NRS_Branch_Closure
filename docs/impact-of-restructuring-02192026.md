
# Impact of Branch Restructuring on Local Deposit and Credit Markets

This document gathers results on the broader implications of branch restructuring, addressing **editor comment 3** and the referee’s requests on contribution and lending (e.g. **referee.1**, **referee.3**): why closures and openings matter—how they reallocate deposits across nearby branches, alter local market structure and competition, and whether they spill over into credit supply. The first section quantifies deposit reallocation in a ZIP–year panel; the second section reports evidence on mortgage and small-business (CRA) lending. 


## 1. Deposit Reallocation Around Branch Closures and Openings
*Source: `code/analysis/incumbent_chg_opening_closure_02182026_v2.qmd`*

We relate one-year deposit growth at *incumbent* banks (those with no openings or closures in the ZIP–year) to two branch-count treatments: the fraction of branches closed and the fraction of new branches in the ZIP, with the prior-year ZIP deposit base as the common scale so coefficients are pass-through elasticities. ZIP and CBSA–year fixed effects and pre-trend (`zip_growth_3yr`) are included; standard errors are clustered by ZIP. The table reports estimates by subperiod (2000–2007, 2008–2011, 2012–2019, 2020–2024). 

```
                            2000-7 (1) 2000-7 (2) 2008-11 .. 2008-11 ...1 2012-19 .. 2012-19 ...1 2020-24 .. 2020-24 ...1
Dependent Var.:                 gr_1yr     gr_1yr     gr_1yr       gr_1yr     gr_1yr       gr_1yr     gr_1yr       gr_1yr
                                                                                                                         
fraction_of_branches_closed  0.0574***             0.0490***              -0.0238***              -0.0438***             
                            (0.0123)              (0.0125)                (0.0068)                (0.0107)               
fraction_of_new_branches    -0.0493***            -0.0438***              -0.0607***              -0.0691***             
                            (0.0064)              (0.0097)                (0.0095)                (0.0192)               
share_deps_closed                       0.1096***               0.1353***              -0.0141                 -0.0482***
                                       (0.0224)                (0.0205)                (0.0100)                (0.0147)  
zip_growth_3yr               1.27e-5    1.29e-5    0.0001***    0.0001***  4.96e-6*     5.21e-6*  -0.0002      -0.0002   
                            (1.31e-5)  (1.33e-5)  (1.97e-5)    (1.97e-5)  (2.6e-6)     (2.72e-6)  (0.0007)     (0.0007)  
log1p(branches_zip_lag1)    -0.0479*** -0.0230*** -0.0155       0.0024    -0.0262***   -0.0203*** -0.0382***   -0.0276** 
                            (0.0074)   (0.0066)   (0.0104)     (0.0093)   (0.0054)     (0.0053)   (0.0112)     (0.0114)  
Fixed-Effects:              ---------- ---------- ----------   ---------- ----------   ---------- ----------   ----------
ZIPBR                              Yes        Yes        Yes          Yes        Yes          Yes        Yes          Yes
cbsa_yr                            Yes        Yes        Yes          Yes        Yes          Yes        Yes          Yes
___________________________ __________ __________ __________   __________ __________   __________ __________   __________
S.E.: Clustered              by: ZIPBR  by: ZIPBR  by: ZIPBR    by: ZIPBR  by: ZIPBR    by: ZIPBR  by: ZIPBR    by: ZIPBR
Observations                    55,198     55,198     48,193       48,193     94,257       94,257     43,786       43,786
R2                             0.41799    0.41683    0.38280      0.38297    0.36369      0.36302    0.49178      0.49124
Within R2                      0.00333    0.00135    0.00171      0.00198    0.00144      0.00039    0.00186      0.00082
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```


## 2. Impact on Mortgage and CRA Lending
*Source: `code/analysis/closure_credit_impacts_02192026.qmd`*

We test whether areas that experience branch closures or net branch reductions see declines in mortgage origination (HMDA) or small-business lending (CRA), particularly for lower-income or underserved borrowers—addressing **editor comment 3**, **referee comment 1** (broader implications, downstream credit outcomes), and **referee comment 3** (who is hurt or helped by restructuring).

**Design.** The unit of observation is **county–year**. We build a county–year panel from the branch-level sample (`branch_closure_analysis_sample_02172026.rds`): at each county–year we compute the fraction of branches closed and the fraction of new branches (same definitions as in the ZIP deposit reallocation analysis). County–year mortgage volume is the sum of bank–county HMDA originations; CRA volume is the sum of bank–county CRA small-business loan amounts. Outcomes are one-year growth rates in mortgage and CRA volume (`gr_mortgage_1yr`, `gr_cra_1yr`). Regressions include county and year fixed effects, three-year pre-trend in county deposits (`county_growth_3yr`), and log lagged branch count; standard errors are clustered by county. Subperiods (2000–2007, 2008–2011, 2012–2019, 2020–2024) mirror the deposit reallocation table for comparability.

**Baseline results (Tables A and B).** Run `code/analysis/closure_credit_impacts_02192026.qmd` to produce the tables; they are also written to `tables/closure_credit_mortgage_02192026.txt` and `tables/closure_credit_cra_02192026.txt`. The coefficients on `fraction_of_branches_closed` and `fraction_of_new_branches` show whether county-level mortgage and CRA lending growth respond to branch restructuring. Negative coefficients on closures would indicate that areas losing branches see slower credit growth; positive coefficients on openings would indicate that new branches are associated with faster local credit growth (or vice versa depending on specification). Even null or small effects are informative, as they clarify which margins branch closures do and do not operate through (editor/referee).

**Heterogeneity by income and LMI (Table C).** The same script estimates interactions of the closure share with (i) low-income county indicator (below median county income) and (ii) high LMI share where available. This speaks directly to “who is hurt”: if closure effects on lending are larger in lower-income or high-LMI counties, restructuring disproportionately affects underserved borrowers. Heterogeneity tables are written to `tables/closure_credit_mortgage_heterogeneity_02192026.txt` and `tables/closure_credit_cra_heterogeneity_02192026.txt`.

**Link to comments.**  
- **Editor 3 / Referee 1:** The county–year credit regressions quantify whether branch closures translate into reduced local mortgage and small-business lending, complementing the deposit reallocation evidence in Section 1.  
- **Referee 3:** Heterogeneity by income and LMI addresses who is hurt or helped and allows discussion of whether credit-side impacts are driven by income/wealth versus other demographic factors.