*===============================================================================
/*	
Clean: The Value of Health Paper - German SOEP

Last Edit: 	18.03.2021 20:53
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)
			
Outline: 	This dofile cleans the raw data, removing all individuals with missing
			information on the variables of interest as described in detail in the
			paper.
		 
Input: 		Raw long-format SOEP data as created in previous steps. 
			- SOEP_merged_raw.dta

Output: 	Cleaned long-format SOEP data. 
			- SOEP_merged_clean.dta 
*/
*===============================================================================
clear 	all
version 15
capture log close
set 	more off

log using 	"./Output/03_SOEP_QALY_clean", text replace
*===============================================================================
* BEGIN PROGRAM
*===============================================================================

* Load in merged dataset of raw SOEP data extraction
use 		"./Data_panel/SOEP_merged_raw.dta", replace 

di in red "Data conditioning: Total number of individual-year observations: 434,002"

* Before dropping any household-members generate count variable for later weighting
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
replace sex=1.75 if sex==0 // value chosen, otherwise min-> missing

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
drop if diff>2 // Remove individuals with large reporting discrepancy

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
	
* Remove if missing disability percentage	
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

* Remove old variables for industry and occupation
drop 	industry occupation

rename 	industry2 industry
rename 	occupation2 occupation


di in red "Data conditioning: Clean control variables: 326,717"

*-------------------------------------------------------------------------------
* Drop observations where predicting labour market incomes not possible
*-------------------------------------------------------------------------------
gen 	employed = 1 if econact == 11 | econact ==12
recode 	employed (.=0)

* Drop if individual state they are employed but do not report an income
drop 	if net_labour_income <=0 & employed ==1

* Drop if industry or occupation avaialable but not employed
drop 	if industry !=. & net_labour_income ==-2 & employed  ==0
drop 	if occupation !=. & net_labour_income ==-2 & employed  ==0

* Drop if industry or occupation missing althoug employed and positive income
drop if		labour_inc_no_pred

di in red "Data conditioning: Remove working individuals without ind-occ information: 309,253"

*===============================================================================
* Clean Health Questionnaire
*===============================================================================

di in red 	"Preparing Health Utility Imputation"

replace 	valid	=	0 	if valid!=1 // Recode valid SF12 response indicator

gen  		impyear	=	syear*valid // Only years recorded if valid SF12 available

* If impyear = 0 (no SF12 available) impyear is replaced by the average of both 
* adjacent impyear values which are only the actual reporting year (syear) if and
* only if the observation has two adjacent consecutive observations. 
by pid: 	replace impyear	= (impyear[_n-1] + impyear[_n+1])/2 if impyear==0

gen	 		imputable	=	(syear==impyear)		
keep if 	imputable	==	1 // Remove observations with non-imputable SF12 value

di in red "Data conditioning: At least two consecutively observed self-reported SF12: 243,157"

*===============================================================================
* Conditioning on Observations Spells of at least 3 observations
*===============================================================================

* Identifying spells of consecutive runs
xtset pid syear

tsspell		, fcond(missing(L.syear)) // Creating variables identifying spells, observations within them and spell-ends 	

* Sorting according to individual 

sort 			pid _spell		// Sorting by ID and spell-identifier

by pid _spell: egen maxrun_spell	=	max(_seq) 	//	Cross-wave identifier of maximum spell length

keep if maxrun_spell>=3 // Keep only observations within spells of >=3 periods

di in red "Data conditioning: Remove observation not included in consecutive triplets: 220,358"

*-------------------------------------------------------------------------------
* Imputing SF12 
*-------------------------------------------------------------------------------

* Impute SF12 values by linear mean between two consecutive SF12 participations 
* (2 year difference)
replace	sf12ind_UK 	=	(sf12ind_UK[_n-1]+sf12ind_UK[_n+1])/2 	if sf12ind_UK==. & imputable==1
replace sf12ind_NL = (sf12ind_NL[_n-1]+sf12ind_NL[_n+1])/2 		if sf12ind_NL==. & imputable==1

*-------------------------------------------------------------------------------
* Imputing MCS and PCS for observations within triplet
*------------------------------------------------------------------------------- 
 
replace	mcs			=	(mcs[_n-1]+mcs[_n+1])/2				if	mcs==. & imputable==1 
replace	pcs			=	(pcs[_n-1]+pcs[_n+1])/2				if	pcs==. & imputable==1 
 
drop impyear imputable _spell _seq _end maxrun_spell

save "./Data_panel/SOEP_merged_clean.dta", replace

*===============================================================================
* END PROGRAM
*===============================================================================
capture log close

exit
