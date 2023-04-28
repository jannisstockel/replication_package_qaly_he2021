*===============================================================================
/*	
Prep: The Value of Health Paper - German SOEP: No Ind/Occ Information


Last Edited: 18.03.2021 20:57			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile prepares a robustness check which provides descriptives
			for individuals which get dropped due to missing industry occupation
			information (needed for IV), and a OLS regression which includes those
			individuals. If these are not dropped, the additional data conditioning
			steps need to be conducted similar to the base case (up to line 653).
		 
Input: 		SOEP_merged_raw.dta

Output: 	SOEP_merged_noindocc.dta
*/
*===============================================================================


*===============================================================================
* BEGIN PROGRAM
*===============================================================================

use 		"./Data_panel/SOEP_merged_raw.dta", replace 

* Before dropping some HH-members count 
sort hid syear
by hid syear: gen hhresp=_N

*===============================================================================
* Clean income 
*===============================================================================

* -1 and -3 values in hhnetto indicating not availble
drop if hhnetto <=0

*===============================================================================
* Clean Background Variables: Sex, Age, Disability, Marital and Labor Market Participation
*===============================================================================

* Sex + Imputation and cleaning out of contradictory responses 
sort 		pid syear

replace sex	=	0 	if	sex==-5 | sex==.
 
* Generating Value containing highest reported value for sex 
by pid: egen sex_max=max(sex)

* Dropping observation never stating sex information (all . or -5)
drop if sex_max==0
drop sex_max
replace sex=1.75 if sex==0

by pid: egen sex_min=min(sex)
by pid: egen sex_max=max(sex)

replace sex = 1 	if sex_min==1 		& sex_max==1.75 
replace sex = 2 	if sex_min==1.75	& sex_max==2 

drop if sex_min==1 & sex_max==2  // Drop individuals giving contradictory answers

drop sex_min sex_max

* Birthyear 
replace birthyear=0 	if birthyear<0 | birthyear==.

by pid: egen min_b=min(birthyear)
by pid: egen max_b=max(birthyear)

drop if max_b==0
replace birthyear=max_b if birthyear==0
drop min_b max_b 

by pid: egen min_b=min(birthyear)
by pid: egen max_b=max(birthyear)

gen diff = max_b - min_b 
drop if diff>2

by pid: egen mean_b=mean(birthyear)
replace mean_b=round(mean_b, 1)

replace birthyear=mean_b 

* Age 
gen age = syear - birthyear

* Disability status and level in percent
replace disabled=0 	if disabled<1 | disabled==.
by pid: egen max_d=max(disabled)

drop if max_d==0	
drop max_d 
replace disabled=1.75 if disabled==0

by pid: egen min_d=min(disabled)
by pid: egen max_d=max(disabled)
	
drop 	if disabled_percent==-3 | disabled_percent==-1 | disabled_percent==.

* General Self-Assessed Health, 5-Point-Scale at present
drop 	if health	<	0

* Life satisfaction
drop 	if lifesat<0 | lifesat==.

* Marital Status
drop 	if marstat<=0 | marstat==.

* Labor Force Status
drop 	if econact<=0 | econact==.

* Educational Attainment
replace 	pgpsbilo	=	-2 	if pgpsbilo==-5
replace 	pgpsbila	=	-2 	if pgpsbila==-5

foreach x of varlist pgpsbil* pgpbbil* {
	
	drop if `x'==-1 | `x'<-2 | `x'==.
	
} 

*===============================================================================
* Clean tenure and working hours
*===============================================================================
* Generate tenure

gen tenure = interview_date-jobsince
replace tenure = 0 if tenure <0
replace tenure = tenure/365 
recode tenure (.=0) if econact !=11 & econact !=12 // I am not sure whether this is ok to do, everyone who does not work gets a tenure of 0 and not missing

tab econact if tenure ==. //1402 observations with missing tenure who work

