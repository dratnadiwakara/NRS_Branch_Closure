
# Editor Comments

Dear Authors,

Thank you for submitting your manuscript to the *Journal of Financial Economics*. I apologize for the delay in getting back to you. I had an accident that resulted in a fractured hand requiring surgery, and as you can imagine, this slowed me down.

I have now read the paper and considered the referee’s report. The referee views the topic as interesting and timely and sees potential for the paper to make a contribution. At the same time, the referee raises a number of substantive concerns regarding interpretation, scope, and clarity that would need to be addressed before the paper could be considered further. In light of these comments and my own reading of the paper, I am willing to offer you the opportunity to revise and resubmit.

Below I list my comments. Some of these echo points raised by the referee:

1. **Construction and interpretation of branch-level deposit beta**  
   I am still a bit unsure how you construct the branch-level deposit beta. If I understand correctly, you first estimate equation (2), where you use bank-level deposit betas and regress them on local characteristics. The local characteristics are constructed by averaging characteristics of the markets in which a given bank is operating. Then, in the next step, you take those characteristics and predict branch-level betas for each branch. Now, if I understand correctly, you are not using any bank-level information in the second step. So that means if two banks have different bank-level betas but operate in the same locations, they will have the same branch deposit betas. Later, you include bank or bank-time fixed effects, thereby netting out the average bank effect. I think that this can work, but I do think you should explain much more explicitly what you are doing.

   You should show the equation that defines how you construct the branch-level betas, and you should explain clearly that they do not contain any bank-level information beyond what is captured through local characteristics. You should also explain how we should think about these betas in the context of your empirical design. If I have misunderstood what you are doing, please clarify precisely how the branch-level betas are constructed and how they should be interpreted.

> **PLAN TO ADDRESS COMMENT**
>

2. **Entry into high-beta areas vs. difficulty moving low-beta customers**  
   You assert that entrants choose high-beta areas because it is hard to move low-beta customers across banks. I certainly agree that it is harder to move low-beta depositors relative to high-beta depositors. However, low-beta deposits are also more valuable than high-beta deposits. Hence, at least theoretically, I do not see that there is a clear prediction on where banks should enter with new branches. Please clarify how you think about this tradeoff and what the underlying intuition or framework implies for entry decisions.

> **PLAN TO ADDRESS COMMENT**
>

3. **Broader implications of branch closures**  
   The referee suggests that the paper would benefit from drawing out the broader implications of branch closures. In particular, it would be helpful to examine how closures affect local market structure and competition, whether they generate “banking deserts” in which households face limited access to physical bank branches, and how nearby branches respond. The referee also notes that exploring downstream outcomes would strengthen the contribution.

   For example, it is unclear a priori whether small-business lending should decline following branch closures. Such an effect may arise if physical branches play an important role in screening and monitoring small firms. Even evidence showing that certain outcomes are not affected would be informative, as it would help clarify which economic margins branch closures do and do not operate through.

<div style="background-color: #e8f5e9; padding: 0.75rem 1rem; border-radius: 4px; border-left: 4px solid #2e7d32; margin: 0.75rem 0;">

**✓ Addressed.** We document (i) how incumbent branches’ deposit growth responds to the fraction of branches closed and new branches in the ZIP (deposit reallocation), and (ii) county-level mortgage and CRA lending growth following branch restructuring, with heterogeneity by income and population-weighted LMI (“who is hurt”). See [Impact of branch restructuring on local deposit and credit markets](impact-of-restructuring-02192026.html) for results.

</div>

> **PLAN TO ADDRESS COMMENT**
> [...]

4. **Variation in betas across deposit types and composition**  
   I agree that there is significant variation in betas across deposit types. I do not think that this fundamentally changes your main point, but it is important to account for it explicitly and to be clear about how composition affects your interpretation.

> **PLAN TO ADDRESS COMMENT**
> [...]

