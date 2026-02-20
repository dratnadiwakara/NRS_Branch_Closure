---
layout: default
title: Key opening results — NRS Branch Closure
---
## [← Index](index.html) · [1. Editor and referee comments](response-plan.html)

# Key Branch Opening Results

Collected key regression results from branch opening analysis. No descriptive statistics.

*Source: `code/analysis/key_opening_results_02202026.qmd`*

---

## 1. Baseline Opening Model

Branch-level opening indicator (`new_branch_zip`) regressed on predicted deposit beta and controls. Odd columns: state–year and bank–year fixed effects; even columns: county–year and bank–year fixed effects. Columns 1–2: all banks; 3–4: large banks (CPI-adjusted assets ≥ $100M); 5–6: small banks. Controls include log zip deposits, county deposit growth, HMDA mortgage and CRA lending growth, establishment and payroll growth, LMI, log lag county CRA/mortgage volume, and log(1 + family income). Standard errors clustered by bank (RSSDID). Source: `code/analysis/key_opening_results_02202026.qmd` (tbl-baseline-opening).

```
                                   model 1     model 2     model 3     model 4     model 5     model 6
                                 All Banks   All Banks Large Banks Large Banks Small Banks Small Banks
                                                                                                      
Deposit Beta                     0.0227***  0.0257***    0.0724***   0.0718***   0.0175***   0.0215***
                                (0.0016)   (0.0014)     (0.0125)    (0.0121)    (0.0008)    (0.0008)  
log(Zip Deposits)                0.0003***  0.0003***    0.0005***   0.0006***   0.0002***   0.0002***
                                (1.91e-5)  (1.87e-5)    (0.0001)    (0.0001)    (8.09e-6)   (8.58e-6) 
County Deposit Growth           -0.0005***              -0.0002                 -0.0006***            
                                (9.21e-5)               (0.0005)                (8.73e-5)             
Mortgage Growth                 -0.0002                 -0.0054***               0.0008***            
                                (0.0004)                (0.0018)                (0.0003)              
CRA Loan Growth                 -0.0002                  0.0003                 -0.0005***            
                                (0.0002)                (0.0006)                (0.0001)              
Establishment Growth             0.0293***               0.0530***               0.0239***            
                                (0.0022)                (0.0096)                (0.0015)              
Payroll Growth                   0.0003                 -4.16e-6                 0.0004               
                                (0.0006)                (0.0024)                (0.0005)              
Low-to-Moderate Income          -0.0003**                0.0015**               -0.0007***            
                                (0.0001)                (0.0006)                (8.13e-5)             
log(Lag County CRA Volume)       0.0004***              -0.0003                  0.0008***            
                                (0.0001)                (0.0002)                (6.81e-5)             
log(Lag County Mortgage Volume) -0.0003*                 0.0009**               -0.0009***            
                                (0.0002)                (0.0004)                (7.92e-5)             
log(Income)                     -7.2e-5**  -9.38e-5***  -7.4e-5      4.99e-5    -0.0001***  -0.0001***
                                (2.96e-5)  (2.61e-5)    (0.0001)    (0.0002)    (1.88e-5)   (1.89e-5) 
Fixed-Effects:                  ---------- -----------  ----------  ----------  ----------  ----------
state_yr                               Yes          No         Yes          No         Yes          No
bank_yr                                Yes         Yes         Yes         Yes         Yes         Yes
county_yr                               No         Yes          No         Yes          No         Yes
_______________________________ __________ ___________  __________  __________  __________  __________
S.E.: Clustered                 by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID
Observations                    18,278,991  18,280,979   1,974,418   1,974,648  16,304,573  16,306,331
R2                                 0.02794     0.03666     0.02473     0.04156     0.03035     0.04379
Within R2                          0.00102     0.00082     0.00327     0.00178     0.00080     0.00071

Mean opening rate by regime:
Full sample: 0.001743 
Large banks: 0.004254 
Small banks: 0.001439 
```

---

## 2. Openings by Time Period

Branch opening regressions by subperiod. Same specification as baseline (new_branch_zip on deposit beta and controls; odd columns: state–year + bank–year FE; even columns: county–year + bank–year FE). Four periods: 2001–2007, 2008–2011, 2012–2019, 2020–2023. Panel A: large banks; Panel B: small banks. Standard errors clustered by bank. Source: `code/analysis/key_opening_results_02202026.qmd` (tbl-opening-large-by-cycle, tbl-opening-small-by-cycle).

Panel A: Large Banks

