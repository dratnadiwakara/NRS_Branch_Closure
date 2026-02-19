---
name: Referee broader implications plan
overview: "A plan to address the JFE referee and editor comments on the broader implications of branch closures (things-to-do 20-23 and 53-72), implementing six empirical analyses: competitor deposit reallocation (SOD + event study), market structure (HHI), small business lending (CRA), mortgage outcomes (HMDA), banking deserts, and closure cascades. The plan incorporates Sun and Abraham event-study implementation patterns from the deposit-reallocation-branch-closure repo."
todos: []
isProject: false
---

# Plan: Addressing Broader Implications of Branch Closures (JFE R&R)

**Target comments:** [referee-reports/things-to-do.md](referee-reports/things-to-do.md) lines 20-23 (Editor) and 53-72 (Referee §1 — Contribution and broader implications).

**Deliverable:** Create [referee-reports/referee_response_plan.md](referee-reports/referee_response_plan.md) with the content below (this plan). Implementation will follow in separate code/analysis steps.

---

## 1. Summary of comments

- **Editor (20-23):** Draw out broader implications: how closures affect local market structure and competition, whether they create banking deserts, how nearby branches respond, and downstream outcomes (e.g. small-business lending).
- **Referee (53-72):** Paper does not address why closures matter. Requested: (1) effect on local competition and nearby branches (same bank and competitors), (2) clustering of closures/openings across banks, (3) who is hurt/helped. The existing "PLAN TO ADDRESS COMMENT" in things-to-do lists six concrete tasks.

---

## 2. Data and codebase context

