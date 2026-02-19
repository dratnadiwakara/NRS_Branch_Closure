
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

**Design.** The unit of observation is **county–year**. We build a county–year panel from the branch-level sample (`branch_closure_analysis_sample_02172026.rds`): at each county–year we compute the fraction of branches closed and the fraction of new branches (same definitions as in the ZIP deposit reallocation analysis). County–year mortgage volume is the sum of bank–county HMDA originations; CRA volume is the sum of bank–county CRA small-business loan amounts. Outcomes are one-year growth rates in mortgage and CRA volume (`gr_mortgage_1yr`, `gr_cra_1yr`). Regressions include county and year fixed effects, three-year pre-trend in county deposits (`county_growth_3yr`), and log lagged branch count; standard errors are clustered by county. The script also produces baseline results by subperiod (2000–2007, 2008–2011, 2012–2019, 2020–2024) in separate tables.

**Heterogeneity by income and LMI (table below).** The table reports baseline specifications (no interaction) and specifications that interact both the closure share and the opening share with (i) low-income county (below median county income) and (ii) **population-weighted LMI** (`pop_w_lmi`): the share of county population in FHFA low-income tracts (above median = high-LMI county). The sample is county–years with year ≥ 2004, excluding 2008–2011 (GFC) and 2020 (pandemic) so that estimates reflect normal-cycle variation. Columns shown here are: mortgage baseline, mortgage × LMI (pop_w_lmi), CRA baseline, CRA × LMI (pop_w_lmi). This speaks directly to “who is hurt”: the interaction terms show whether effects of closures and openings on lending differ in lower-income or high-LMI counties. For example, in the mortgage × LMI column, the negative coefficient on *fraction_of_branches_closed × pop_w_lmi* indicates that the adverse association between closures and mortgage growth is stronger in high-LMI counties; the CRA × LMI column shows a positive interaction of *fraction_of_new_branches × pop_w_lmi* for CRA lending (new branches associated with higher CRA growth in high-LMI counties).


```
                                         Mtg (baseline)      Mtg × LMI CRA (bas.. CRA × LMI
Dependent Var.:                         gr_mortgage_1yr gr_mortgage_1yr gr_cra_1yr gr_cra_1yr
                                                                                             
fraction_of_branches_closed                  -0.0161          0.0425    -0.0093    -0.0518   
                                             (0.0229)        (0.0332)   (0.0523)   (0.0747)  
fraction_of_new_branches                      0.0857***       0.0996*** -0.0372    -0.1162** 
                                             (0.0205)        (0.0292)   (0.0420)   (0.0586)  
log1p(branches_county_lag1)                   0.0255***       0.0245*** -0.0367**  -0.0366** 
                                             (0.0073)        (0.0073)   (0.0144)   (0.0145)  
county_growth_3yr                            -0.0008         -0.0007    -0.0040*   -0.0040*  
                                             (0.0009)        (0.0009)   (0.0022)   (0.0023)  
log1p(total_deps_county_lag1)                -0.0434***      -0.0421*** -0.0465*** -0.0466***
                                             (0.0051)        (0.0051)   (0.0096)   (0.0095)  
pop_w_lmi                                                     0.0059               -0.0341*  
                                                             (0.0084)              (0.0185)  
fraction_of_branches_closed x pop_w_lmi                      -0.2689**              0.1771   
                                                             (0.1294)              (0.2411)  
fraction_of_new_branches x pop_w_lmi                         -0.0763                0.4100*  
                                                             (0.0949)              (0.2133)  
Fixed-Effects:                          --------------- --------------- ---------- ----------
county_code                                         Yes             Yes        Yes        Yes
year                                                Yes             Yes        Yes        Yes
_______________________________________ _______________ _______________ __________ __________
S.E.: Clustered                         by: county_code by: county_code by: coun.. by: coun..
Observations                                     41,726          41,617     41,726     41,617
R2                                              0.53042         0.53113    0.10852    0.10864
Within R2                                       0.00253         0.00267    0.00122    0.00146
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```