```

                                   model 1    model 2    model 3    model 4    model 5    model 6    model 7    model 8
Deposit Beta                     0.1176***  0.1368***  0.0858***  0.0930***  0.0395***  0.0365***  0.0556**   0.0532*  
                                (0.0198)   (0.0220)   (0.0176)   (0.0186)   (0.0080)   (0.0082)   (0.0275)   (0.0272)  
log(Zip Deposits)                0.0011***  0.0012***  0.0012***  0.0012***  0.0002***  0.0002***  0.0003**   0.0004** 
                                (0.0001)   (0.0001)   (0.0003)   (0.0003)   (5.18e-5)  (5.35e-5)  (0.0002)   (0.0002)  
log(Income)                      0.0045***  0.0052***  0.0030**   0.0035*   -0.0007**  -0.0004    -0.0003*** -0.0003***
                                (0.0010)   (0.0011)   (0.0013)   (0.0018)   (0.0004)   (0.0004)   (8.23e-5)  (8.43e-5) 
Fixed-Effects:                  ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
state_yr                               Yes         No        Yes         No        Yes         No        Yes         No
bank_yr                                Yes        Yes        Yes        Yes        Yes        Yes        Yes        Yes
county_yr                               No        Yes         No        Yes         No        Yes         No        Yes
_______________________________ __________ __________ __________ __________ __________ __________ __________ __________
S.E.: Clustered                 by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                       377,514    377,553    296,143    296,177    703,731    703,815    558,657    558,728
R2                                 0.02418    0.04467    0.03776    0.05182    0.00877    0.01856    0.01328    0.02630
Within R2                          0.00608    0.00431    0.00538    0.00292    0.00170    0.00076    0.00327    0.00145
```

Panel B: Small Banks

```
                                   model 1    model 2    model 3    model 4    model 5    model 6     model 7     model 8
Deposit Beta                     0.0249***  0.0312***  0.0144***  0.0194***  0.0165***  0.0201***  0.0110***   0.0142*** 
                                (0.0017)   (0.0017)   (0.0013)   (0.0015)   (0.0010)   (0.0011)   (0.0010)    (0.0011)   
log(Zip Deposits)                0.0004***  0.0004***  0.0003***  0.0003***  0.0002***  0.0002***  0.0001***   0.0001*** 
                                (1.64e-5)  (1.66e-5)  (2.81e-5)  (3.09e-5)  (5.5e-6)   (6.01e-6)  (5.94e-6)   (6.51e-6)  
log(Income)                      0.0001     0.0001     0.0003***  0.0003*** -0.0005*** -0.0006*** -8.03e-5*** -5.72e-5***
                                (0.0001)   (9.02e-5)  (8.54e-5)  (8.4e-5)   (5.95e-5)  (5.96e-5)  (1.67e-5)   (1.85e-5)  
Fixed-Effects:                  ---------- ---------- ---------- ---------- ---------- ---------- ----------- -----------
state_yr                               Yes         No        Yes         No        Yes         No         Yes          No
bank_yr                                Yes        Yes        Yes        Yes        Yes        Yes         Yes         Yes
county_yr                               No        Yes         No        Yes         No        Yes          No         Yes
_______________________________ __________ __________ __________ __________ __________ __________ ___________ ___________
S.E.: Clustered                 by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID  by: RSSDID  by: RSSDID
Observations                     4,578,610  4,579,156  2,850,855  2,851,143  5,047,733  5,048,226   3,296,208   3,296,572
R2                                 0.03504    0.04872    0.03168    0.04499    0.02069    0.03230     0.01835     0.02975
Within R2                          0.00117    0.00105    0.00087    0.00077    0.00066    0.00058     0.00058     0.00051
```

```

Large banks mean opening rate by regime:
2001-2007: 0.007911 
2008-2011: 0.008411 
2012-2019: 0.001738 
2020-2023: 0.002577 

Small banks mean opening rate by regime:
2001-2007: 0.002343 
2008-2011: 0.001538 
2012-2019: 0.000850 
2020-2023: 0.000874 
```

---

## 3. Reduced Form: Demographics and Openings

Panel A: Full Sample

