*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Health State Dependence

Last Edit:	18.03.2021 20:55			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta

Output: 	Results from health state dependence specifications in Table 5 and 
			Table 4.2 to 4.4.
*/
*===============================================================================

* Load Dataset
use		 "./Data_panel/SOEP_merged_finalIMPUTATION_hstate.dta", replace

* Drop Individuals not in the health state dependency sample
drop	if	hstate_sample==0

*-------------------------------------------------------------------------------
* Health State Dependence - All in Sample: OLS & IV Models 
*-------------------------------------------------------------------------------

* OLS - All 
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_hstate
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Good Health
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_good==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_good
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Bad Health
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_bad==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_bad
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* IV - All 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_hstate
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Good Health 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_good==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_good
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Bad Health 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_bad==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_bad
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

*-------------------------------------------------------------------------------
* Health State Dependence - Remove individuals with high income variance
*-------------------------------------------------------------------------------

* Drop individuals with strongly varying income 
drop if hstate_incvar==1

* OLS - All 
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_hstate_incvar
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Good Health 
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_good==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_good_incvar
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Bad Health
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_bad==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_bad_incvar
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* IV - All 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_hstate_incvar
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Good Health 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_good==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_good_incvar
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Bad Health
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_bad==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_bad_incvar
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

*-------------------------------------------------------------------------------
* Health State Dependence - Remove Non-Working individuals
*-------------------------------------------------------------------------------

* Remove additionall non-working individuals
drop if nworking==1

* OLS - All 
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_hstate_working
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Good Health 
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_good==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_good_working
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Bad Health
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_bad==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_bad_working
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* IV - All 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_hstate_working
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Good Health 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_good==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_good_working
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Bad Health
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_bad==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_bad_working
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

*-------------------------------------------------------------------------------
* Health State Dependence - Remove individuals without severe health shocks
*-------------------------------------------------------------------------------

* Keep only those with severe drop in health
drop if hstate_severe==0

* OLS - All 
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_hstate_severe
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Good Health 
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_good==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_good_severe
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* OLS - Bad Health
xtreg 	lifesat $mqaly_ols $covariates $years $states if hstate_bad==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK_bad_severe
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic

* IV - All 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_hstate_severe
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Good Health 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_good==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_good_severe
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

* IV - Bad Health
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if hstate_bad==1, fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK_bad_severe
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000