drop if tenure ==. & econact ==11 
drop if tenure ==. & econact ==12
drop if wrkhrs ==. & econact ==11 
drop if wrkhrs ==. & econact ==12 

*===============================================================================
* Clean Leisure Capacity Variables 
*===============================================================================

* Drop if workhours not stated but individual not outside of employment
drop 	if wrkhrs==-3 | wrkhrs==-1

drop	if hobby_hours<0

*===============================================================================
* Clean data for predicted labour market income
*===============================================================================

xtset pid syear

*-------------------------------------------------------------------------------
* Imputing industry occupation if not available but was available before/after
*-------------------------------------------------------------------------------

gen occupation2 = occupation

* Imputation previous year industry and occupation if job was not changed (newwork_lastyear)
replace occupation2 = L.occupation if occupation ==. & newwork_lastyear ==2

* Imputation of 2nd year if job not changed
replace occupation2 = L.occupation2 if occupation ==. & newwork_lastyear ==2

* Imputation of following year industry occupation if job was not changed
replace occupation2 = F.occupation2 if occupation ==. & F.newwork_lastyear ==2

gen industry2 = industry

* Imputation previous year industry and occupation if job was not changed (newwork_lastyear)
replace industry2 = L.industry if industry ==. & newwork_lastyear ==2 & L.industry !=.

* Imputation of 2nd year if job not changed
replace industry2 = L.industry2 if industry ==. & newwork_lastyear ==2 

* Imputation of following year industry occupation if job was not changed
replace industry2 = F.industry2 if industry ==. & F.newwork_lastyear ==2 


* Generate indicator flagging non available prediction variables
gen		labour_inc_no_pred =0
recode	labour_inc_no_pred (0=1) if (industry2 ==. | occupation2 ==. ) & net_labour_income !=-2 & net_labour_income !=0
tab 	labour_inc_no_pred

* Impute if job was changed but within same industry and occupation 
replace industry2 = L.industry2 if labour_inc_no_pred ==1 & L.industry == F.industry & L.occupation == F.occupation & newwork_lastyear ==2 & net_labour_income !=-2

replace 	occupation2 = L.occupation2 if labour_inc_no_pred ==1 & L.industry == F.industry & L.occupation == F.occupation & newwork_lastyear ==2 & net_labour_income !=-2

* Rename for industry occupation imputation robustness check
rename 	industry industry_wo_imputation
rename 	occupation occupation_wo_imputation

rename 	industry2 industry
rename 	occupation2 occupation

*-------------------------------------------------------------------------------
* Drop observations where predicting labour market incomes not possible
*-------------------------------------------------------------------------------

tab 	econact
tab 	labour_inc_no_pred

gen 	employed = 1 if econact == 11 | econact ==12
recode 	employed (.=0)

* Drop if individual state they are employed but do not report an income
drop 	if net_labour_income <=0 & employed ==1

* Drop if industry or occupation avaialable but not employed
drop 	if industry !=. & net_labour_income ==-2 & employed  ==0
drop 	if occupation !=. & net_labour_income ==-2 & employed  ==0

* Flag if industry or occupation missing althoug employed and positive income
tab 		labour_inc_no_pred

*===============================================================================
* Clean Health Questionnaire
*===============================================================================

di in red 	"Preparing Health Utility Imputation"

replace 	valid	=	0 	if valid!=1

gen  		impyear	=	syear*valid

by pid: 	replace impyear	= (impyear[_n-1] + impyear[_n+1])/2 if impyear==0

gen	 		imputable	=	(syear==impyear)		

keep if 	imputable	==	1

*===============================================================================
* Conditioning on spell >=3
*===============================================================================

* Identifying spells of consecutive runs
xtset pid syear

tsspell		, fcond(missing(L.syear))	// Creating variables identifying spells, observations within them and spell-ends 	

* Sorting according to individual 

sort 			pid _spell					// Sorting by ID and spell-identifier

