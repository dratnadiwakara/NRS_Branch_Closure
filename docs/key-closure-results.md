---
layout: default
title: Key closure results — NRS Branch Closure
---
## [← Index](index.html) · [1. Editor and referee comments](response-plan.html)

# Key Branch Closure Results

Collected key regression results from branch closure and opening analysis. No descriptive statistics.

*Source: `code/analysis/key_closure_results_02172026.qmd`*

---

## 1. Deposit Beta Regression

Bank-level deposit beta (interest expense sensitivity to rate cycles) regressed on depositor and bank characteristics across three rate cycles: early (2004–2006), mid (2016–2019), late (2022–2024). Columns 1–3 use college frac and stock market frac as separate sophistication proxies; columns 4–6 replace them with a single sophisticated frac (education + stock market participation). Covariates include age bins, log income, bank HHI, log assets, population density, trans accounts, uninsured deposits, and time-deposit share. Source: `code/analysis/key_closure_results_02172026.qmd` (tbl-deposit-beta-regs).

```
                      beta_cyc.. beta_cyc...1 beta_cyc...2 beta_cyc...3 beta_cyc...4 beta_cyc...5
                     Early Cycle    Mid Cycle   Late Cycle  Early Cycle    Mid Cycle   Late Cycle
                                                                                                 
Constant               0.8858***   -0.4100*     -1.049**      0.2527      -1.177***    -2.063*** 
                      (0.3058)     (0.2234)     (0.4112)     (0.2723)     (0.1944)     (0.3580)  
Age bin 2             -0.0216      -0.0104      -0.0221      -0.0346**    -0.0084      -0.0208   
                      (0.0138)     (0.0094)     (0.0175)     (0.0135)     (0.0093)     (0.0172)  
Age bin 3             -0.0580***   -0.0182*     -0.0240      -0.0738***   -0.0109      -0.0162   
                      (0.0159)     (0.0109)     (0.0204)     (0.0149)     (0.0104)     (0.0194)  
Age bin 4             -0.0196      -0.0456***   -0.0609**    -0.0362**    -0.0288**    -0.0414   
                      (0.0197)     (0.0152)     (0.0285)     (0.0184)     (0.0144)     (0.0271)  
Stock market frac     -0.0648       0.3101***    0.3651***                                       
                      (0.1044)     (0.0718)     (0.1389)                                         
College frac           0.6922***    0.2460***    0.3640***                                       
                      (0.0759)     (0.0528)     (0.1002)                                         
Log(Income)           -0.1064***   -0.0183      -0.0195      -0.0440*      0.0566***    0.0800** 
                      (0.0283)     (0.0206)     (0.0381)     (0.0246)     (0.0176)     (0.0324)  
Bank HHI              -0.1479***   -0.1181***   -0.2123***   -0.1439***   -0.1125***   -0.2074***
                      (0.0431)     (0.0302)     (0.0554)     (0.0433)     (0.0304)     (0.0556)  
Log(Assets)            0.0474***    0.0418***    0.0929***    0.0517***    0.0437***    0.0952***
                      (0.0047)     (0.0029)     (0.0053)     (0.0047)     (0.0029)     (0.0053)  
Pop. density           0.0951***   -0.0399*      0.1299***    0.2470***    0.0173       0.2162***
                      (0.0356)     (0.0232)     (0.0436)     (0.0316)     (0.0207)     (0.0387)  
Trans. accounts       -0.0101      -0.0399       0.1324*     -0.0213      -0.0426       0.1272   
                      (0.0693)     (0.0431)     (0.0796)     (0.0696)     (0.0433)     (0.0798)  
Uninsured deposits     0.4129***    0.3006***    0.7926***    0.4733***    0.3304***    0.8366***
                      (0.0461)     (0.0280)     (0.0513)     (0.0459)     (0.0278)     (0.0509)  
time_deposits_assets   0.8089***    1.320***     1.673***     0.8304***    1.330***     1.685*** 
                      (0.0481)     (0.0309)     (0.0576)     (0.0483)     (0.0309)     (0.0575)  
Sophisticated frac                                            0.1081***    0.0683***    0.0888***
                                                             (0.0148)     (0.0109)     (0.0202)  
____________________  __________   __________   __________   __________   __________   __________
S.E. type                    IID          IID          IID          IID          IID          IID
Observations               5,689        5,042        4,530        5,689        5,042        4,530
R2                       0.16166      0.35648      0.32137      0.15405      0.35042      0.31751
Adj. R2                  0.15989      0.35494      0.31956      0.15241      0.34900      0.31585
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```

