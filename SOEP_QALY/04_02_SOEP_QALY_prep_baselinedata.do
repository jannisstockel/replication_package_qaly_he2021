*===============================================================================
/*	
Prep: The Value of Health Paper - German SOEP: Baseline Data

Last Edit: 	18.03.2021 20:55
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)
			
Outline: 	This subdofile creates the dataset used in the baseline estimations.  
		 
Input: 		Dataset in storage as created by 04_00 preparation dofile. 

Output: 	Multiple datasets used in subsequent analyses with SF12 imputation
			- SOEP_merged_finalIMPUTATION_incloutlier.dta, including outliers 
			- SOEP_merged_finalIMPUTATION.dta, excluding outliers 
			- SOEP_merged_finalIMPUTATION_emplonly, employed only 
			- SOEP_merged_finalIMPUTATION_log, Log-income sample
*/
*===============================================================================

*===============================================================================
* BEGIN PROGRAM
*===============================================================================

*-------------------------------------------------------------------------------
* Generate Last Variables for FE-Regressions for the Imputed Dataset
*-------------------------------------------------------------------------------
preserve // necessary for unimputed dataset creation, see lines 441 for details
	
* Setting Dataset to time series
xtset pid syear
			
* Generate Lagged Income
gen 	hhnetto_equivCPIlag	=	hhnetto_equivCPI[_n-1]	if 	syear==syear[_n-1]+1

* Generate Lagged SF12-Index Value
gen		sf12ind_UKlag 			=	sf12ind_UK[_n-1]	if	syear==syear[_n-1]+1

* Generate Lagged SF12-Index Value dutch tariff
gen		sf12ind_NLlag 	=	sf12ind_NL[_n-1]	if	syear==syear[_n-1]+1

* Age Squared	
gen 	age_sqr	=	age^2

*leisure capacity as hours for hobby, and sq to correct for unemployed etc.
gen hobby_hours_sq = hobby_hours*hobby_hours

* Generate log income
gen log_hhnetto_equivCPI 	= log(hhnetto_equivCPI)
gen log_hhnetto_equivCPIlag = log(hhnetto_equivCPIlag)

*-------------------------------------------------------------------------------
* Attach Variable Labels 
*-------------------------------------------------------------------------------
label var	disability "Disability"
label var	age "Age"
label var	age_sqr "Age squared"
label var	married "(de facto) Married"
label var	edu_primary "Primary education"
label var	edu_tertiary "Tertiary education"
label var	hobby_hours "Leisure time"
label var	hobby_hours_sq "Leisure time squared"
label var	unemployed "Unemployed"
label var	wrkhrs "Work hours"
label var   tenure "Tenure"
label var 	employed "Employed"
label var	log_hhnetto_equivCPI "Log income"	
label var	lifesat "Life satisfaction"
label var	hhnetto_equivCPI "\\ Income in 1000's"
label var	hhnetto_equivCPIlag "Income in 1000's $(t-1)$"
label var	sf12ind_UK "SF-6D utility"
label var	sf12ind_UKlag "SF-6D utility $(t-1)$"	

* Save dataset including the income outliers
save "./Data_panel/SOEP_merged_finalIMPUTATION_incloutlier.dta", replace

*===============================================================================
* Generate information on outlier
*===============================================================================

* Globals with variable lists to generate income outlier flags
global	covariates 	"disability age* married edu_primary edu_tertiary hobby_hours hobby_hours_sq unemployed wrkhrs  tenure"
global	mqaly_UK	"hhnetto_equivCPI* sf12ind_UK sf12ind_UKlag"
global	years		"y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 y2013 y2014 y2015 y2016 y2017 y2018"
global  states		"state1 state2 state3 state4 state5 state6 state7 state8 state9 state10 state11 state12 state13 state14 state15 state16"
	
* Pooled regression to identify outliers
reg 	lifesat $mqaly_UK $covariates $years $states

* DFbeta as measure for outliers
predict dfit, dfits
dfbeta	hhnetto_equivCPI* sf12ind_UK sf12ind_UKlag
sum _dfbeta*

* Generate indicator for outliers
xtreg 	lifesat $mqaly_UK $covariates $years $states, fe robust
gen in_sample = e(sample)
gen 	outlier_prep = 1 if (_dfbeta_1 > abs(1) | _dfbeta_2 > abs(1) | _dfbeta_3 > abs(1) |  _dfbeta_4 > abs(1)) & in_sample ==1

*-------------------------------------------------------------------------------
* Drop outlier
*-------------------------------------------------------------------------------

recode 	outlier_prep (.=0)
drop 	if outlier_prep ==1

*-------------------------------------------------------------------------------
* Drop if income variables are not available
*-------------------------------------------------------------------------------

drop  if   hhnetto_equivCPIlag ==. | hh_pred_labourinc_lin_lag ==.

di in red "Data conditioning: Excluding observations wihtout lag: 186,902"

save "./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

*===============================================================================
* Create Log Sample 
*===============================================================================

* Drop individuals with for which log(pred_inc)==. 
drop	if	hh_pred_labourinc_lin == 0 | hh_pred_labourinc_lin_lag== 0

* Identifying spells of consecutive runs
xtset pid syear

tsspell		, fcond(missing(L.syear))	// Creating variables identifying spells, observations within them and spell-ends 	

* Sorting according to individual 
sort 			pid _spell	 // Sorting by ID and spell-identifier

by pid _spell: egen maxrun_spell	=	max(_seq) 	//	Cross-wave identifier of maximum spell length

keep if maxrun_spell>=2
drop	_seq _end _spell maxrun_spell


save "./Data_panel/SOEP_merged_finalIMPUTATION_log.dta", replace

*===============================================================================
* Create Sample excluding Self-Employed Only
*===============================================================================

* Identify households ever having self-employed individual
sort    hid syear   
by      hid syear: egen self_employed_HH = max(self_employed)
drop	if self_employed_HH==1 

* Set to time series for tsspell command
xtset pid syear

tsspell		, fcond(missing(L.syear))	// Creating variables identifying spells, observations within them and spell-ends 	

* Sorting according to individual 
sort 			pid _spell					// Sorting by ID and spell-identifier

by pid _spell: egen maxrun_spell	=	max(_seq) 	//	Cross-wave identifier of maximum spell length

keep if maxrun_spell>=2
drop	_seq _end _spell

save 	"./Data_panel/SOEP_merged_finalIMPUTATION_emplonly", replace 

* Dataset restored to state before lagged variables are created which are used in
* all specifications. In the unimputed dataset these need to be created separately
* to make sure that annually-lagged variables (imputed dataset) are not used when
* using the unimputed dataset (2-year frequency of observation).
restore 

save	"./Data_panel/SOEP_merged_IMPUTATION.dta", replace // Saved for later use

*===============================================================================
* END PROGRAM
*===============================================================================