by pid _spell: egen maxrun_spell	=	max(_seq) 	//	Cross-wave identifier of maximum spell length

keep if maxrun_spell>=3

*-------------------------------------------------------------------------------
* Imputing SF12 
*-------------------------------------------------------------------------------

replace	sf12ind_UK 	=	(sf12ind_UK[_n-1]+sf12ind_UK[_n+1])/2 	if sf12ind_UK==. & imputable==1

replace sf12ind_NL = (sf12ind_NL[_n-1]+sf12ind_NL[_n+1])/2 		if sf12ind_NL==. & imputable==1

*-------------------------------------------------------------------------------
* Imputing MCS and PCS 
*------------------------------------------------------------------------------- 
 
replace	mcs			=	(mcs[_n-1]+mcs[_n+1])/2				if	mcs==-8 & imputable==1 
	
replace	pcs			=	(pcs[_n-1]+pcs[_n+1])/2				if	pcs==-8 & imputable==1 
 
drop impyear imputable _spell _seq _end maxrun_spell


*===============================================================================
* Generate SES Dummies/Variables
*===============================================================================

di in red 	"Creating SES and Background Dummy Variables"

* Sex
gen	female 		=	 (sex==2)

* Disability Satus and Severity Levels
gen disability	=	(disabled==1)

replace disabled_percent=0 if disabled_percent==-2

gen disability_sev25 	= (disabled_percent>=0 & disabled_percent<=24)
gen disability_sev50 	= (disabled_percent>=25 & disabled_percent<=49)
gen disability_sev75 	= (disabled_percent>=50 & disabled_percent<=74)
gen disability_sev100	= (disabled_percent>=75 & disabled_percent<=100)

* Marital Status, de facto
gen married=(marstat==1 | marstat==6 | marstat==7)
gen div_sep_wid=(marstat==4 | marstat==5 | marstat==2 | marstat==8)
gen unmarried=(marstat==3)

* Labor Force Status
gen pensioner	=	(econact==2)
gen unemployed	=	(econact==6) 
gen student		= 	(econact==3)
gen no_lf		=	(econact==1 | econact==5 | econact==8 | econact==9 | econact==10 | econact ==4)

* Identify Self-Employed individuals
gen	self_employed = (empl_details>=410 & empl_details<=440)

* Highest Educational Attainment
gen edu_tertiary	=	(pgpbbil02>-2)
gen edu_secondary	=	(pgpbbil01>-2 & edu_tertiary==0)
gen edu_primary		=	(edu_secondary==0 & edu_tertiary==0)

replace edu_secondary	= 1 if edu_primary==1 & pgpbbil03>1 // Apprenticeship/Studying		
replace edu_primary		= 0 if pgpbbil03>1

* East and West Germany
gen east	=	(bula==4 | bula==8 | bula==13 | bula==14 | bula==16)
gen south 	= 	(bula==1 | bula==2 | bula==7 | bula==11)

* State and Year Dummies 
foreach x of numlist 2003/2018 {

	gen		y`x' = (syear==`x')
	
}	

foreach x of numlist 1/16 {
	
	gen		state`x' = (bula==`x')

}

*===============================================================================
* Household Equivalised Income Calculation
*===============================================================================
/* Household Equivalised Income is calculated on the basis of houshold disposable
income (hhnetto) and the household composition. According to the OECD methodology 
the following weights are applied to calculate adult equivalents in each HH;

Adult: 								1.0
Second adult and children >=14: 	0.5
Children <14:						0.3

The number of adult individual receiving a questionnaire invite is captured by 
hhresp which counts the number of individual obervations in each HH before cleaning
for incomplete information. 

The number of children of ages>=14 and <14 are calculated based on the wave-by-wave
data on household-level children and their ages as reported in the *kind.dta files.
*/

di in red 	"Calculating Equivalized Household Income in 2016 Prices"

* Step 1: Calculate Household Members with OECD Weights