---

## 2. Baseline Closure Model

Branch-level closure indicator (`closed`) regressed on predicted deposit beta and controls. Odd columns: state–year and bank–year fixed effects; even columns: county–year and bank–year fixed effects. Columns 1–2: all banks; 3–4: large banks (CPI-adjusted assets ≥ $100M); 5–6: small banks. Controls include log lagged branch deposits, same-ZIP prior 3-year branches, legacy branch, county deposit growth, HMDA mortgage and CRA lending growth, establishment and payroll growth, population-weighted LMI, log bank–county mortgage/CRA volume, and log(1 + family income). Standard errors clustered by bank (RSSDID). Source: `code/analysis/key_closure_results_02172026.qmd` (tbl-baseline-closure).

```
                                        model 1    model 2     model 3     model 4     model 5     model 6
                                      All Banks  All Banks Large Banks Large Banks Small Banks Small Banks
                                                                                                          
Deposit beta                          0.1001***  0.1114***   0.1333***   0.1678***   0.0804***   0.0701***
                                     (0.0107)   (0.0127)    (0.0199)    (0.0222)    (0.0095)    (0.0108)  
log(lag_branch_deposit_amount)       -0.0160*** -0.0158***  -0.0189***  -0.0184***  -0.0143***  -0.0141***
                                     (0.0005)   (0.0005)    (0.0011)    (0.0011)    (0.0005)    (0.0005)  
same_zip_prior_3yr_branches           0.0483***  0.0461***   0.0457***   0.0405***   0.0494***   0.0472***
                                     (0.0062)   (0.0062)    (0.0103)    (0.0108)    (0.0071)    (0.0069)  
legacy_branch                        -0.0071*** -0.0068***  -0.0063***  -0.0072***  -0.0082***  -0.0082***
                                     (0.0012)   (0.0013)    (0.0021)    (0.0024)    (0.0012)    (0.0013)  
lag_county_deposit_gr                 0.0006                 0.0018                  0.0002               
                                     (0.0006)               (0.0014)                (0.0006)              
lag_hmda_mtg_amt_gr                  -0.0076***             -0.0061                 -0.0072***            
                                     (0.0025)               (0.0051)                (0.0022)              
lag_cra_loan_amount_amt_lt_1m_gr     -0.0005                -0.0007                 -0.0002               
                                     (0.0006)               (0.0020)                (0.0005)              
lag_establishment_gr                 -0.1289***             -0.2508***              -0.0453**             
                                     (0.0241)               (0.0469)                (0.0180)              
lag_payroll_gr                       -0.0026                -0.0138                  0.0054               
                                     (0.0053)               (0.0102)                (0.0058)              
pop_w_lmi                            -0.0046***             -0.0116***               0.0006               
                                     (0.0015)               (0.0028)                (0.0011)              
log(lag_bank_county_mortgage_volume) -0.0003    -0.0006**   -0.0010      0.0003     -0.0002     -0.0007***
                                     (0.0003)   (0.0003)    (0.0007)    (0.0011)    (0.0002)    (0.0002)  
log(lag_bank_county_cra_volume)      -0.0004    -0.0007**    0.0005      0.0011     -0.0004     -0.0008***
                                     (0.0003)   (0.0004)    (0.0006)    (0.0008)    (0.0003)    (0.0003)  
log1p(family_income)                 -0.0017*** -0.0023***  -0.0026***  -0.0027***  -0.0011**   -0.0023***
                                     (0.0004)   (0.0004)    (0.0006)    (0.0008)    (0.0004)    (0.0005)  
Fixed-Effects:                       ---------- ----------  ----------  ----------  ----------  ----------
state_yr                                    Yes         No         Yes          No         Yes          No
bank_yr                                     Yes        Yes         Yes         Yes         Yes         Yes
county_yr                                    No        Yes          No         Yes          No         Yes
____________________________________ __________ __________  __________  __________  __________  __________
S.E.: Clustered                      by: RSSDID by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID
Observations                          1,735,826  1,802,203     682,236     698,499   1,053,588   1,090,424
R2                                      0.09460    0.12532     0.04876     0.09692     0.14328     0.19442
Within R2                               0.01396    0.01338     0.01397     0.01271     0.01450     0.01408
```

---

## 3. Closure by Time Period

