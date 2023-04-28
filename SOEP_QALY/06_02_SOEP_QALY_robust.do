*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Robustness Checks

Last Edit:	18.03.2021 20:55		
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta
			- SOEP_merged_finalNOIMPUTATION.dta
			- SOEP_merged_finalIMPUTATION_emplonly.dta
			
Output: 	Results from the robustness check specifications presented in Table 7.
*/
*===============================================================================

*===============================================================================
* Only Working Population 
*===============================================================================

* Load Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION_log.dta", replace

*-------------------------------------------------------------------------------
* Regular OLS in Log Sample 
*-------------------------------------------------------------------------------
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_working_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_working = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_working_sc*1000)]
estimate store OLS_UK_working
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_working_sc*1000
estat ic 

*-------------------------------------------------------------------------------
* Regular IV in Log Sample 
*-------------------------------------------------------------------------------
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

matrix B1	=	e(b)

scalar 	IV_UK_working_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_working = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_working_sc*1000)]
estimate store IV_UK_working
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = IV_UK_working_sc*1000
estat ic 

*===============================================================================
* Only Working Population excluding Self-Employed Individuals
*===============================================================================

* Load Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION_emplonly.dta", replace

*-------------------------------------------------------------------------------
* Regular OLS in Log Sample 
*-------------------------------------------------------------------------------
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_employed_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_employed = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_employed_sc*1000)]
estimate store OLS_UK_employed
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_employed_sc*1000
estat ic 

*-------------------------------------------------------------------------------
* Regular IV in Log Sample 
*-------------------------------------------------------------------------------
xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

matrix B1	=	e(b)

scalar 	IV_UK_employed_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_employed = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_employed_sc*1000)]
estimate store IV_UK_employed
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = IV_UK_employed_sc*1000
estat ic 

*===============================================================================
*  Exclusion of individuals receiveing bonus payments
*===============================================================================

* Load Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

*-------------------------------------------------------------------------------
* Baseline OLS Model without individuals receiving bonuses
*-------------------------------------------------------------------------------

preserve

drop if plc0050 != -2
bys pid: gen singleton = (_N==1)
drop if singleton ==1


xtreg 	lifesat $mqaly_ols $covariates $years $states if plc0050 == -2, fe robust

matrix B1	=	e(b)

scalar 	OLS_wo_bonus_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_wo_bonus = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_wo_bonus_sc*1000)]
estimate store OLS_wo_bonus
estadd scalar Individuals = e(N_clust)

estadd scalar CIV = OLS_wo_bonus_sc* 1000
estat ic 
 
restore
 
*-------------------------------------------------------------------------------
* Baseline Model without individuals receiving bonuses - IV
*-------------------------------------------------------------------------------

xtivreg2 lifesat $mqaly_iv $covariates_iv $years $states ($endog_base =  $instruments ) if plc0050 == -2, fe first endog($endog_base) robust

matrix	B1	=	e(b)

scalar 	IV_wo_bonus_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_wo_bonus = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_wo_bonus_sc*1000)]
estimates store IV_wo_bonus
estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_wo_bonus_sc*1000

*===============================================================================
* SF6D sum score
*===============================================================================

* Load Dataset
use		"./Data_panel/SOEP_merged_finalNOIMPUTATION.dta", replace

bys pid: gen singleton = (_N==1)
drop if singleton ==1

* Sum score with artifically equal range of levels (1 to 5). Using range of 
* 3 and 4 for the first two dimensions would already impose a weighting. 
* Therefore rescaled the first two dimensions to 1 to 5 range.

* Alternative, sum score ranging from 0.345 to 1 instead of 0 to 1
gen SF6D_sum_r = (SF6D_sum_alt*(0.655/1))+0.345
gen SF6D_sum_r_lag = (SF6D_sum_alt_lag*(0.655/1))+0.345

*-------------------------------------------------------------------------------
* OLS
*-------------------------------------------------------------------------------

xtreg 	lifesat hhnetto_equivCPI* SF6D_sum_alt SF6D_sum_alt_lag $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_sum_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_sum = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_sum_sc*1000)]
estimate store OLS_sum
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_sum_sc*1000
estat ic 

*-------------------------------------------------------------------------------
* IV
*-------------------------------------------------------------------------------

xtivreg2 	lifesat SF6D_sum_alt SF6D_sum_alt_lag $covariates_iv $years $states ($endog_base = $instruments) ///
			, fe robust first endog($endog_base)

matrix B1	=	e(b)

scalar 	IV_sum_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_sum = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_sum_sc*1000)]
estimate store IV_sum

estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_sum_sc*1000

*===============================================================================
* Regressing on SF6D Items
*===============================================================================