5. **Uniform pricing citations and literature coverage**  
   You cite Begenau and Stafford (2025) in connection with uniform pricing. I should note, however, that this paper bundles together a number of additional claims that I view as problematic. More importantly, the distinction between uniform pricing—specifically, rate setters versus non–rate setters—was already discussed in the original work of Drechsler et al. (2017). In addition, there is an earlier and growing literature that studies uniform pricing in banking. In particular, Dlugosz et al. (*Management Science*, 2023) use uniform pricing for identification, and Granja and Paixao (*JFE*, forthcoming) examine uniform pricing in the context of bank mergers. At a minimum, these papers should be cited to accurately reflect the literature.

> **PLAN TO ADDRESS COMMENT**
> [...]

6. **Updated franchise valuation reference**  
   Finally, the deposit franchise valuation formula you attribute to Drechsler et al. (2023) has since been updated in Drechsler et al. (*JF*, forthcoming). You should incorporate this in your discussion.

> **PLAN TO ADDRESS COMMENT**
> [...]

I hope these comments are helpful as you revise the paper. This is not a guarantee that the paper will be published in the JFE. I will need full support from the referee to proceed. Please keep this in mind when deciding whether to resubmit the paper.

Sincerely,  
Philipp Schnabl  
Co-Editor, *Journal of Financial Economics*  


# Referee Report


## Summary
This paper studies the determinants of bank branch openings and closures in the U.S. over the period 2001–2023, with a particular focus on the role of deposit pricing power and depositor sophistication. The authors argue that advances in digital banking and payment technologies have reduced both banks’ pricing power over deposits and customers’ reliance on physical branch access, with these effects varying systematically across local markets.

To capture this channel, the paper introduces a branch-level measure of deposit interest-rate sensitivity (“deposit beta”), constructed by mapping bank-level deposit betas estimated from interest expense responses over monetary tightening cycles to branch locations using local demographic characteristics associated with financial sophistication. The empirical strategy exploits within-bank variation across branches while absorbing bank-year and local fixed effects.

The paper documents that branches with higher predicted deposit betas are more likely to close, particularly among large banks and in the post-GFC and post-pandemic periods. At the same time, banks are more likely to open branches in areas characterized by high deposit betas. The authors interpret these patterns as reflecting asymmetric incentives: incumbents close branches where deposits generate low franchise value due to high rate sensitivity and low reliance on proximity, while entrants avoid low-beta markets because depositors are difficult to attract away from incumbents in those areas. The paper finds comparatively weak evidence that local lending conditions explain branch restructuring, concluding that deposit-side considerations dominate branch location decisions.

## Comments

### **1. Contribution and broader implications**
While the finding that high-beta branches are more likely to close is interesting, the evidence on the long-run trend in branch closures over the past decade and the role of technological change in driving it is already well documented in the literature (e.g., Jiang et al. 2024; Benmelech et al. 2023). The paper contributes by linking branch closures to deposit beta and by proposing an identification strategy that isolates the effect of deposit pricing power within the same bank. However, many of the core results are not particularly surprising in light of existing work, for example Drechsler, Savov and Schnabl (2017, 2021 and 2023) who show how deposit beta shapes the value of bank deposit franchise.

More importantly, even if the evidence on branch closures is convincing, the paper does not address the broader question of why this matters. The analysis would benefit from a deeper exploration of the implications of branch closures. What happens to local competition after a branch closes? How are nearby branches, both within the same bank and across competing banks, affected? Are branch closures/openings clustered across banks within the same area? Who is ultimately hurt or helped by these closures? Quantifying the effects on market structure, deposit pricing, or consumer outcomes would substantially strengthen the paper’s contribution beyond documenting closure patterns.

<div style="background-color: #e8f5e9; padding: 0.75rem 1rem; border-radius: 4px; border-left: 4px solid #2e7d32; margin: 0.75rem 0;">