Branch closure regressions by subperiod. Same specification as baseline (closed on deposit beta and controls; odd columns: state–year + bank–year FE; even columns: county–year + bank–year FE). Four periods: 2001–2007 (pre-crisis), 2008–2011 (GFC), 2012–2019 (post-crisis recovery), 2020–2024 (pandemic). The qmd produces separate tables for large and small banks; this table shows large banks. Standard errors clustered by bank. Source: `code/analysis/key_closure_results_02172026.qmd` (tbl-closure-by-regime).

Panel A: Large Banks
```
                                        model 1    model 2    model 3    model 4    model 5    model 6    model 7    model 8
                                        2001-07    2001-07    2008-11    2008-11    2012-19    2012-19    2020-23    2020-23
                                                                                                                            
Deposit beta                          0.0870***  0.1050***  0.0916***  0.0928***  0.1555***  0.1894***  0.2798***  0.3952***
                                     (0.0147)   (0.0235)   (0.0200)   (0.0231)   (0.0323)   (0.0375)   (0.0453)   (0.0503)  
log(lag_branch_deposit_amount)       -0.0155*** -0.0154*** -0.0137*** -0.0134*** -0.0205*** -0.0202*** -0.0267*** -0.0244***
                                     (0.0021)   (0.0022)   (0.0025)   (0.0026)   (0.0017)   (0.0018)   (0.0047)   (0.0042)  
Fixed-Effects:                       ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
state_yr                                    Yes         No        Yes         No        Yes         No        Yes         No
bank_yr                                     Yes        Yes        Yes        Yes        Yes        Yes        Yes        Yes
county_yr                                    No        Yes         No        Yes         No        Yes         No        Yes
____________________________________ __________ __________ __________ __________ __________ __________ __________ __________
S.E.: Clustered                      by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                            133,715    130,668    132,618    130,627    292,994    288,790    122,909    148,414
R2                                      0.05774    0.12125    0.03349    0.07891    0.04046    0.09137    0.05092    0.09345
Within R2                               0.01682    0.01620    0.01426    0.01325    0.01569    0.01376    0.01514    0.01314
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```

Panel B: Small Banks
```
                                        model 1    model 2    model 3    model 4    model 5    model 6    model 7    model 8
                                        2001-07    2001-07    2008-11    2008-11    2012-19    2012-19    2020-24    2020-24
                                                                                                                            
Deposit beta                          0.0657***  0.0833***  0.1239***  0.0917***  0.0659***  0.0813***  0.1398***  0.1010***
                                     (0.0128)   (0.0173)   (0.0205)   (0.0249)   (0.0186)   (0.0212)   (0.0254)   (0.0293)  
log(lag_branch_deposit_amount)       -0.0109*** -0.0108*** -0.0149*** -0.0149*** -0.0164*** -0.0163*** -0.0172*** -0.0162***
                                     (0.0011)   (0.0011)   (0.0007)   (0.0007)   (0.0007)   (0.0006)   (0.0009)   (0.0008)  
Fixed-Effects:                       ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
state_yr                                    Yes         No        Yes         No        Yes         No        Yes         No
bank_yr                                     Yes        Yes        Yes        Yes        Yes        Yes        Yes        Yes
county_yr                                    No        Yes         No        Yes         No        Yes         No        Yes
____________________________________ __________ __________ __________ __________ __________ __________ __________ __________
S.E.: Clustered                      by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                            332,500    330,645    180,904    179,892    369,028    367,196    171,156    212,691
R2                                      0.13281    0.18457    0.16671    0.21117    0.14607    0.19744    0.12709    0.18470
Within R2                               0.01426    0.01395    0.01669    0.01620    0.01508    0.01471    0.01468    0.01385
```

---
## 4. Closures and Branch Usage (Pandemic Era)

Branch closure regressions for 2020–2023 (pandemic era), adding branch-usage variables from SafeGraph/advan: drop in visits (change from 2019 to 2021) and log median distance from home. Odd columns: state–year + bank–year FE; even columns: county–year + bank–year FE. Panel A: full sample; Panel B: by bank size (large vs small). Columns 1–2: baseline (deposit beta + controls); columns 3–4: add usage variables. Standard errors clustered by bank. Source: `code/analysis/key_closure_results_02172026.qmd` (tbl-closure-usage).

