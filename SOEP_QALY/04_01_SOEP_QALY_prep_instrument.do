*===============================================================================
/*	
Prep: The Value of Health Paper - German SOEP: Instrument Preparation

Last Edit: 	18.03.2021 20:55
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)
			
Outline: 	This subdofile creates the income-instrument used in the paper.  
		 
Input: 		Dataset in storage as created by 04_00 preparation dofile. 

Output: 	Graphs on instrumental variable estimation 
			- Figure A3.3: Income prediction by Industry
			- Figure A3.4: Income prediction by Occupation 
*/
*===============================================================================

*===============================================================================
* BEGIN PROGRAM
*===============================================================================

*-------------------------------------------------------------------------------
* Predicting labour income (linear income based, West and East Germany separate)
*-------------------------------------------------------------------------------

* Generating value labels for industry and occupation
label define industries 1 "Agriculture" 2 "Mining" 3 "Construction" 4 "Wood" 5 "Stone/Glass" /// 
			6 "Metal" 7 "Non-electrical machinery" 8 "Electronics" 9 "Transportation equipment" ///
			10 "Food/Tobacco" 11 "Professional equipment" 12 "Clothing" 13 "Paper" 14 "Printing" ///
			15 "Chemicals" 16 "Petroleum/Rubber" 17 "Other manufacturing" 18 "Transportation" ///
			19 "Telecommunication" 20 "Utilities" 21 "Wholesale trade" 22 "Retail trade" ///
			23 "Finance/Insurance" 24 "Business Services" 26 "Personal/repair services" ///
			27 "Recreational services" 28 "Healthcare" 30 "Education" 32 "Other" 33 "Public administration" ///
			34 "Hopsitality", add
		
label value industry industries		

label define occupations 1 "Managerial" 2 "Engineers" 3 "IT Professional" 4 "Natural Scientist" ///
			5 "Medical Professional" 6 "Caregiver/Nurse" 7 "Post-secondary teachers" 8 "Other teachers" ///
			9 "Counsellors/Librarians" 10 "Social scientists/Urban planners" 11 "Social/Religious workers" ///
			12 "Lawyers/Judges" 13 "Writers/Artists" 14 "Technicians/Supporting occupations" /// 
			15 "Sales occupations" 16 "Clerical/Administrative support" 17 "Private household workers" ///
			18 "Protective service workers" 19 "Other service workers" 20 "Farmers" ///
			21 "Crafts/Repair workers" 22 "Operators/Laborers"

label value occupation occupations

*-------------------------------------------------------------------------------
* Labour income regressions and predictions
*-------------------------------------------------------------------------------

* First running regressions and then predicting labour income
reg		net_labour_income i.industry i.occupation i.syear i.bula if east == 1 & net_labour_income >0 
predict	pred_labourinc_east if east==1 & net_labour_income !=0

estimate store labour_east

reg		net_labour_income i.industry i.occupation i.syear i.bula if east ==	0 & net_labour_income >0 
predict	pred_labourinc_west if east==0 & net_labour_income !=0

estimate store labour_west

*-------------------------------------------------------------------------------
* Create Appendix Figures A3.3/3.4: Income Prediction Industry/Occupation coefficients 
*-------------------------------------------------------------------------------

* Industry
coefplot labour_west labour_east,  sort baselevels  drop(*.occupation *.syear *.bula _cons) xline(0) label graphregion(col(white)) grid(none) legend(region(col(white)) col(1) ring(0) bplacement(east) size(vsmall) symxsize(6))

graph export "./Output/Graphs/figureA3_3.png", replace

* Occupation
coefplot labour_west labour_east, sort baselevels  drop(*.industry *.syear *.bula _cons) xline(0) label graphregion(col(white)) grid(none) legend(region(col(white)) col(1) ring(0) bplacement(east) size(vsmall) symxsize(6))

graph export "./Output/Graphs/figureA3_4.png", replace

*-------------------------------------------------------------------------------
* Combining predictions
*------------------------------------------------------------------------------

* Combine East and West
gen		pred_labourinc_lin	=	pred_labourinc_east
replace	pred_labourinc_lin	=	pred_labourinc_west if east == 0

*-------------------------------------------------------------------------------
* Generating prediction error
*------------------------------------------------------------------------------

gen pred_error_inc = pred_labourinc_lin-net_labour_income if pred_labourinc_lin !=.

hist pred_error_inc

twoway scatter industry pred_error_inc if pred_error_inc > -30, jitter(1.5) msymbol(point) xscale(range(-30 5) ) ylabel(1(1)33, valuelabel angle(horizontal) labsize(vsmall)) 


* Flag for individuals with predicted labour income
gen 	full_obs_empl = 0
recode	full_obs_empl (0=1) if pred_labourinc_lin !=.


*-------------------------------------------------------------------------------
* Generating log predicted income
*------------------------------------------------------------------------------

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

* Econact codings 1-10 are nonworking statuses
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
* those individuals, household sum would no longer be correct. Therefore we drop 
* all individuals in the household.
* If we would not do this, the predicted labour incomes for those households 
* be underestimated. Hypothesis would be that therefore the CIV will be lower 
* household (higher importance of income), if these households are dropped. 
*-------------------------------------------------------------------------------

bys hid syear: egen problemh = max(labour_inc_no_pred) // cross-wave flag

* Household also have to be dropped if in their lag, one receives labour income
* but predicting labour income was not possible
sort pid syear
gen problemh_lag = L.problemh

drop if problemh ==1
drop if problemh_lag ==1

*===============================================================================
* END PROGRAM
*===============================================================================
