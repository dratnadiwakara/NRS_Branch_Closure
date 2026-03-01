---
layout: default
title: Impact of branch restructuring — NRS Branch Closure
---
## [← Index](index.html) · [1. Editor and referee comments](response-plan.html)

# Impact of Branch Restructuring on Local Deposit and Credit Markets

This document gathers results on the broader implications of branch restructuring, addressing **editor comment 3** and the referee’s requests on contribution and lending (e.g. **referee.1**, **referee.3**): why closures and openings matter—how they reallocate deposits across nearby branches, alter local market structure and competition, and whether they spill over into credit supply. The first section quantifies deposit reallocation in a ZIP–year panel; the second section reports the effect of closures and openings on local market concentration (ZIP-level deposit HHI); the third section reports evidence on mortgage and small-business (CRA) lending. 


## 1. Deposit Reallocation Around Branch Closures and Openings
*Source: `code/analysis/incumbent_chg_opening_closure_02182026_v2.qmd`*

We relate one-year deposit growth at *incumbent* banks (those with no openings or closures in the ZIP–year) to two branch-count treatments: the fraction of branches closed and the fraction of new branches in the ZIP, with the prior-year ZIP deposit base as the common scale so coefficients are pass-through elasticities. ZIP and CBSA–year fixed effects and pre-trend (`zip_growth_3yr`) are included; standard errors are clustered by ZIP. The table reports estimates by subperiod (2000–2007, 2008–2011, 2012–2019, 2020–2024). 

```
                               2000-7 (1) 2008-11 .. 2012-19 .. 2020-24 ..
Dependent Var.:                    gr_1yr     gr_1yr     gr_1yr     gr_1yr
                                                                          
fraction_of_branches_closed     0.0987***  0.0656***  0.0088    -0.0472***
                               (0.0157)   (0.0171)   (0.0097)   (0.0151)  
fraction_of_new_branches       -0.0301*** -0.0345*** -0.0406*** -0.0629***
                               (0.0077)   (0.0119)   (0.0110)   (0.0226)  
zip_growth_3yr              2e-5*          0.0001***  5.71e-6** -0.0003   
                               (1.17e-5)  (1.99e-5)  (2.84e-6)  (0.0007)  
log1p(branches_zip_lag1)       -0.0688*** -0.0290**  -0.0577*** -0.0529***
                               (0.0089)   (0.0123)   (0.0067)   (0.0127)  
log1p(n_incumbent_banks)        0.0573***  0.0272**   0.0643***  0.0356***
                               (0.0081)   (0.0114)   (0.0066)   (0.0125)  
Fixed-Effects:              ------------- ---------- ---------- ----------
ZIPBR                                 Yes        Yes        Yes        Yes
county_yr                             Yes        Yes        Yes        Yes
___________________________ _____________ __________ __________ __________
S.E.: Clustered                 by: ZIPBR  by: ZIPBR  by: ZIPBR  by: ZIPBR
Observations                       50,735     44,430     86,614     39,839
R2                                0.48056    0.43429    0.42217    0.54278
Within R2                         0.00502    0.00197    0.00425    0.00382
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```

## 2. Market Concentration (HHI) After Openings and Closures
*Source: `code/analysis/hhi_after_openings_closures_03012026.qmd` (branch-count treatments, `r_frac`)*

We regress the one-year change in ZIP-level deposit HHI (`delta_HHI_1yr` = HHI_{t+1} − HHI_t) on the fraction of branches closed and the fraction of new branches in the ZIP, with ZIP and county–year fixed effects and controls (past three-year deposit growth, log lagged branch count, log lagged incumbent bank count). Standard errors are clustered by ZIP. A positive coefficient on closures means concentration rises the year after more branches close; the coefficient on openings indicates whether entry raises or lowers concentration. Estimates are reported by subperiod.

