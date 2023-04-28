*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Baseline

Last Edit:	18.03.2021 20:55			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta
			- SOEP_merged_finalNOIMPUTATION.dta

Output: 	Results from baseline specifications presented in Table 2. 
*/
*===============================================================================

* Load Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

*===============================================================================
* Baseline OLS & IV Model using Imputed & Unimputed Data
*===============================================================================

*-------------------------------------------------------------------------------
* Hausmann Test for Fixed Effects vs. Random Effects Model
*-------------------------------------------------------------------------------

* Hausmann Test with UK Tariffs
xtreg	lifesat $mqaly_ols $covariates $years $states, fe 
eststo 	fixed

xtreg	lifesat $mqaly_ols $covariates $years $states, re 
eststo 	random

hausman fixed ., sigmamore // Systematic difference in coefficients-> FE necessary

*-------------------------------------------------------------------------------
* Baseline OLS/IV Model with Imputed Data 
*-------------------------------------------------------------------------------

* OLS Model 
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust
gen in_OLS_sample = e(sample)

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimate store OLS_UK
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 

* IV Model 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

gen in_IV_sample = e(sample)
matrix	B1	=	e(b)

scalar 	IV_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_sc*1000)]
estimates store IV_UK
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_sc*1000


* Save first stage results
eststo: xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base) savefirst savefprefix(st1)

*-------------------------------------------------------------------------------
* Baseline OLS/IV Model with Unimputed Data 
*-------------------------------------------------------------------------------

* Load Dataset
use		"./Data_panel/SOEP_merged_finalNOIMPUTATION.dta", replace

*bys pid: gen singleton = (_N==1)
*drop if singleton ==1

* OLS Model
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_noimp_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_noimp = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_noimp_sc*1000)]
estimate store OLS_UK_noimp
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_noimp_sc*1000
estat ic 

* IV Model 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_noimp_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_noimp_sc*1000)]
estimates store IV_UK_noimp
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_noimp_sc*1000