**✓ Addressed (in part).** We quantify (i) how incumbent banks’ deposit growth in a ZIP responds to the fraction of branches closed and the fraction of new branches in that ZIP (how nearby branches are affected; deposit reallocation), and (ii) county-level mortgage and CRA lending growth following restructuring, with heterogeneity by low-income and high–LMI counties (“who is hurt or helped”).  See [Impact of branch restructuring on local deposit and credit markets](impact-of-restructuring-02192026.html) for results.

</div>

> **PLAN TO ADDRESS COMMENT**
>
> - [X] Using SOD data, test whether competing banks' branches in the same zip code or county gain deposits in the years following a closure and openings.
>
>
> - [X] Using CRA data, estimate whether small business lending in a county declines following branch closures, particularly in counties where the closed branch was the primary lender.
>
> - [X] Similarly using HMDA data, test whether mortgage origination volumes or approval rates fall in areas that experience net branch reductions, particularly for lower-income borrowers who may rely more heavily on in-person services.
>



### **2. Aggregation across deposit types and interpretation of betas**
The paper measures deposit beta by aggregating all deposit categories (checking, savings and time deposits) into a single measure. This is potentially misleading, as these deposit types exhibit very different interest rate sensitivities. Time deposits typically have much higher betas, often close to one, while savings deposits have substantially lower betas, and checking deposits even lower. As a result, variation in the measured deposit beta used in the paper may to a large extent reflect differences in deposit composition rather than differences in depositor behavior or pricing power.

For example, a bank or branch with a high beta driven by a large share of time deposits is fundamentally different from one with a low beta driven by a predominance of savings or checking deposits. Treating these as comparable risks conflates compositional effects with behavioral or demographic effects and may distort the interpretation of the results.

<div style="background-color: #e8f5e9; padding: 0.75rem 1rem; border-radius: 4px; border-left: 4px solid #2e7d32; margin: 0.75rem 0;">

**✓ Addressed.** Time-deposit share (`time_deposits_assets`) added to the first-stage deposit beta model. See [Key closure results](key-closure-results.html) (Deposit Beta Regression table).

</div>