Panel A: Full Sample
```
                                        model 1    model 2    model 3    model 4
                                       Baseline   Baseline With Usage With Usage
                                                                                
Deposit beta                          0.2445***  0.2696***  0.2093***  0.2167***
                                     (0.0247)   (0.0288)   (0.0222)   (0.0257)  
log(lag_branch_deposit_amount)       -0.0201*** -0.0187*** -0.0203*** -0.0189***
                                     (0.0019)   (0.0018)   (0.0020)   (0.0018)  
Drop in visits                                              0.0032**   0.0037** 
                                                           (0.0016)   (0.0018)  
Log(Distance)                                               0.0048***  0.0070***
                                                           (0.0013)   (0.0012)  
Fixed-Effects:                       ---------- ---------- ---------- ----------
state_yr                                    Yes         No        Yes         No
bank_yr                                     Yes        Yes        Yes        Yes
county_yr                                    No        Yes         No        Yes
____________________________________ __________ __________ __________ __________
S.E.: Clustered                      by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                            275,813    341,533    275,351    340,987
R2                                      0.07946    0.10945    0.07955    0.10970
Within R2                               0.01363    0.01233    0.01379    0.01256
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```

Panel B: By Size
```
                                         model 1     model 2     model 3     model 4     model 5     model 6     model 7     model 8
                                     Large Banks Large Banks Large Banks Large Banks Small Banks Small Banks Small Banks Small Banks
                                                                                                                                    
Deposit beta                           0.3052***   0.4049***   0.2336***   0.3099***   0.1835***   0.1372***   0.1616***   0.1079***
                                      (0.0484)    (0.0518)    (0.0436)    (0.0470)    (0.0259)    (0.0302)    (0.0248)    (0.0297)  
log(lag_branch_deposit_amount)        -0.0254***  -0.0233***  -0.0259***  -0.0239***  -0.0166***  -0.0157***  -0.0166***  -0.0158***
                                      (0.0045)    (0.0040)    (0.0046)    (0.0041)    (0.0009)    (0.0008)    (0.0009)    (0.0008)  
Drop in visits                                                -8.68e-5     0.0053                              0.0048***   0.0043***
                                                              (0.0042)    (0.0051)                            (0.0014)    (0.0014)  
Log(Distance)                                                  0.0120***   0.0119***                          -0.0004      0.0033***
                                                              (0.0015)    (0.0021)                            (0.0011)    (0.0012)  
Fixed-Effects:                        ----------  ----------  ----------  ----------  ----------  ----------  ----------  ----------
state_yr                                     Yes          No         Yes          No         Yes          No         Yes          No
bank_yr                                      Yes         Yes         Yes         Yes         Yes         Yes         Yes         Yes
county_yr                                     No         Yes          No         Yes          No         Yes          No         Yes
____________________________________  __________  __________  __________  __________  __________  __________  __________  __________
S.E.: Clustered                       by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID
Observations                             121,413     146,769     121,358     146,706     154,400     191,707     153,993     191,234
R2                                       0.04934     0.08953     0.04982     0.09001     0.12273     0.17823     0.12279     0.17847
Within R2                                0.01462     0.01271     0.01512     0.01318     0.01459     0.01359     0.01469     0.01372
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```

---

## 5. Reduced Form: Demographics and Closures

Branch closure regressions replacing deposit beta with depositor demographics. Tests whether demographics directly predict closures without going through deposit beta. Columns 1–2: college frac, log income, stock market frac, age bins, county deposit HHI, population density; columns 3–4: replace college/stock market frac with sophisticated zipcode (combined education + stock market participation). Odd columns: state–year + bank–year FE; even columns: county–year + bank–year FE. Panel A: full sample; Panel B: by bank size. Standard errors clustered by bank. Source: `code/analysis/key_closure_results_02172026.qmd` (tbl-closure-reduced-form).