```
                                   model 1    model 2    model 3    model 4
College frac                     0.0039***  0.0042***                      
                                (0.0003)   (0.0003)                        
Stock market frac                0.0011***  0.0010***                      
                                (0.0003)   (0.0002)                        
Sophisticated zipcode                                  0.0014***  0.0013***
                                                      (7.59e-5)  (7.79e-5) 
log(Zip Deposits)                0.0003***  0.0003***  0.0003***  0.0003***
                                (1.85e-5)  (1.83e-5)  (1.87e-5)  (1.85e-5) 
Age Q1-Q2                       -0.0004*** -0.0003*** -0.0005*** -0.0004***
                                (6.57e-5)  (6.06e-5)  (6.92e-5)  (6.4e-5)  
Age Q2-Q3                       -0.0008*** -0.0007*** -0.0009*** -0.0008***
                                (9.42e-5)  (8.73e-5)  (9.37e-5)  (8.77e-5) 
Age >Q3                         -0.0011*** -0.0011*** -0.0011*** -0.0010***
                                (0.0001)   (0.0001)   (0.0001)   (0.0001)  
County deposit HHI              -0.0014***            -0.0010***           
                                (0.0002)              (0.0002)             
Population density              -0.0011***            -0.0007***           
                                (0.0002)              (0.0003)             
log(Income)                     -0.0003*** -0.0004*** -4.73e-6   -1.06e-5  
                                (4.16e-5)  (3.26e-5)  (4.38e-5)  (3.6e-5)  
Fixed-Effects:                  ---------- ---------- ---------- ----------
state_yr                               Yes         No        Yes         No
bank_yr                                Yes        Yes        Yes        Yes
county_yr                               No        Yes         No        Yes
_______________________________ __________ __________ __________ __________
S.E.: Clustered                 by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                    18,278,991 18,279,222 18,278,991 18,279,222
R2                                 0.02800    0.03669    0.02796    0.03664
Within R2                          0.00108    0.00085    0.00103    0.00079
```

Panel B: By Bank Size

```
                                     model 1    model 2    model 3    model 4    model 5    model 6    model 7    model 8
college_frac                       0.0123***  0.0134***  0.0033***  0.0034***                                            
                                  (0.0018)   (0.0018)   (0.0002)   (0.0002)                                              
log(family_income)                -0.0553    -0.0446     0.0342***  0.0318*** -0.1468**  -0.1442**   0.0043    -0.0030   
                                  (0.0537)   (0.0522)   (0.0085)   (0.0092)   (0.0569)   (0.0558)   (0.0082)   (0.0090)  
dividend_frac                      0.0006     0.0007     0.0009***  0.0010***                                            
                                  (0.0018)   (0.0017)   (0.0002)   (0.0002)                                              
factor_age_bin2                   -0.0016*** -0.0013*** -0.0002*** -0.0002*** -0.0018*** -0.0014*** -0.0004*** -0.0003***
                                  (0.0004)   (0.0004)   (3.45e-5)  (3.23e-5)  (0.0004)   (0.0005)   (3.62e-5)  (3.34e-5) 
factor_age_bin3                   -0.0023*** -0.0021*** -0.0006*** -0.0006*** -0.0024*** -0.0021*** -0.0007*** -0.0006***
                                  (0.0006)   (0.0007)   (4.89e-5)  (4.67e-5)  (0.0006)   (0.0006)   (5.26e-5)  (4.99e-5) 
factor_age_bin4                   -0.0030*** -0.0032*** -0.0008*** -0.0009*** -0.0030*** -0.0029*** -0.0008*** -0.0008***
                                  (0.0007)   (0.0009)   (6.34e-5)  (6.12e-5)  (0.0007)   (0.0008)   (6.85e-5)  (6.52e-5) 
lag_county_deposit_hhi             0.0003               -0.0015***             0.0010               -0.0011***           
                                  (0.0007)              (0.0002)              (0.0007)              (0.0002)             
population_density                 0.0011               -0.0018***             0.0026**             -0.0014***           
                                  (0.0009)              (0.0001)              (0.0011)              (0.0001)             
log_zip_deposits                   0.0005***  0.0006***  0.0002***  0.0002***  0.0005***  0.0006***  0.0002***  0.0002***
                                  (0.0001)   (0.0001)   (7.99e-6)  (8.49e-6)  (0.0001)   (0.0001)   (7.97e-6)  (8.5e-6)  
log1p(family_income)               0.0548     0.0439    -0.0346*** -0.0323***  0.1475**   0.1448**  -0.0044     0.0029   
                                  (0.0538)   (0.0523)   (0.0085)   (0.0092)   (0.0571)   (0.0560)   (0.0083)   (0.0090)  
sophisticated                                                                  0.0030***  0.0031***  0.0012***  0.0011***
                                                                              (0.0005)   (0.0006)   (4.28e-5)  (4.09e-5) 
Fixed-Effects:                    ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------
state_yr                                 Yes         No        Yes         No        Yes         No        Yes         No
bank_yr                                  Yes        Yes        Yes        Yes        Yes        Yes        Yes        Yes
county_yr                                 No        Yes         No        Yes         No        Yes         No        Yes
_________________________________ __________ __________ __________ __________ __________ __________ __________ __________
S.E.: Clustered                   by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                       1,974,418  1,974,648 16,304,573 16,306,331  1,974,418  1,974,648 16,304,573 16,306,331
R2                                   0.02482    0.04171    0.03043    0.04381    0.02455    0.04146    0.03040    0.04377
Within R2                            0.00337    0.00194    0.00088    0.00074    0.00309    0.00168    0.00085    0.00070
```