* Load Dataset
use		"./Data_panel/SOEP_merged_finalNOIMPUTATION.dta", replace

bys pid: gen singleton = (_N==1)
drop if singleton ==1

*-------------------------------------------------------------------------------
* OLS
*-------------------------------------------------------------------------------
/*
local SF6D "SFPhys SFRole SFSocial SFPain SFMental SFVital"

foreach x of local SF6D {

    tab `x', gen(`x')
	
}
*/
local SF6D_dim "SFPhys2 SFPhys3 SFRole2 SFRole3 SFRole4 SFSocial2 SFSocial3 SFSocial4 SFSocial5 SFPain2 SFPain3 SFPain4 SFPain5 SFMental2 SFMental3 SFMental4 SFMental5 SFVital2 SFVital3 SFVital4 SFVital5"

xtreg 	lifesat hhnetto_equivCPI* `SF6D_dim' $covariates $years $states, fe robust

estimate store OLS_sfdim

matrix B1	=	e(b)
scalar 	CIV_ph	=	(B1[1,4])/(B1[1,1] + B1[1,2])
scalar 	CIV_rl	=	(B1[1,7])/(B1[1,1] + B1[1,2])
scalar 	CIV_soc	=	(B1[1,11])/(B1[1,1] + B1[1,2])
scalar 	CIV_pain	=	(B1[1,15])/(B1[1,1] + B1[1,2])
scalar 	CIV_mental	=	(B1[1,19])/(B1[1,1] + B1[1,2])
scalar 	CIV_vital	=	(B1[1,23])/(B1[1,1] + B1[1,2])

scalar CIV_QALY_dim = CIV_ph+CIV_rl+ CIV_soc + CIV_pain +CIV_mental +CIV_vital
di CIV_ph CIV_rl CIV_soc CIV_pain CIV_mental CIV_vital CIV_QALY_dim

estadd scalar Individuals = e(N_clust)

estadd scalar CIV = CIV_QALY_dim*1000*-1

estadd scalar CIV_ph = CIV_ph*1000*-1
estadd scalar CIV_rl = CIV_rl*1000*-1
estadd scalar CIV_soc = CIV_soc*1000*-1
estadd scalar CIV_pain = CIV_pain*1000*-1
estadd scalar CIV_mental = CIV_mental*1000*-1
estadd scalar CIV_vital = CIV_vital*1000*-1

*-------------------------------------------------------------------------------
* IV 
*-------------------------------------------------------------------------------

xtivreg2 lifesat `SF6D_dim' $covariates_iv $years $states ($endog_base =  $instruments ), fe first endog($endog_base)

estimate store IV_sfdim

matrix B1	=	e(b)
scalar 	CIV_ph_IV	=	(B1[1,4])/(B1[1,1] + B1[1,2])
scalar 	CIV_rl_IV	=	(B1[1,7])/(B1[1,1] + B1[1,2])
scalar 	CIV_soc_IV	=	(B1[1,11])/(B1[1,1] + B1[1,2])
scalar 	CIV_pain_IV	=	(B1[1,15])/(B1[1,1] + B1[1,2])
scalar 	CIV_mental_IV	=	(B1[1,19])/(B1[1,1] + B1[1,2])
scalar 	CIV_vital_IV	=	(B1[1,23])/(B1[1,1] + B1[1,2])

scalar CIV_QALY_dim_IV = CIV_ph_IV+CIV_rl_IV+ CIV_soc_IV + CIV_pain_IV +CIV_mental_IV +CIV_vital_IV
di CIV_ph_IV CIV_rl_IV CIV_soc_IV CIV_pain_IV CIV_mental_IV CIV_vital_IV CIV_QALY_dim_IV

estadd scalar Individuals = e(N_clust)

estadd scalar CIV = CIV_QALY_dim_IV*1000*-1

estadd scalar CIV_ph = CIV_ph_IV*1000*-1
estadd scalar CIV_rl = CIV_rl_IV*1000*-1
estadd scalar CIV_soc = CIV_soc_IV*1000*-1
estadd scalar CIV_pain = CIV_pain_IV*1000*-1
estadd scalar CIV_mental = CIV_mental_IV*1000*-1
estadd scalar CIV_vital = CIV_vital_IV*1000*-1


*===============================================================================
* OLS results for individuals without information on industry and occupation
*===============================================================================


* Load Dataset
use "./Data_panel/SOEP_merged_noindocc.dta", replace


*===============================================================================
* Run model with and wihtout individuals without industry/occupation
*===============================================================================


xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)

scalar 	OLS_UK_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_w_IV_info = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_sc*1000)]
estimates store OLS_UK_w_IV_info
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_sc*1000
estat ic 