Panel A: Full Sample
```
                                        model 1    model 2    model 3    model 4
College frac                          0.0064***  0.0137***                      
                                     (0.0025)   (0.0023)                        
Log(Income)                           0.5047***  0.4930***  0.2766***  0.2433***
                                     (0.0726)   (0.0892)   (0.0624)   (0.0829)  
Stock market frac                     0.0171***  0.0097***                      
                                     (0.0037)   (0.0036)                        
Age Q1-Q2                             0.0011*    0.0010*    0.0011*    0.0010*  
                                     (0.0006)   (0.0005)   (0.0006)   (0.0006)  
Age Q2-Q3                             0.0007     0.0008     0.0012     0.0014*  
                                     (0.0007)   (0.0006)   (0.0007)   (0.0007)  
Age >Q3                               0.0007     0.0015*    0.0021**   0.0028***
                                     (0.0009)   (0.0008)   (0.0010)   (0.0010)  
County deposit HHI                   -0.0067***            -0.0066***           
                                     (0.0020)              (0.0021)             
Population density                    0.0058***             0.0075***           
                                     (0.0019)              (0.0020)             
log(lag_branch_deposit_amount)       -0.0160*** -0.0158*** -0.0159*** -0.0156***
                                     (0.0006)   (0.0005)   (0.0006)   (0.0005)  
same_zip_prior_3yr_branches           0.0485***  0.0461***  0.0487***  0.0464***
                                     (0.0062)   (0.0062)   (0.0062)   (0.0062)  
legacy_branch                        -0.0069*** -0.0068*** -0.0068*** -0.0067***
                                     (0.0012)   (0.0013)   (0.0012)   (0.0013)  
lag_county_deposit_gr                 0.0013**              0.0015**            
                                     (0.0006)              (0.0006)             
lag_hmda_mtg_amt_gr                  -0.0071***            -0.0074***           
                                     (0.0025)              (0.0024)             
lag_cra_loan_amount_amt_lt_1m_gr     -0.0004               -0.0005              
                                     (0.0006)              (0.0006)             
lag_establishment_gr                 -0.1236***            -0.1264***           
                                     (0.0218)              (0.0232)             
lag_payroll_gr                        0.0002                0.0032              
                                     (0.0052)              (0.0052)             
pop_w_lmi                            -0.0038***            -0.0044***           
                                     (0.0011)              (0.0011)             
log(lag_bank_county_mortgage_volume) -0.0004    -0.0006*   -0.0004    -0.0006** 
                                     (0.0003)   (0.0003)   (0.0003)   (0.0003)  
log(lag_bank_county_cra_volume)      -0.0005    -0.0007**  -0.0005*   -0.0008** 
                                     (0.0003)   (0.0004)   (0.0003)   (0.0004)  
log1p(family_income)                 -0.5090*** -0.4982*** -0.2784*** -0.2456***
                                     (0.0732)   (0.0896)   (0.0629)   (0.0832)  
Sophisticated zipcode                                       0.0023***  0.0024***
                                                           (0.0006)   (0.0005)  
Fixed-Effects:                       ---------- ---------- ---------- ----------
state_yr                                    Yes         No        Yes         No
bank_yr                                     Yes        Yes        Yes        Yes
county_yr                                    No        Yes         No        Yes
____________________________________ __________ __________ __________ __________
S.E.: Clustered                      by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                          1,735,826  1,802,203  1,735,826  1,802,203
R2                                      0.09464    0.12534    0.09451    0.12522
Within R2                               0.01401    0.01340    0.01387    0.01327
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```