gen			hhsize_equiv	= 	hhresp/2 + 0.5 + 0.3*oldt + 0.3*youngt // HH member weighted

* Step 3: Calculate Equivalized Household Income (unadjusted prices)
gen			hhnetto_equiv	=	hhnetto/hhsize_equiv

* Step 4: Use CPI Data to Calculate income in 2016 Prices

* Generate Cross-Wave Variable with CPI for 2016
egen		cpi_2018 		=	max(cpi)	// all incomes need to be adjusted for 2018 prices

gen			hhnetto_equivCPI=   ((hhnetto_equiv*cpi_2018)/cpi)/1000
gen			hhnetto_CPI		=	((hhnetto*cpi_2018)/cpi)/1000

replace 	net_labour_income = 0 if net_labour_income==-2
replace		net_labour_income = net_labour_income/1000

*===============================================================================
* Individual Leisure Capacity
*===============================================================================

/* L. Huang et al. (2018) report leisure capacity as the percentage of time not
spend in paid employment. Time spend in paid employment is calculated on several
measures; actual hours worked each week (wrkhrs), months in full- and parttime
employment (fulltime_/parttime_months). 

Further, questionnaires contained measures on hours of sleep on weekdays and week-
ends. Although not in every wave they allow for a rough measure of sleeping times
in the sample.  

Mean Sleeping Time Workday: 6.93
Mean Sleeping Time Weekend: 7.77

Not all individuals work fulltime. For nor the mean weekly sleeping time is calculated 
by 3.5*6.93 + 3.5*7.77 = 51.45  or 30.625% of all hours in a year (52*7*24=8736)
*/

di in red 		"Calculating Individual Leisure Capacity"

replace wrkhrs=0 if wrkhrs==-2

* Generate Annual Working Hours, assumption: Weekly Workhours representative for full year
gen wrkhrs_annual	=	12*4*wrkhrs

* Generate Annual Sleeping Time -> See comment above
gen	sleephrs_annual	=	12*4*51.45

* Cross-Wave: Hours in a Year
gen annual_hours	=	8736

* Generate Leisure Capacity (Rough Measure for Now), % of time for leisure available
gen leisure_cap		=	(annual_hours - sleephrs_annual - wrkhrs_annual)/annual_hours 

*===============================================================================
* Create Instrumental variable
*===============================================================================

* Instrument similar to Luechinger 2009, with reduced number of industry occupation cell based on classifaction used by Pischke.

*-------------------------------------------------------------------------------
* Predicting labour income
*-------------------------------------------------------------------------------

* Generate Instruments using Linear Income
reg		net_labour_income i.industry i.occupation i.syear i.bula if east == 1 & net_labour_income >0 
predict	pred_labourinc_east if east==1 & net_labour_income !=0

reg		net_labour_income i.industry i.occupation i.syear i.bula if east ==	0 & net_labour_income >0 
predict	pred_labourinc_west if east==0 & net_labour_income !=0

gen		pred_labourinc_lin	=	pred_labourinc_east	
replace	pred_labourinc_lin	=	pred_labourinc_west if east == 0

* Flag for individuals with predicted labour income
gen 	full_obs_empl = 0
recode	full_obs_empl (0=1) if pred_labourinc_lin !=.

* Generate Instruments using Log Income
gen		log_net_labour_income = log(net_labour_income)

* Generate Instruments using Log-Income 
reg		log_net_labour_income i.industry i.occupation i.syear i.bula if east == 1 & net_labour_income >0 
predict	pred_log_labourinc_east if east==1 & net_labour_income !=0

reg		log_net_labour_income i.industry i.occupation i.syear i.bula if east ==	0 & net_labour_income >0 
predict	pred_log_labourinc_west if east==0 & net_labour_income !=0

gen		pred_labourinc_log	=	pred_log_labourinc_east	
replace	pred_labourinc_log	=	pred_log_labourinc_west if east == 0