```
                                2000-2007     2008-2011     2012-2019     2020-2024
Dependent Var.:             delta_HHI_1yr delta_HHI_1yr delta_HHI_1yr delta_HHI_1yr
                                                                                   
fraction_of_branches_closed     0.1264***    0.1615***      0.2232***     0.2557***
                               (0.0094)     (0.0104)       (0.0053)      (0.0076)  
fraction_of_new_branches       -0.0168***   -0.0107**      -0.0302***    -0.0189** 
                               (0.0031)     (0.0049)       (0.0047)      (0.0090)  
zip_growth_3yr                  8.18e-6     -2.33e-5***    -3.27e-9      -0.0001*  
                               (5.2e-6)     (6.76e-6)      (1.03e-6)     (7.35e-5) 
Fixed-Effects:              ------------- ------------- ------------- -------------
ZIPBR                                 Yes           Yes           Yes           Yes
county_yr                             Yes           Yes           Yes           Yes
___________________________ _____________ _____________ _____________ _____________
S.E.: Clustered                 by: ZIPBR     by: ZIPBR     by: ZIPBR     by: ZIPBR
Observations                       50,737        44,427        86,612        39,834
R2                                0.37722       0.38563       0.35134       0.41770
Within R2                         0.01634       0.02464       0.09457       0.11008
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```


<div style="border: 1px solid #ccc; padding: 1rem; margin: 1rem 0;">
<p><strong style="color: #b91c1c;">AI WRITTEN:</strong> <strong>Interpretation and reconciliation with deposit reallocation.</strong> The positive coefficient on closures is larger in later subperiods (2012–2019, 2020–2024), while the deposit reallocation results (Section 1) show that incumbent banks in the ZIP no longer gain—and may lose—deposits when branches close in those same periods. A possible explanation is that closing banks are increasingly able to <strong>retain deposits at their remaining branches</strong> after a closure, leveraging technology (e.g. digital and mobile banking), so that depositors do not switch to other banks in the same ZIP. In the data, only about X% of closures correspond to the bank fully exiting the ZIP; in the other Y% of cases the closing bank retains at least one branch in the ZIP. Even when the bank stays in the ZIP, it can hold a large share of the closed branch’s deposits at branches <em>outside</em> the ZIP or in non-branch channels. Then the closing bank’s <strong>in-ZIP</strong> deposit share falls (reflected in the ZIP-level HHI calculation), so local concentration rises, while local incumbents do not gain—and may even lose—because the freed deposits were retained by the closing bank rather than reallocated to them.</p>

> **Comment from Opus:** Why the current explanation works The key mechanism is about where the freed deposits go:
> Pre-2012: When Bank A closes a branch, its depositors switch to Banks B and C in the same ZIP. Total in-ZIP deposits stay roughly the same; they just redistribute. Incumbents gain (positive coefficient in Section 1). HHI rises modestly (0.13) because one player's share shrinks, but the effect is dampened because the deposits stay in the ZIP and get spread across remaining banks.
> Post-2012: When Bank A closes a branch, its depositors stay with Bank A — at branches in other ZIPs or via digital channels. Now the deposits leave the ZIP entirely (in SOD, deposits are booked at the branch). Incumbents don't gain (zero/negative coefficient in Section 1). But the HHI effect is larger (0.22–0.26) because removing deposits from the ZIP without redistributing them locally is more concentrating: the denominator (total ZIP deposits) shrinks while incumbents' absolute deposits are unchanged, so their shares mechanically rise.
> In short: deposits leaving the ZIP (post-2012, technology-enabled retention) concentrates the market more than deposits reshuffling within the ZIP (pre-2012). That's the core reconciliation.
> Even when the bank keeps a branch in the ZIP, many of the closed branch's depositors may end up booked at branches outside the ZIP (same bank, different location), so Bank A's in-ZIP share still falls substantially.
> One alternative (complementary) explanation worth considering: market thinning
> Over the 2000–2024 period, average branch density per ZIP has fallen. When a ZIP starts with 6 banks, losing one bank's presence is a smaller HHI shock than when it starts with 3 banks. So the growing HHI coefficient may partly reflect that later closures happen in thinner markets, where each closure is a proportionally bigger structural hit to competition. > This is consistent with the log1p(branches_zip_lag1) control in the HHI regression flipping from positive (pre-2012) to negative (post-2012) — ZIPs with more branches see less concentration change in the later period, reinforcing the thinning story.
This explanation is complementary rather than alternative: technology-enabled retention is why deposits leave the ZIP (demand side), and thinner markets are why each departure has a bigger structural impact (supply side). Together they explain why the HHI coefficient roughly doubles from 2000–2007 to 2020–2024.

> Bottom line
> The current explanation is correct — the reconciliation fundamentally comes down to deposits leaving the ZIP vs. staying in the ZIP. You might tighten it by (i) making that "deposits leave the denominator" point more explicit and (ii) adding the market-thinning point as a reinforcing structural factor. The two stories together — retention via technology + thinner starting markets — give a clean account of the divergence.
</div>
## 3. Impact on Mortgage and CRA Lending
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