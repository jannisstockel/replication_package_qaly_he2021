*===============================================================================
/*	
Prep: The Value of Health Paper - German SOEP: No Imputation

Last Edit: 	18.03.2021 20:57
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)
			
Outline: 	This subdofile creates the dataset used in the baseline estimations.  
		 
Input: 		Dataset in storage as created by 04_00 preparation dofile. 

Output: 	Dataset without imputed SF12 values and adjusted lagged variables and 
			proper labelling for SF12 dimensions. 
			- SOEP_merged_finalNOIMPUTATION.dta
*/
*===============================================================================

*===============================================================================
* BEGIN PROGRAM
*===============================================================================

* Load in previously saved dataset to start from
use		"./Data_panel/SOEP_merged_IMPUTATION.dta", replace 

* Remove years without SF12 data
drop if valid==0

* Setting Dataset to time series
xtset pid syear
			
* Generate Lagged Income
gen 	hhnetto_equivCPIlag	=	hhnetto_equivCPI[_n-1]	if 	syear==syear[_n-1]+2

* Generate Lagged SF12-Index Value
gen		sf12ind_UKlag 		=	sf12ind_UK[_n-1]	if	syear==syear[_n-1]+2

* Generate Lagged SF12-Index Value dutch tariff
gen		sf12ind_NLlag 		=	sf12ind_NL[_n-1]	if	syear==syear[_n-1]+2

* Generate lagged mcs and pcs variables
by	pid:	gen	mcs_lag		=	mcs[_n-1] 	if	syear == syear[_n-1] + 2
by 	pid:	gen pcs_lag		=	pcs[_n-1] 	if	syear == syear[_n-1] + 2

* Generate SF6D sum score
gen 	SF6D_sum = (((-1)*((SFPhys + SFRole + SFSocial + SFPain + SFMental + SFVital)-27))*(100/21))/100

sum 	SF6D_sum
gen		SF6D_sum_lag = SF6D_sum[_n-1]	if	syear==syear[_n-1]+2

*-------------------------------------------------------------------------------
* Generate SF6D sum score Alternative: equally weight all dimensions, ranging from 1 to 5
*-------------------------------------------------------------------------------

recode  SFPhys (3=5)
recode  SFPhys (2=3)

recode  SFRole (4=5)
recode  SFRole (2=2.3333333)
recode  SFRole (3=3.6666667)

gen 	SF6D_sum_alt = (((-1)*((SFPhys + SFRole + SFSocial + SFPain + SFMental + SFVital)-30))*(100/24))/100

sum 	SF6D_sum_alt
gen		SF6D_sum_alt_lag = SF6D_sum_alt[_n-1]	if	syear==syear[_n-1]+2
	
* Age Squared	
gen 	age_sqr	= age^2

*leisure capacity as hours for hobby, and sq to correct for unemployed etc.
gen hobby_hours_sq = hobby_hours*hobby_hours

* Generate log income
gen log_hhnetto_equivCPI = log(hhnetto_equivCPI)
gen log_hhnetto_equivCPIlag = log(hhnetto_equivCPIlag)

*===============================================================================
* Conditioning on spell >=2, avoiding singleton observations in FE regressions
*===============================================================================

gen	sf12wave = . 

local	i=1

foreach x of numlist 2002 2004 2006 2008 2010 2012 2014 2016 2018 {
	
	replace	sf12wave = `i' if syear==`x'
	
	local	++i

}	

* Identify gaps to left and right 
by pid: gen leftgap  = syear - syear[_n-1] 
by pid: gen rightgap = syear[_n+1] - syear 

drop	if	leftgap>2 & rightgap>2 

xtset pid sf12wave

tsspell		, fcond(missing(L.sf12wave)) // Creating variables identifying spells, observations within them and spell-ends 	

* Sorting according to individual 
sort 			pid _spell		// Sorting by ID and spell-identifier

by pid _spell: egen maxrun_spell	=	max(_seq) // Cross-wave identifier of maximum spell length
keep if maxrun_spell>=2 // include only if two consecutive observations

drop	sf12wave

xtset pid syear

*===============================================================================
* Identify and remove outliers as in the main specification
*===============================================================================

global	covariates 	"disability age* married edu_primary edu_tertiary hobby_hours hobby_hours_sq unemployed wrkhrs  tenure"
global	mqaly_UK	"hhnetto_equivCPI* sf12ind_UK sf12ind_UKlag"

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

recode 	outlier_prep (.=0)
drop if outlier_prep ==1

*-------------------------------------------------------------------------------
* Drop if lagged income values not available 
*-------------------------------------------------------------------------------
drop  if   hhnetto_equivCPIlag ==. | hh_pred_labourinc_lin_lag ==.

*-------------------------------------------------------------------------------
* Attach variable labels for output tables 
*-------------------------------------------------------------------------------
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

label var	SF6D_sum_alt 		"SF-6D Summary Score"		
label var	SF6D_sum_alt_lag 	"SF-6D Summary Score $(t-1)$"		
	
local SF6D "SFPhys SFRole SFSocial SFPain SFMental SFVital"

foreach x of local SF6D {

    tab `x', gen(`x')
	
}

label var	SFPhys2 "Physical Function 2"
label var	SFPhys3 "Physical Function 3"
label var	SFRole2 "Role Function 2"
label var	SFRole3 "Role Function 3"
label var	SFRole4 "Role Function 4"
label var	SFSocial2 "Social Function 2"
label var	SFSocial3 "Social Function 3"
label var	SFSocial4 "Social Function 4"
label var	SFSocial5 "Social Function 5"
label var	SFPain2 "Pain 2"
label var	SFPain3 "Pain 3"
label var	SFPain4 "Pain 4"
label var	SFPain5 "Pain 5"
label var	SFMental2 "Mental Health 2"
label var	SFMental3 "Mental Health 3"
label var	SFMental4 "Mental Health 4"
label var	SFMental5 "Mental Health 5"
label var	SFVital2 "Vitality 2"
label var	SFVital3 "Vitality 3"
label var	SFVital4 "Vitality 4"
label var	SFVital5 "Vitality 5"

save "./Data_panel/SOEP_merged_finalNOIMPUTATION.dta", replace

*===============================================================================
* END PROGRAM
*===============================================================================
