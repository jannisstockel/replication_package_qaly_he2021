*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Tariff Specifications

Last Edit:	18.03.2021 20:55			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta

Output: 	Results from tariff choice specification in Table 4. 
*/
*===============================================================================

*-------------------------------------------------------------------------------
* UK (Baseline) and Dutch Tariffs: OLS & IV Models 
*-------------------------------------------------------------------------------

* Load in Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

* Replace UK-Tariff with Dutch Tariff 
replace 	sf12ind_UK 		= sf12ind_NL 
replace		sf12ind_UKlag 	= sf12ind_NLlag

* Prepare data
xtset pid syear

* OLS with Dutch Tariff
xtreg	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix 	B1 	=	e(b)

scalar 	OLS_NL_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_NL = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_NL_sc*1000)]
estimate store OLS_NL	
estadd scalar Individuals = e(N_g)
estadd scalar CIV = OLS_NL_sc*1000

* IV with Dutch Tariff
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base = $instruments ) , fe robust first endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_NL_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_NL = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_NL_sc*1000)]
estimates store IV_NL
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_NL_sc*1000

