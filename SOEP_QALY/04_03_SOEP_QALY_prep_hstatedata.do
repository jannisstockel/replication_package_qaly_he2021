*===============================================================================
/*	
Prep: The Value of Health Paper - German SOEP: Health State Dependency

Last Edit: 	18.03.2021 20:55
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)
			
Outline: 	This subdofile creates the dataset used in the baseline estimations.  
		 
Input: 		Dataset in storage as created by 04_00 preparation dofile. 

Output: 	Multiple datasets used in subsequent analyses with SF12 imputation
			- SOEP_merged_finalIMPUTATION_hstate, health state dataset where all 
			  individuals are included but sample is identifiable using binary.
*/
*===============================================================================

*===============================================================================
* BEGIN PROGRAM
*===============================================================================

* Load Imputed Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

* Generate mean/min/max observed mental/physical component score variables
by 	pid:	egen mean_mcs = mean(mcs)
by  pid:    egen mean_pcs = mean(pcs)
by  pid:	egen max_mcs  = max(mcs)
by  pid:	egen min_mcs  = min(mcs)
by  pid:	egen max_pcs  = max(pcs)
by  pid:	egen min_pcs  = min(pcs)

* Generate variables encoding maximum difference between mean and min/max scores
gen upper_mcs	= max_mcs - mean_mcs
gen lower_mcs	= mean_mcs - min_mcs
gen upper_pcs	= max_pcs - mean_pcs
gen lower_pcs	= mean_pcs - min_pcs

* Binary encoding changes of at least 10 in total for mental or physical score
gen	score_change = (upper_mcs>=5 & lower_mcs>=5) | (upper_pcs>=5 & lower_pcs>=5) 

* Create indicator variable for the health state change sample 
gen hstate_sample = (score_change == 1)

* Indicator identifying observations with both scores below in-person mean
gen		bad_score = (mcs<mean_mcs & pcs<mean_pcs)

* Identify spells based on means (0=no bad score). For example
* if below mean score is only reported for mental/physical scores not both. 
by pid: egen		mean_bad_score = mean(bad_score)
replace	hstate_sample=0	 if mean_bad_score == 0

* Generate identifier for good and bad health states
gen		hstate_good  = bad_score==0 
gen		hstate_bad 	 = bad_score==1

* Identfy points where health states change
by pid:	gen switch		= (bad_score==1 & bad_score[_n-1]==0 & _n!=1) 

* Variable encoding number of switch points
by pid: gen	switch_sum	=  sum(switch)

* Individuals with eratic health changes removed from sample-identifier
replace hstate_sample=0	if switch_sum>1	

* Encode number of observation periods in good and bad health per individual
by pid: egen hstate_good_sum 	= sum(hstate_good) 
by pid:	egen hstate_bad_sum 	= sum(hstate_bad)

* Individuals with less then two observations in good and bad health removed from 
* sample identifier
replace	hstate_sample=0 	if	hstate_good_sum<2 | hstate_bad_sum<2

*-------------------------------------------------------------------------------
* Condition on continous observations in good health spells 
*-------------------------------------------------------------------------------
preserve

* Remove individuals outside of health state sample and in bad health
drop	if hstate_sample==0
drop	if hstate_bad==1 

* Set to time series for tsspell to work
xtset pid syear
tsspell		, fcond(missing(L.syear))	

* Sorting according to individual ids and observation spells
sort 			pid _spell					

* Generate variable encoding length of spell and condition on at least 2 consecutives
by pid _spell: egen maxrun_spell	=	max(_seq) 	
keep if maxrun_spell>=2
drop _spell _seq _end

* Generate temporary dataset to be combined with bad health states later
save	"./Temp_hstate_good", replace

restore

*-------------------------------------------------------------------------------
* Condition on continous observations in bad health spells 
*-------------------------------------------------------------------------------
preserve

* Remove individuals outside of health state sample and in good health 
drop	if hstate_sample==0
drop	if hstate_good==1 

* Set to time series for tsspell to work
xtset pid syear
tsspell		, fcond(missing(L.syear))	

* Sorting according to individual ids and observation spells
sort 			pid _spell					