---

## 4. Openings and Branch Usage (Pandemic Era)

Branch opening regressions for 2020–2023 (pandemic era), adding usage variables from SafeGraph/advan: drop in visits (2019→2021) and log median distance from home. Odd columns: state–year + bank–year FE; even columns: county–year + bank–year FE. First table: full sample (baseline vs with usage); second table: by bank size. Standard errors clustered by bank. Source: `code/analysis/key_opening_results_02202026.qmd` (tbl-open-usage-full, open_usage_by_size).

```

                                   model 1    model 2    model 3    model 4
                                  Baseline   Baseline With Usage With Usage
                                                                           
Deposit Beta                     0.0116***  0.0131***  0.0089**   0.0108***
                                (0.0040)   (0.0034)   (0.0037)   (0.0031)  
log(Zip Deposits)                0.0007***  0.0007***  0.0007***  0.0007***
                                (0.0001)   (0.0001)   (0.0001)   (0.0001)  
log(Income)                     -0.0002*** -0.0001*** -0.0001*** -0.0001***
                                (4.09e-5)  (4.15e-5)  (3.93e-5)  (3.97e-5) 
Drop in visits                                         0.0007***  0.0008***
                                                      (0.0002)   (0.0001)  
Log(Distance km)                                       0.0003***  0.0002***
                                                      (6.84e-5)  (7.65e-5) 
Fixed-Effects:                  ---------- ---------- ---------- ----------
state_yr                               Yes         No        Yes         No
bank_yr                                Yes        Yes        Yes        Yes
county_yr                               No        Yes         No        Yes
_______________________________ __________ __________ __________ __________
S.E.: Clustered                 by: RSSDID by: RSSDID by: RSSDID by: RSSDID
Observations                     2,058,693  2,058,693  2,053,941  2,053,941
R2                                 0.02339    0.03671    0.02357    0.03697
Within R2                          0.00119    0.00094    0.00124    0.00098
```

```

                                    model 1     model 2     model 3     model 4     model 5     model 6     model 7     model 8
                                Large Banks Large Banks Large Banks Large Banks Small Banks Small Banks Small Banks Small Banks
                                                                                                                               
Deposit Beta                      0.0562*      0.0492     0.0493*      0.0419    0.0054***   0.0090***   0.0032***    0.0074***
                                 (0.0320)     (0.0297)   (0.0287)     (0.0271)  (0.0012)    (0.0013)    (0.0012)     (0.0013)  
log(Zip Deposits)                 0.0015**     0.0016**   0.0015**     0.0016**  0.0006***   0.0006***   0.0005***    0.0005***
                                 (0.0007)     (0.0007)   (0.0007)     (0.0007)  (2.98e-5)   (3.07e-5)   (2.91e-5)    (2.97e-5) 
log(Income)                      -0.0006***   -0.0006**  -0.0006***   -0.0005** -9.28e-5*** -8.04e-5*** -7.99e-5***  -7.3e-5** 
                                 (0.0002)     (0.0002)   (0.0002)     (0.0002)  (2.63e-5)   (2.88e-5)   (2.6e-5)     (2.86e-5) 
Drop in visits                                            0.0013       0.0010                            0.0006***    0.0008***
                                                         (0.0010)     (0.0009)                          (7.72e-5)    (9.27e-5) 
Log(Distance km)                                          0.0010**     0.0011**                          0.0003***    0.0001** 
                                                         (0.0004)     (0.0004)                          (5.72e-5)    (6.05e-5) 
Fixed-Effects:                   ----------   ---------  ----------   --------- ----------- ----------- -----------  ----------
state_yr                                Yes          No         Yes          No         Yes          No         Yes          No
bank_yr                                 Yes         Yes         Yes         Yes         Yes         Yes         Yes         Yes
county_yr                                No         Yes          No         Yes          No         Yes          No         Yes
_______________________________  __________   _________  __________   _________ ___________ ___________ ___________  __________
S.E.: Clustered                  by: RSSDID   by: RSS..  by: RSSDID   by: RSS..  by: RSSDID  by: RSSDID  by: RSSDID  by: RSSDID
Observations                        278,972     278,972     277,978     277,978   1,779,721   1,779,721   1,775,963   1,775,963
R2                                  0.01847     0.03650     0.01868     0.03670     0.02713     0.04739     0.02734     0.04773
Within R2                           0.00438     0.00234     0.00452     0.00244     0.00086     0.00077     0.00090     0.00080
```
```
Mean opening rates (2020–2023):
All banks: 0.001365 
Large banks: 0.003276 
Small banks: 0.001066 
```