> **PLAN TO ADDRESS COMMENT**
>
> - [X] For the "first stage" model to predict deposit betas, add more bank-level controls to capture different types of funding.  Currently we have 2: transactions deposits and uninsured deposits.  Can we add at least one more, such as the fraction of time deposits?  This would help us address referee comment 2.  (The other way to do it would be to estimate deposit betas separately by deposit type and then use a weighted average.  I don't really think this is worth the trouble since we do not know the shares at the branch level.)

### **3. Branch opening versus closure and the role of income**
The paper consistently interprets deposit beta as a measure of branch profitability, arguing that lower-beta branches generate greater deposit franchise value. As the authors state, “Deposit Beta provides a consistent ranking: low beta branches generate more value for the bank than high beta ones.” This interpretation naturally explains why banks would close branches with higher betas and lower profitability.

However, this framework is difficult to reconcile with the results on branch openings, which show the opposite pattern: banks are opening branches in high-beta areas. Under the authors’ interpretation, these areas should be less profitable and have weaker deposit franchise value. The authors suggest that low beta makes depositors difficult to attract away from incumbents, but this argument is not clearly articulated and is not supported by direct evidence. The paper does not document customer poaching behavior or show that switching costs are higher in low-beta areas.

In principle, low beta may simply reflect a lack of competition, in which case entry could allow a bank to poach customers relatively easily by offering slightly higher rates while still maintaining profitability. Banks may also compete on non-price margins, such as service quality or account opening bonuses, suggesting additional channels through which customers could be attracted in low-beta regions. Moreover, branch openings involve substantial fixed costs, raising further questions about the profitability of opening branches in high-beta areas. Relatedly, it is not clear why banks would close branches in high-beta areas only to open new branches in similar areas.

In addition, evidence from the closure and opening regressions with local demographic characteristics suggests that local income is a consistent predictor of branch location decisions. Banks appear less likely to close branches and more likely to open them in wealthier areas, consistent with a desire to maximize deposits. This pattern aligns with industry reports and press coverage (e.g., *Wall Street Journal*, “America’s Biggest Bank Is Growing the Old-Fashioned Way: Branches,” 2024) emphasizing the importance of local income and wealth. The wealthiness of an area may matter not only for deposit availability but also for cross-selling opportunities such as credit cards or wealth management. Notably, wealthier areas also tend to have lower deposit betas, as shown in Table 2. This raises the possibility that the branch closure results are driven less by pricing power per se and more by local wealth, with deposit beta acting as a correlated proxy. This channel requires additional analysis and clarification as it is not fully clear to me whether deposit beta is the fundamental driver or partly a proxy for other factors like income. The paper could also benefit from providing case evidence based on specific bank decisions regarding branch expansion, such as recent expansions in branch networks by JP Morgan.

<div style="background-color: #e8f5e9; padding: 0.75rem 1rem; border-radius: 4px; border-left: 4px solid #2e7d32; margin: 0.75rem 0;">

**✓ Addressed (in part).** The “who is hurt or helped” dimension is addressed by heterogeneity in county-level mortgage and CRA lending: we interact closure and opening shares with low-income county and population-weighted LMI. See [Impact of branch restructuring on local deposit and credit markets](impact-of-restructuring-02192026.html). Ln(income) has been broken out in the closings/openings models; see [Key closure results](key-closure-results.html).

</div>

> **PLAN TO ADDRESS COMMENT**
>
> - [X] Break out Ln(income) as another variable in the closings/openings models.  As such, the predicted beta effect would be driven by HHI, share with high education, share with stock market participation and age dummies.  Doing this would help us address comment 3.  The plan is to break out Ln(income) in the 'second stage', not in the 'first stage'. That way the beta coefficient in the second stage is identified off the remaining demographic variation with income absorbing its own direct effect. Let me know if you had something different in mind.
> - [ ] PS to DR email: "This can be addressed with a better exposition. Frame entry as the choice between buying an existing branch (or branch network) via M&A v. De Novo entry. We are looking at de novo entry in our paper, and our results show that it is harder to enter markets this way when people are more rate-insensitive. I think a side prediction, which we don't test, is that entry into these areas will be more likely via M&A, because when a bank enters a market by buying an existing bank's branches, the deposits come with the branch, rather than having to be competed away from incumbents – we can test this Also, note that we are not saying banks enter unprofitable areas. We are just saying that if you want to collect deposits via de novo branching, at the margin it is easier to do that in high-beta areas. As long as beta < 1, you can still raise deposits profitably! The other high-level point to make is that our results reinforce the DSS claim that beta measures market power, since we show that low-beta is not just associated with high concentration and 'sticky' depositors (old, unsophisticated residents); such markets also have high entry barriers, making the profitability of their incumbent banks hard to compete away."

### **4. Importance of lending opportunities for branch closure and opening**
The authors argue that deposit margins are far more important than lending margins in explaining branch closure and opening decisions. This conclusion is based on regressions that include lending growth as an explanatory variable and find limited explanatory power. However, this test faces several challenges.

First, raw measures of lending growth are correlated with local economic conditions, which may also reflect deposit opportunities. In fact, deposit growth itself appears to have limited explanatory power, suggesting broader measurement challenges. Second, deposit beta may partially capture lending opportunities because it reflects local demographics that are correlated with credit demand. To disentangle the roles of deposit versus lending margins, the paper would benefit from exploiting clearer shocks to either lending or deposit opportunities. Ideally, one would like to observe shocks that increase or decrease lending opportunities without simultaneously affecting deposit margins, or vice versa.

> **PLAN TO ADDRESS COMMENT**
>
> - [ ] Bank-by-year fixed effects absorb much of the common variation between deposit and lending conditions at the bank level, so that identification comes from within-bank cross-branch variation where the link between demographics and lending demand is weaker. The deposit-β is constructed from interest expense responses to rate cycles, which is a financial behavior measure that is more directly tied to depositor sophistication than to local credit demand, and you can make that argument more explicitly in the revision.

### **5. Branch closure trends and the role of deposit beta**
My current reading of the paper is that deposit beta effectively serves as a sufficient statistic for branch closure decisions: conditional on a bank deciding to close branches within a given period, it is more likely to close those with higher betas. However, the paper does not sufficiently explain what drives the time-series trend in branch closures or how this trend interacts with deposit beta.

As the paper documents, the distribution of deposit betas does not increase over time, suggesting that changes in beta are not the primary driver of the observed rise in closures. While the authors argue that technological change plays a role, the paper does not provide direct evidence on how technology interacts with deposit beta. In particular, it is unclear why a high-beta branch would be more likely to close in, say, 2025 than in 2005.

More generally, the explanatory power of deposit beta in the closure regressions appears limited, with an R² close to 10% even after including extensive fixed effects, and likely much smaller without them. At the same time, the estimated economic magnitudes are very large: a relatively small increase in beta of 0.02 (i.e., a 2 basis point larger increase in deposit rates per 100 basis point increase in the market rate) translates into roughly a 10% increase relative to the mean closure rate and about a 25% increase relative to the mean opening rate. Given that branch-level beta variation itself is quite small (with a standard deviation around 0.02), it is unclear what accounts for such large estimated effects.

> **PLAN TO ADDRESS COMMENT**
> [...]

### **6. Branch-level betas: imputed measures versus RateWatch data**
The analysis relies on bank-level variation in interest expense on deposits, combined with local demographic characteristics, to construct branch-level betas. The authors argue against using actual branch-level deposit rate information from RateWatch due to limited coverage or uniform pricing across branches. Even if RateWatch is not well suited as a baseline measure, it would still be very valuable to include it as a robustness check.

Using RateWatch data where available would provide an important alternative source of variation and help assess whether the results are sensitive to the choice of beta construction. More broadly, the paper would be strengthened by validating the imputed deposit betas against realized betas constructed from RateWatch data where possible. Even if RateWatch is noisy or incomplete, showing that projected betas align with observed pricing behavior in overlapping samples would increase confidence in the beta measure and its economic interpretation.

> **PLAN TO ADDRESS COMMENT**
>
> - [ ] Scatter plot showing beta estimates align closely.

### **7. Other minor comments**
- **Standard errors:** Given that deposit beta is itself estimated in a first stage and then used as a regressor in the branch closure and opening regressions, the reported standard errors do not account for this generated-regressor problem. The standard errors should therefore be bootstrapped (or otherwise adjusted) to properly reflect the additional estimation uncertainty.

> **PLAN TO ADDRESS COMMENT**
>
> - [ ] I can implement a bank-level bootstrap. The idea would be to randomly draw banks with replacement, repeat the full two-step estimation on each resampled dataset, and build the distribution of the coefficient of interest across iterations. The standard deviation of that distribution gives us the bootstrapped standard error. This should be straightforward to implement for the baseline results and we can do 500–1000 iterations to make sure the estimates are stable.

## References
- Benmelech, E., Yang, J. and Zator, M. (2023). *Bank branch density and bank runs* (No. w31462). National Bureau of Economic Research.
- Drechsler, I., Savov, A. and Schnabl, P. (2017). “The deposits channel of monetary policy.” *The Quarterly Journal of Economics*, 132(4), 1819–1876.
- Drechsler, I., Savov, A. and Schnabl, P. (2021). “Banking on deposits: Maturity transformation without interest rate risk.” *The Journal of Finance*, 76(3), 1091–1143.
- Drechsler, I., Savov, A. and Schnabl, P. (2023). “Valuing the Deposit Franchise Value.”
- Jiang, E.X., Yu, G.Y. and Zhang, J. (2024). “Bank competition amid digital disruption: Implications for financial inclusion.” *The Journal of Finance*.




# Other To-Do
Show how visits to branches decline overtime