*-------------------------------------------------------------------------------
* Setting predicted labour income for individuals who do not work to 0 
*-------------------------------------------------------------------------------

foreach x of numlist 1/10 {

	replace pred_labourinc_lin  = 0 if econact ==`x'

}

*-------------------------------------------------------------------------------
* Summing predicted labour market income over household and equivalising over members
*-------------------------------------------------------------------------------

* Linear
sort hid syear 
by hid syear: egen 	hh_pred_labourinc_lin_sum	=	sum(pred_labourinc_lin)
gen					hh_pred_labourinc_lin		=	hh_pred_labourinc_lin_sum/hhsize_equiv

* Logarithmic Income
gen		pred_labourinc_logexp = exp(pred_labourinc_log) 
replace	pred_labourinc_logexp = 1/1000 		if econact>=1 & econact<=10
by hid syear: egen 	hh_pred_labourinc_log_sum	=	sum(pred_labourinc_logexp)
gen					hh_pred_labourinc_log		=	log(hh_pred_labourinc_log_sum/hhsize_equiv) 

*-------------------------------------------------------------------------------
* Creating lag of predicted income
*-------------------------------------------------------------------------------
sort pid syear 
by pid:		  gen  hh_pred_labourinc_lin_lag	=	hh_pred_labourinc_lin[_n-1] if syear==syear[_n-1]+1
by pid:		  gen  hh_pred_labourinc_log_lag	=	hh_pred_labourinc_log[_n-1] if syear==syear[_n-1]+1

*-------------------------------------------------------------------------------
* Generate flag for individuals in households with individual labour income, but 
* no way to predict labour income (missing industry, occupation), if we only drop 
* those individuals, household sum would also be wrong. Therefore drop all individuals
* in household. If we would not do this, the predicted labour incomes for those households 
* be underestimated. Hypothesis would be that therefore the CIV will be lower 
* household (higher importance of income), if these households are dropped. 
*-------------------------------------------------------------------------------

bys hid syear: egen problemh = max(labour_inc_no_pred)

* Household also have to be dropped if in their lag, one receives labour income, but predicting labour income was not possible
sort pid syear
gen problemh_lag = L.problemh

*drop if problemh ==1
*drop if problemh_lag ==1

*-------------------------------------------------------------------------------
* Generate industry occupation cell for clustering standard errors
*-------------------------------------------------------------------------------

egen 	ind_occ = group(industry occupation), label

gen  	ind_imp = industry
gen		occ_imp = occupation

*-------------------------------------------------------------------------------
* Replace Industry Occupation Cells for individuals not working
*-------------------------------------------------------------------------------
replace	ind_occ	= 472 	if ind_occ==. & econact == 2 // Aged 65+ and not working
replace	ind_occ	= 473 	if ind_occ==. & (econact == 3 | econact==5)  // Education/community service
replace ind_occ = 474   if ind_occ==. & econact == 4 // Maternity leave
replace	ind_occ = 475   if ind_occ==. & (econact == 8 | econact==9 | econact==10) // Unstable employment

replace	ind_occ = 998	if ind_occ==. & econact == 1 // Not in labour force 
replace	ind_occ	= 999	if ind_occ==. & econact == 6 // Unemployed

egen	ind_occ_year	= group(ind_occ syear)

*===============================================================================
* Conditioning on spell >=3, avoiding singleton observations in FE regressions
*===============================================================================

* Remove Observations not in SF12 triplet
gen		sf12wave	=	(syear==2002 | syear==2004 | syear==2006 | syear==2008 | ///
						 syear==2010 | syear==2012 | syear==2014 | syear==2016 | ///
						 syear==2018)

by pid:	gen		triplet = (sf12wave==1) | (sf12wave[_n-1]==1 & syear[_n-1]==syear-1 ///
						  & sf12wave[_n+1]==1 & syear[_n+1]==syear+1)						 
					
drop	if triplet==0
drop	triplet sf12wave
 
*===============================================================================
* Safe Dataset
*===============================================================================

keep pid syear disability* edu* sex married div_sep_wid unmarried pensioner unemployed 	///
	 employed student no_lf  mcs pcs age lifesat female east sf12ind_UK  ///
	 leisure_cap hhnetto_equivCPI valid interview_date  hobby_hours ///
	 occupation industry gross_labour_income net_labour_income bula east tenure jobsince ///
	 wrkhrs econact hid hhnetto* health south ///
	 hhsize_equiv mcs pcs newwork_lastyear labour_inc_no_pred hh_pred_labourinc_log_lag  hh_pred_labourinc_log ///
	 employed sf12ind_NL hh_pred_labourinc_lin hh_pred_labourinc_lin_lag hh_pred_labourinc_lin ///
	 ind_imp occ_imp full_obs_empl occupation_wo_imputation industry_wo_imputation ///
	 y* state* self_employed SFPhys SFRole ///
	 SFSocial SFPain SFMental SFVital problemh problemh_lag

*-------------------------------------------------------------------------------
* Generate Last Variables for FE-Regressions for the Imputed Dataset
*-------------------------------------------------------------------------------
	
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

* Generate lagged mcs and pcs variables
by	pid:	gen	mcs_lag		=	mcs[_n-1] 	if	syear == syear[_n-1] + 1
by 	pid:	gen pcs_lag		=	pcs[_n-1] 	if	syear == syear[_n-1] + 1

* Generate log income
gen log_hhnetto_equivCPI = log(hhnetto_equivCPI)
gen log_hhnetto_equivCPIlag = log(hhnetto_equivCPIlag)


*===============================================================================
* Generate information on outlier
*===============================================================================

global	covariates 	"disability age* married edu_primary edu_tertiary hobby_hours hobby_hours_sq unemployed wrkhrs  tenure"
global	mqaly_UK	"hhnetto_equivCPI* sf12ind_UK sf12ind_UKlag"
global	years		"y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 y2013 y2014 y2015 y2016 y2017 y2018"
global  states		"state1 state2 state3 state4 state5 state6 state7 state8 state9 state10 state11 state12 state13 state14 state15 state16"
	
* This procedure is not made for panel FE, Olafsdottir paper use it nevertheless
reg 	lifesat $mqaly_UK $covariates $years $states

* DFbeta as measure for outliers
predict dfit, dfits
dfbeta	hhnetto_equivCPI* sf12ind_UK sf12ind_UKlag
sum _dfbeta*

* Generate indicator for outlier in base case
xtreg 	lifesat $mqaly_UK $covariates $years $states, fe robust
gen in_sample = e(sample)

gen 	outlier_prep = 1 if (_dfbeta_1 > abs(1) | _dfbeta_2 > abs(1) | _dfbeta_3 > abs(1) |  _dfbeta_4 > abs(1)) & in_sample ==1

*-------------------------------------------------------------------------------
* Drop outlier
*-------------------------------------------------------------------------------

recode 	outlier_prep (.=0)
drop 	if outlier_prep ==1

*-------------------------------------------------------------------------------
* Drop if lagged income values not available 
*-------------------------------------------------------------------------------
drop  if   hhnetto_equivCPIlag ==. | hh_pred_labourinc_lin_lag ==.

* Label variables
label var	lifesat "Life satisfaction"
label var	hhnetto_equivCPI "Income in 1000's"
label var	sf12ind_UK "SF-6D utility"
label var	disability "Disability"
label var	age "Age"
label var	married "(de facto) Married"
label var	edu_primary "Primary education"
label var	edu_tertiary "Tertiary education"
label var	hobby_hours "Leisure time"
label var	unemployed "Unemployed"
label var	wrkhrs "Work hours"
label var   tenure "Tenure"
label var 	employed "Employed"


save "./Data_panel/SOEP_merged_noindocc.dta", replace

*===============================================================================
* END PROGRAM
*===============================================================================