Panel B: By Size
```
                                         model 1     model 2     model 3     model 4     model 5     model 6     model 7     model 8
                                     Large Banks Large Banks Large Banks Large Banks Small Banks Small Banks Small Banks Small Banks
                                                                                                                                    
College frac                           0.0043      0.0119***   0.0098***   0.0168***                                                
                                      (0.0047)    (0.0040)    (0.0022)    (0.0028)                                                  
Log(Income)                            0.8552***   0.6822***   0.2701***   0.3417***   0.4628***   0.2658*     0.1485**    0.1953** 
                                      (0.1326)    (0.1832)    (0.0684)    (0.0811)    (0.1032)    (0.1499)    (0.0675)    (0.0792)  
Stock market frac                      0.0354***   0.0299***  -0.0019     -0.0090**                                                 
                                      (0.0044)    (0.0047)    (0.0032)    (0.0036)                                                  
Age Q1-Q2                              0.0030***   0.0025***  -0.0003     -0.0004      0.0030***   0.0026***  -0.0006     -0.0006   
                                      (0.0007)    (0.0006)    (0.0004)    (0.0005)    (0.0007)    (0.0007)    (0.0004)    (0.0005)  
Age Q2-Q3                              0.0027**    0.0020**   -0.0007     -0.0005      0.0038***   0.0034***  -0.0009*    -0.0008   
                                      (0.0010)    (0.0008)    (0.0006)    (0.0007)    (0.0011)    (0.0009)    (0.0006)    (0.0006)  
Age >Q3                                0.0030**    0.0029**   -0.0008     -2.47e-5     0.0064***   0.0065***  -0.0009     -0.0002   
                                      (0.0014)    (0.0012)    (0.0008)    (0.0008)    (0.0014)    (0.0013)    (0.0008)    (0.0008)  
County deposit HHI                     0.0009                 -0.0102***               0.0027                 -0.0106***            
                                      (0.0036)                (0.0019)                (0.0036)                (0.0019)              
Population density                     0.0002                  0.0110***               0.0016                  0.0127***            
                                      (0.0033)                (0.0017)                (0.0035)                (0.0017)              
log(lag_branch_deposit_amount)        -0.0192***  -0.0186***  -0.0142***  -0.0141***  -0.0187***  -0.0182***  -0.0142***  -0.0141***
                                      (0.0011)    (0.0010)    (0.0005)    (0.0005)    (0.0011)    (0.0010)    (0.0005)    (0.0005)  
same_zip_prior_3yr_branches            0.0454***   0.0404***   0.0498***   0.0472***   0.0458***   0.0410***   0.0499***   0.0474***
                                      (0.0102)    (0.0107)    (0.0071)    (0.0069)    (0.0102)    (0.0107)    (0.0071)    (0.0069)  
legacy_branch                         -0.0066***  -0.0071***  -0.0078***  -0.0082***  -0.0064***  -0.0068***  -0.0077***  -0.0081***
                                      (0.0021)    (0.0024)    (0.0012)    (0.0013)    (0.0021)    (0.0024)    (0.0012)    (0.0013)  
lag_county_deposit_gr                  0.0027**                0.0008                  0.0035**                0.0009               
                                      (0.0013)                (0.0006)                (0.0014)                (0.0006)              
lag_hmda_mtg_amt_gr                   -0.0058                 -0.0066***              -0.0063                 -0.0066***            
                                      (0.0050)                (0.0022)                (0.0050)                (0.0022)              
lag_cra_loan_amount_amt_lt_1m_gr      -0.0006                  0.0002                 -0.0009                  0.0002               
                                      (0.0020)                (0.0005)                (0.0019)                (0.0005)              
lag_establishment_gr                  -0.2227***              -0.0564***              -0.2417***              -0.0533***            
                                      (0.0464)                (0.0173)                (0.0490)                (0.0175)              
lag_payroll_gr                        -0.0117                  0.0084                 -0.0039                  0.0094               
                                      (0.0101)                (0.0059)                (0.0102)                (0.0059)              
pop_w_lmi                             -0.0061***              -0.0020*                -0.0072***              -0.0019*              
                                      (0.0022)                (0.0011)                (0.0020)                (0.0011)              
log(lag_bank_county_mortgage_volume)  -0.0007      0.0004     -0.0004     -0.0007***  -0.0005      0.0003     -0.0003     -0.0007***
                                      (0.0008)    (0.0011)    (0.0002)    (0.0002)    (0.0007)    (0.0011)    (0.0002)    (0.0002)  
log(lag_bank_county_cra_volume)        0.0008      0.0011     -0.0007***  -0.0008***   0.0007      0.0010     -0.0007***  -0.0008***
                                      (0.0006)    (0.0008)    (0.0003)    (0.0003)    (0.0006)    (0.0008)    (0.0003)    (0.0003)  
log1p(family_income)                  -0.8624***  -0.6899***  -0.2724***  -0.3455***  -0.4659***  -0.2690*    -0.1493**   -0.1970** 
                                      (0.1334)    (0.1839)    (0.0688)    (0.0814)    (0.1039)    (0.1504)    (0.0679)    (0.0795)  
Sophisticated zipcode                                                                  0.0044***   0.0050***   0.0004      0.0006   
                                                                                      (0.0009)    (0.0006)    (0.0004)    (0.0005)  
Fixed-Effects:                        ----------  ----------  ----------  ----------  ----------  ----------  ----------  ----------
state_yr                                     Yes          No         Yes          No         Yes          No         Yes          No
bank_yr                                      Yes         Yes         Yes         Yes         Yes         Yes         Yes         Yes
county_yr                                     No         Yes          No         Yes          No         Yes          No         Yes
____________________________________  __________  __________  __________  __________  __________  __________  __________  __________
S.E.: Clustered                       by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID
Observations                             682,236     698,499   1,053,588   1,090,424     682,236     698,499   1,053,588   1,090,424
R2                                       0.04900     0.09708     0.14338     0.19442     0.04869     0.09679     0.14334     0.19437
Within R2                                0.01423     0.01288     0.01461     0.01408     0.01390     0.01257     0.01457     0.01401
---
Signif. codes: 0 '***' 0.01 '**' 0.05 '*' 0.1 ' ' 1
```