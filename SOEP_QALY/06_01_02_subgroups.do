*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Subgroups

Last Edit:	18.03.2021 20:55		
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta

Output: 	Results from subgroups specifications presented in Table 3 and Table 
			A2.1. 
*/
*===============================================================================

* Load Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

*===============================================================================
* Subgroup OLS & IV Models 
*===============================================================================

*-------------------------------------------------------------------------------
* OLS/IV Model separate for West and East Germany 
*-------------------------------------------------------------------------------

* OLS East

preserve

drop if east !=1
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg	lifesat	$mqaly_ols $covariates $years $states if east==1, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_east_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_east = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_east_sc*1000)]
estimate store OLS_UK_east
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_east_sc*1000

restore

* OLS West

preserve

drop if east ==1
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg	lifesat	$mqaly_ols $covariates $years $states if east==0, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_west_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_west = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_west_sc*1000)]
estimate store OLS_UK_west
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_west_sc*1000

restore

* IV East
xtivreg2 	lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments) ///
			if east==1 , fe first robust endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_east_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_east = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_east_sc*1000)]
estimates store IV_UK_east
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_east_sc*1000


* IV West 
xtivreg2 	lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments) ///
			if east==0 , fe first robust endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_west_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_west = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_west_sc*1000)]
estimates store IV_UK_west
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_west_sc*1000




*-------------------------------------------------------------------------------
* OLS/IV Models for Older (50+) and Younger (<50)
*-------------------------------------------------------------------------------			

* OLS for Younger 

preserve

drop if age >= 50
bys pid: gen singleton = (_N==1)
drop if singleton ==1


xtreg 	lifesat $mqaly_ols $covariates $years $states if age<50, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_young_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_young = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_young_sc*1000)]
estimate store OLS_UK_young
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_young_sc*1000

restore

* OLS for Older

preserve

drop if age <50
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg 	lifesat $mqaly_ols $covariates $years $states if age>=50, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_old_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_old = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_old_sc*1000)]
estimate store OLS_UK_old
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_old_sc*1000

restore

* IV for Younger
xtivreg2 	lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments) ///
			if age<50, fe first robust endog($endog_base)
			
matrix	B1	=	e(b)

scalar 	IV_UK_young_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_young = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_young_sc*1000)]
estimates store IV_UK_young
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_young_sc*1000

* IV for Older
xtivreg2 	lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments) ///
			if age>=50, fe first robust endog($endog_base)
			 
matrix	B1	=	e(b)

scalar 	IV_UK_old_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 		define IV_UK_old = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_old_sc*1000)]
estimates 	store IV_UK_old
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_old_sc*1000

*-------------------------------------------------------------------------------
* OLS/IV Models for Men and Women separately
*-------------------------------------------------------------------------------

* OLS Men only 

preserve

drop if sex !=1
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg 	lifesat $mqaly_ols $covariates $years $states if sex ==1, fe robust
	
matrix B1	=	e(b)

scalar 	OLS_UK_male_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_male = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_male_sc*1000)]
estimate store OLS_UK_male
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_male_sc*1000

restore

* OLS Women only 

preserve

drop if sex !=2
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg 	lifesat $mqaly_ols $covariates $years $states if sex ==2, fe robust
	
matrix B1	=	e(b)

scalar 	OLS_UK_female_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_female = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_female_sc*1000)]
estimate store OLS_UK_female
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_female_sc*1000

restore

* IV Men only 
xtivreg2 	lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments) ///
			if sex == 1, fe first robust endog($endog_base)
			
matrix	B1	=	e(b)

scalar 	IV_UK_male_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_male = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_male_sc*1000)]
estimates store IV_UK_male
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_male_sc*1000

* IV Women only 			
xtivreg2 	lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments) ///
			if sex == 2, fe first robust endog($endog_base)
			
matrix	B1	=	e(b)

scalar 	IV_UK_female_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_female = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_female_sc*1000)]
estimates store IV_UK_female
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_female_sc*1000

*-------------------------------------------------------------------------------
* OLS/IV Models for Different Time Periods 
*-------------------------------------------------------------------------------

* OLS without 2007-2009

preserve

drop if syear >=2007 & syear <=2009
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg 	lifesat $mqaly_ols $covariates $years $states if syear!=2007 & syear!=2008 & syear!=2009, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_nocrisis_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_nocrisis = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_nocrisis_sc*1000)]
estimate store OLS_UK_nocrisis
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_nocrisis_sc*1000

restore

* OLS of pre-crisis years < 2007

preserve

drop if syear >=2007
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg 	lifesat $mqaly_ols $covariates $years $states if syear<2007, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_precrisis_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_precrisis = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_precrisis_sc*1000)]
estimate store OLS_UK_precrisis
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_precrisis_sc*1000

restore

* OLS of post-crisis years > 2009

preserve

drop if syear <= 2009
bys pid: gen singleton = (_N==1)
drop if singleton ==1

xtreg 	lifesat $mqaly_ols $covariates $years $states if syear>2009, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_postcrisis_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_postcrisis = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_postcrisis_sc*1000)]
estimate store OLS_UK_postcrisis
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_postcrisis_sc*1000

restore

* IV Model without 2007 to 2009
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments )    /// 
			if syear!=2007 & syear!=2008 & syear!=2009, fe first robust endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_nocrisis_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_nocrisis = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_nocrisis_sc*1000)]
estimates store IV_UK_nocrisis
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_nocrisis_sc*1000

* IV Model of pre-crisis years 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if syear<2007, fe first robust endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_precrisis_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_precrisis = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_precrisis_sc*1000)]
estimates store IV_UK_precrisis
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_precrisis_sc*1000

* IV Model of post-crisis years 
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if syear>2009, fe first robust endog($endog_base)

matrix	B1	=	e(b)

scalar 	IV_UK_postcrisis_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_postcrisis = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_postcrisis_sc*1000)]
estimates store IV_UK_postcrisis
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_postcrisis_sc*1000

