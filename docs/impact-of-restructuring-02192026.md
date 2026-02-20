---
layout: default
title: Impact of branch restructuring — NRS Branch Closure
---
## [← Index](index.html) · [1. Editor and referee comments](response-plan.html)

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

**Design.** The unit of observation is **county–year**. We build a county–year panel from the branch-level sample (`branch_closure_analysis_sample_02172026.rds`): at each county–year we compute the fraction of branches closed and the fraction of new branches (same definitions as in the ZIP deposit reallocation analysis). County–year mortgage volume is the sum of bank–county HMDA originations; CRA volume is the sum of bank–county CRA small-business loan amounts. Outcomes are forward-looking growth rates: one-year and three-year growth from current volume to future volume (`gr_mortgage_1yr`, `gr_mortgage_3yr`, `gr_cra_1yr`, `gr_cra_3yr`). Regressions include county and year fixed effects, three-year pre-trend in county deposits (`county_growth_3yr`), log lagged branch count, log lagged deposit volume, and log lagged bank count; standard errors are clustered by county.

**Sample restrictions.** The sample uses county–years with year ≥ 2004 (cra data absent pre 2004) and at least 3 banks. Treatment variables are Winsorized at the 99th percentile; outcome growth rates are Winsorized at the 1st and 99th percentiles.

**Heterogeneity by LMI (table below).** The table reports baseline specifications (no interaction) and specifications that interact both the closure share and the opening share with **population-weighted LMI** (`pop_w_lmi`): the share of county population in FHFA low-income tracts (above median = high-LMI county). Columns shown: mortgage 1yr baseline, mortgage 1yr × LMI, mortgage 3yr baseline, mortgage 3yr × LMI, CRA 1yr baseline, CRA × LMI, CRA 3yr baseline, CRA 3yr × LMI. The interaction terms show whether effects of closures and openings on lending differ in high-LMI counties. 


```
                                         Mtg (baseline)      Mtg × LMI Mtg 3yr (base..  Mtg 3yr × LMI CRA (bas.. CRA × LMI CRA 3yr .. CRA 3yr ...1
Dependent Var.:                         gr_mortgage_1yr gr_mortgage_1yr gr_mortgage_3yr gr_mortgage_3yr gr_cra_1yr gr_cra_1yr gr_cra_3yr   gr_cra_3yr
                                                                                                                                                     
fraction_of_branches_closed                  -0.0204         -0.0663**        0.0346         -0.0275    -0.0487    -0.0310    -0.1585**    -0.1526   
                                             (0.0205)        (0.0288)        (0.0319)        (0.0453)   (0.0445)   (0.0658)   (0.0634)     (0.0953)  
fraction_of_new_branches                     -0.0941***      -0.0847***      -0.1611***      -0.1530*** -0.0017     0.0169    -0.0592      -0.0272   
                                             (0.0189)        (0.0265)        (0.0293)        (0.0429)   (0.0356)   (0.0555)   (0.0526)     (0.0800)  
log1p(branches_county_lag1)                   0.0152*         0.0150*         0.0549**        0.0550**   0.0003     0.0009     0.0315       0.0318   
                                             (0.0083)        (0.0083)        (0.0232)        (0.0232)   (0.0143)   (0.0143)   (0.0350)     (0.0350)  
county_growth_3yr                             0.0023***       0.0023***       0.0096***       0.0096*** -0.0006    -0.0006     0.0165*      0.0165*  
                                             (0.0008)        (0.0008)        (0.0028)        (0.0028)   (0.0015)   (0.0015)   (0.0086)     (0.0086)  
log1p(total_deps_county_lag1)                -0.0620***      -0.0617***      -0.1598***      -0.1598*** -0.0200*** -0.0207*** -0.0616***   -0.0621***
                                             (0.0055)        (0.0055)        (0.0166)        (0.0166)   (0.0074)   (0.0074)   (0.0190)     (0.0190)  
log1p(banks_county_lag1)                      0.0131*         0.0133*         0.0876***       0.0877*** -0.0235*   -0.0240*   -0.0430      -0.0431   
                                             (0.0075)        (0.0075)        (0.0218)        (0.0218)   (0.0133)   (0.0133)   (0.0339)     (0.0339)  
pop_w_lmi                                                    -0.0046                         -0.0076               -0.0131                  0.0026   
                                                             (0.0081)                        (0.0211)              (0.0179)                (0.0392)  
fraction_of_branches_closed x pop_w_lmi                       0.2307**                        0.3102**             -0.0809                 -0.0318   
                                                             (0.1112)                        (0.1541)              (0.2230)                (0.3152)  
fraction_of_new_branches x pop_w_lmi                         -0.0471                         -0.0389               -0.0975                 -0.1736   
                                                             (0.0956)                        (0.1817)              (0.1860)                (0.3029)  
Fixed-Effects:                          --------------- --------------- --------------- --------------- ---------- ---------- ----------   ----------
county_code                                         Yes             Yes             Yes             Yes        Yes        Yes        Yes          Yes
year                                                Yes             Yes             Yes             Yes        Yes        Yes        Yes          Yes
_______________________________________ _______________ _______________ _______________ _______________ __________ __________ __________   __________
S.E.: Clustered                         by: county_code by: county_code by: county_code by: county_code by: coun.. by: coun.. by: coun..   by: coun..
Observations                                     50,434          50,392          45,179          45,171     50,434     50,392     45,179       45,171
R2                                              0.62803         0.62828         0.72954         0.72956    0.24105    0.24111    0.32755      0.32762
Within R2                                       0.00387         0.00399         0.00995         0.01005    0.00025    0.00028    0.00093      0.00094
```