- **Existing NRS data/code:** Branch-year panel with `zip`, `STCNTYBR` (county), `RSSDID`, `closed`, `DEPSUMBR`; SOD at `C:/OneDrive/data/fdic_sod_2000_2025_simple.rds`; county-level deposit HHI in [code/sample-construction/create_closure_analysis_sample_02172026.R](code/sample-construction/create_closure_analysis_sample_02172026.R) and [code/sample-construction/create_county_controls_panel.R](code/sample-construction/create_county_controls_panel.R); HMDA/CRA at bank-county-year (`hmda_bank_county_yr.rds`, `cra_bank_county_yr.rds`) and county-level in county controls; branch panel has `same_zip_prior_3yr_branches`, `lag_bank_county_mortgage_volume`, `lag_bank_county_cra_volume`. Closure specification: `closed ~ deposit_beta + ..ctrl_state_closure | state_yr + bank_yr` in [code/analysis/closure_se_bootstrap_02172026.R](code/analysis/closure_se_bootstrap_02172026.R).
- **Reference implementation (event study):** [deposit-reallocation-branch-closure](https://github.com/dratnadiwakara/deposit-reallocation-branch-closure) uses **fixest** `sunab(cohort, YEAR, ref.p = -1)` with unit = bank-county, outcome = log(1+deposits), cohort = first closure year; samples never-treated; uses `sunab_tidy()` + `add_ref_point()` and ggplot for event-time plots; optionally excludes branches that close at cohort for a "consistent branch set."

---

## 3. Implementation plan by task

**Task 1: Replicate competitor regressions with branch-based treatment (zip-year panel)**

- **Objective:** Port the regressions in results_competitor_close_open_v6.7.qmd ([https://raw.githubusercontent.com/dratnadiwakara/r-utilities/refs/heads/main/Projects/deposits_closures_openings/results_competitor_close_open_v6.7.qmd](https://raw.githubusercontent.com/dratnadiwakara/r-utilities/refs/heads/main/Projects/deposits_closures_openings/results_competitor_close_open_v6.7.qmd)) into this project, but replace share_deps_closed (and related deposit-share measures) with:\
- fraction_of_branches_closed = closed branches in the zip over the window / branches_zip_lag1, and
- fraction_of_new_branches = new branches in the zip over the window / branches_zip_lag1 (or lagged total branches).
- **Specification:** In each of the key regressions, include **both** new variables **in the same regression**, e.g.:
- Baseline:

feols(gr_3yr_own ~ fraction_of_branches_closed + fraction_of_new_branches + log1p(branches_zip_lag1) | ZIPBR + cbsa_yr, data = dt)

plus the small-shock / volume variants and splits by period (2000–2007, >2011), mirroring the original QMD.

- Interaction models:

feols(gr_3yr_own ~ fraction_of_branches_closed * sophisticated_ed_sm + fraction_of_new_branches + log1p(branches_zip_lag1) | ZIPBR + cbsa_yr, data = dt)

and the richer versions with above_median_age and above_median_income, again always including both branch-based variables.

### Task 2: Competing banks’ deposits in same zip/county after a closure (SOD, DiD / event study)

- **Goal:** Test whether competing banks’ branches in the same zip or county gain deposits in years following a closure.
- **Data:** SOD (branch-year: `ZIPBR`/zip, `STCNTYBR`, `RSSDID`, `DEPSUMBR`); closure events from branch panel (year and zip or county of closure; identify “closing bank” and “competitor” banks in that geography).
- **Unit of observation:** Either (i) bank–zip–year or (ii) bank–county–year for **non-closing** banks (competitors) in zip/county where at least one closure occurred.
- **Outcome:** Sum of deposits (or log(1+deposits)) for competitor bank in that zip/county–year.
- **Design:** Event study around first closure in the zip/county (by any bank). Define cohort = first closure year in that geography; include zip/county–years with no closure as never-treated (sample if needed). Use **Sun and Abraham**: `feols(log1p(deposits) ~ sunab(cohort, yr, ref.p = -1) | unit_id + yr, data = ..., vcov = ~ RSSDID)` with `unit_id = bank_id × zip` (or county). Align with existing specification by including geography and time FEs; consider interactions with number of branches closed/open as in things-to-do.
- **Output:** Event-time coefficients and plot (reuse pattern: `sunab_tidy`, `add_ref_point`, ggplot with project theme from [.cursor/rules/r-code-conventions.mdc](.cursor/rules/r-code-conventions.mdc)). Save plot in `figures/` with date suffix; cache key results with `saveRDS`.

### Task 3: County- or zip-level deposit HHI after closures

- **Goal:** Test whether deposit HHI at county or zip level increases in years following branch closures relative to areas without closures.
- **Data:** SOD to compute HHI by zip–year and county–year (sum of squared deposit shares by bank); closure events at zip/county–year.
- **Unit:** County–year or zip–year.
- **Outcome:** Deposit HHI (or change in HHI).
- **Design:** Event study with geography as unit; cohort = first year of closure in that county/zip. Specification: `feols(HHI or delta_HHI ~ sunab(cohort, yr, ref.p = -1) | county_id + yr, ...)` (or zip_id). Robustness: control for pre-trend demographics if not fully absorbed by FE.
- **Output:** Event plot and coefficient table; optional: DiD with binary “any closure in prior K years” and geography + year FE.

### Task 4: Small business lending (CRA) after branch closures

- **Goal:** Test whether county-level (or bank-county) small business lending declines after branch closures, especially where the closed branch’s bank was a primary lender.
- **Data:** CRA at bank–county–year (`cra_bank_county_yr.rds`); county-level CRA from county controls if needed; closure events and branch panel to flag “primary lender” counties (e.g. bank with largest share of county CRA in t-1).
- **Unit:** County–year (primary) or bank–county–year (secondary).
- **Outcome:** CRA small business loan volume (or growth) at county level; optionally by bank in that county.
- **Design:** Event study at county level: cohort = first closure year in county; outcome = total CRA volume (or log) in county. Subgroup: counties where closing bank was primary CRA lender vs not. Use `sunab(cohort, yr, ref.p = -1) | county_id + yr` and cluster at county.
- **Output:** Event plots and tables; interpretation that null effects are informative (referee note).

### Task 5: Mortgage origination (HMDA) after branch reductions

- **Goal:** Test whether mortgage origination volumes or approval rates fall in areas with net branch reductions, especially for lower-income borrowers.
- **Data:** HMDA county-level (or applicant-level if available) from county controls / HMDA files; branch panel to measure net branch change by county–year or zip–year.
- **Unit:** County–year (and optionally borrower segment).
- **Outcome:** Mortgage volume (or approval rate) at county level; by income segment if data permit.
- **Design:** Event study: cohort = first year of net branch reduction in county; outcome = log(1+volume) or approval rate. Interact with low-income indicator (e.g. LMI from county controls) to speak to “who is hurt.”
- **Output:** Event plots and tables; discussion of in-person reliance channel.

### Task 6: Banking deserts (branch density after closure)

- **Goal:** Measure share of closures that cause zip/county to fall below a branch-density threshold (e.g. zero branches or &lt; 1 branch per X residents); document concentration by demographics.
- **Data:** SOD for branch counts by zip and county by year; closure events; population (or demographics) from zip/county panels to form branches per capita.
- **Unit:** Closure event (or zip–year / county–year).
- **Logic:** For each closure, compute branch count in that zip/county in year before and after; flag “desert created” if post-closure count = 0 or branches per capita &lt; threshold. Merge to demographics (income, age, education from zip_demographics_panel / county).
- **Output:** Summary stats: fraction of closures creating a desert; cross-tabs or regressions by demographic groups; optional map or bar charts. Use project palette and ggsave with date suffix.

### Task 7: Competitor closure cascades (same zip)

- **Goal:** Test whether one bank’s closure in a zip predicts other banks’ closures in the same zip in the next 1–2 years.
- **Data:** Branch panel with zip, bank (RSSDID), year, and closure indicator.
- **Unit:** Bank–zip–year (or zip–year with “number of competitor closures” as outcome).
- **Design:** (A) Regress indicator “bank b closes a branch in zip z in t” on “any other bank closed in zip z in t-1 (or t-2)” plus bank–year and zip FE (or bank–zip FE). (B) Alternatively: zip–year outcome = number of closures in t; regress on lagged number of closures and FE. Clustering at zip or state–year.
- **Output:** Coefficient and SE on lagged (other-bank) closure; short interpretation of coordinated vs cascading de-branching.

---

## 4. Event study (Sun and Abraham) implementation pattern

To keep analyses comparable and publication-ready:

- **Cohort:** Define as first treatment year (first closure in geography or first net reduction, depending on task). Use a single ref period (e.g. -1) and normalize never-treated to a large cohort (e.g. 10000) so fixest drops them from the sunab coefficients.
- **Sample:** Treated units in [cohort - 3, cohort + 3]; never-treated: random sample (e.g. 50%) to keep estimation manageable.
- **Helpers:** Port or adapt `sunab_tidy()` and `add_ref_point()` from deposit-reallocation-branch-closure (extract event_time, estimate, se from `coeftable(model)` for sunab terms; add ref row with estimate=0, se=0).
- **Plot:** ggplot: x = event_time, y = estimate, geom_line + geom_point + geom_errorbar(ymin = estimate - 1.96*se, ymax = estimate + 1.96*se); apply `theme_custom` and project colors from [.cursor/rules/r-code-conventions.mdc](.cursor/rules/r-code-conventions.mdc); legend title = element_blank().
- **VCov:** Cluster at the level of treatment (e.g. bank_id for bank-level outcomes, county for county-level).

---

## 5. Suggested order and file structure

1. **Data prep (one-time):** Build geography–year closure/opening counts and cohort from branch panel + SOD; compute zip–year and county–year HHI from SOD; ensure CRA/HMDA at county (and bank–county) are mergeable by year and geography. Consider a single script or Qmd that produces: `closure_events_zip_yr.rds`, `closure_events_county_yr.rds`, `zip_yr_hhi.rds`, `county_yr_hhi.rds` (if not already in county_controls).
2. **Task 1 (competitor deposits):** New script or section in a Qmd: build competitor bank–zip–year (or bank–county–year) panel, run sunab, plot, save results.
3. **Task 2 (HHI):** Script: county–year (and optionally zip–year) HHI event study; plot and table.
4. **Task 3 (CRA):** Script: county–year CRA event study; primary-lender subsample.
5. **Task 4 (HMDA):** Script: county–year HMDA event study; low-income interaction if data allow.
6. **Task 5 (banking deserts):** Mostly descriptive: define threshold, merge demographics, summarize and optionally plot by group.
7. **Task 6 (cascades):** Single regression script: bank–zip–year or zip–year, lagged other-bank closure.

Suggested locations: `code/analysis/` for all new analysis scripts (e.g. `broader_implications_competitor_deposits.R`, `broader_implications_hhi.R`, …) or a single Qmd `code/analysis/broader_implications_event_studies.qmd` with sections. Use relative paths and `data_path` as in conventions; `figures/` for all plots with date suffix; cache intermediate objects in `data_path`.

---

## 6. Paper and response memo

- **Paper:** Add a new subsection (e.g. “Broader implications of branch closures”) that presents: (1) competitor deposit reallocation (Task 1), (2) market structure/HHI (Task 2), (3) small business lending (Task 3), (4) mortgages (Task 4), (5) banking deserts (Task 5), (6) closure cascades (Task 6). Emphasize that null results (e.g. no CRA decline) are informative about which margins matter.
- **Response memo:** In the point-by-point response, cite the new subsection and the specific exhibits (tables/figures) for each referee and editor request (“how are nearby branches affected,” “market structure,” “who is hurt,” “clustering/cascading,” “downstream outcomes”).

---

## 7. Checklist (from things-to-do, mapped to tasks)


| Item                                                                                      | Task   |
| ----------------------------------------------------------------------------------------- | ------ |
| SOD, competing banks’ branches gain deposits after closure; DiD; align with existing spec | Task 1 |
| Branch closures as events; county/zip HHI rises after closure                             | Task 2 |
| CRA: small business lending in county after closures; primary lender                      | Task 3 |
| HMDA: mortgage volume/approval in areas with net branch reductions; lower-income          | Task 4 |
| Banking deserts (branch density threshold); who is hurt                                   | Task 5 |
| Closures by one bank predict other banks’ closures in same zip in 1–2 years               | Task 6 |


This plan should be saved as **referee-reports/referee_response_plan.md** so the team can track progress and attach it to the revision. Implementation will follow project R conventions (libraries at top, set.seed once, relative paths, Roxygen2 for functions, saveRDS for key objects, theme_custom and ggsave with date suffix).