* Generate variable encoding length of spell 
by pid _spell: egen maxrun_spell	=	max(_seq) 	
keep if maxrun_spell>=2
drop _spell _seq _end

* Merge with good health state observations
append using "./Temp_hstate_good.dta" 

* Sorty by indiviuals
sort pid syear

* Generate indicator, individual-level cross-wave: Any good/bad health state? 
by pid: egen	max_hstate_good = max(hstate_good)
by pid: egen	max_hstate_bad  = max(hstate_bad) 

* Remove if not both health states are observe
drop if (max_hstate_bad + max_hstate_good!=2)

*	Generate income flags cross-wave by health state
by pid: egen mean_inc_good 		= mean(hhnetto_equivCPI) if hstate_good==1
by pid: egen mean_inc_bad  		= mean(hhnetto_equivCPI) if hstate_bad==1
by pid: egen mean_inc_good_fl	= min(mean_inc_good)
by pid: egen mean_inc_bad_fl	= min(mean_inc_bad)

* Generate variable with income ratios between good and bad health states
gen		inc_ratio	= mean_inc_bad_fl/mean_inc_good_fl // same across observations

* Identify Individuals permanently out of work
gen		nworking = (econact==1 | econact==2 | econact==6)
by pid:	egen nworking_mean = mean(nworking)
drop 	nworking
gen		nworking = (nworking_mean==1) 

* Generate counter for individual-level number of observation 
by pid:	gen	obs_count = _n 

* For working only in sample: Summarize inc_ratios (to enforce one observation per 
* individual only when calculating mean/sd use only first observation)
sum		inc_ratio	if obs_count==1 & nworking==0
gen		hstate_incvar	=	(inc_ratio<(r(mean)-r(sd))) 

* Remove temporary health state data
erase	./Temp_hstate_good.dta 

* Generate cross-wave flag to identifyindividuals inside health state sample
by pid: egen	hstate_sample_fl 	= max(hstate_sample)
replace			hstate_sample		= hstate_sample_fl
drop			hstate_sample_fl

* Save temporary file 
save	"./Temp_hstate_sample.dta", replace 

restore // restore again to starting dataset for this dofile

* Remove individuals outside of the hstate sample based on score difference
drop	if	hstate_sample==1

* Add only those that were selected based on code above
append 	using	"./Temp_hstate_sample.dta" 
erase	./Temp_hstate_sample.dta

* Remove mean health variables to calculate new ones by health states
drop	mean_mcs mean_pcs min_mcs max_mcs min_pcs max_pcs

* Construct measure for within-health-state changes 
sort pid syear

by pid: 	egen mcs_good 	= mean(mcs) if hstate_good==1	& hstate_sample==1
by pid: 	egen mcs_bad 	= mean(mcs) if hstate_bad==1	& hstate_sample==1  
by pid: 	egen pcs_good 	= mean(pcs) if hstate_good==1	& hstate_sample==1
by pid: 	egen pcs_bad 	= mean(pcs) if hstate_bad==1	& hstate_sample==1 

local	scores "mcs pcs"

* Generate flagging variables to run separate regressions later
foreach x of local scores {

	by pid: egen `x'_good_fl = min(`x'_good)
	by pid: egen `x'_bad_fl = min(`x'_bad)
	
	drop	`x'_good `x'_bad

	rename	`x'_good_fl `x'_good
	rename	`x'_bad_fl `x'_bad
	
} 

* Generate within-person health state score changes
gen	mcs_change	=	mcs_good-mcs_bad
gen	pcs_change	=	pcs_good-pcs_bad

* Double check to remove individuals with health changes in only one dimension
replace hstate_sample=0 if (mcs_change<=0 & pcs_change>0) | (pcs_change<=0 & mcs_change>0)

* Identify subsample of severe health shocks of at least 5-points score changes
gen		hstate_severe	= 1 if hstate_sample==1 & (mcs_change>5 | pcs_change>5)
replace hstate_severe   = 0 if hstate_severe==.

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

* Save dataset
save 	"./Data_panel/SOEP_merged_finalIMPUTATION_hstate", replace

*===============================================================================
* END PROGRAM
*===============================================================================
