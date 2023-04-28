*===============================================================================
/*	
Prep: The Value of Health Paper - German SOEP 

Last Edit: 	18.03.2021 20:55
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)
			
Outline: 	This dofile prepares the cleaned data. It creates the different variables	
			used in the analysis and saves intermediate datasets
		 
Input: 		Cleaned long-format SOEP dataset 
			- SOEP_merged_clean.dta 

Output: 	Multiple final analysis datasets
			- 
*/
*===============================================================================
clear all
version 15
capture log close
set more off

log using "./Output/04_SOEP_QALY_prep", text replace

*===============================================================================
* BEGIN PROGRAM
*===============================================================================
use "./Data_panel/SOEP_merged_clean.dta", replace 

*===============================================================================
* Generate SES Dummies/Variables
*===============================================================================

di in red 	"Creating SES and Background Dummy Variables"

* Sex
gen	female 		=	 (sex==2)

* Disability status 
gen disability	=	(disabled==1)

* Marital status (de facto)
gen married=(marstat==1 | marstat==6 | marstat==7)
gen div_sep_wid=(marstat==4 | marstat==5 | marstat==2 | marstat==8)
gen unmarried=(marstat==3)

* Labor force status categories
gen pensioner	=	(econact==2)
gen unemployed	=	(econact==6) 
gen student		= 	(econact==3)
gen no_lf		=	(econact==1 | econact==5 | econact==8 | econact==9 | econact==10 | econact ==4)

* Identify self-employed individuals
gen	self_employed = (empl_details>=410 & empl_details<=440)

* Highest educational attainment categories
gen edu_tertiary	=	(pgpbbil02>-2)
gen edu_secondary	=	(pgpbbil01>-2 & edu_tertiary==0)
gen edu_primary		=	(edu_secondary==0 & edu_tertiary==0)

replace edu_secondary = 1 if edu_primary==1 & pgpbbil03>1 // Apprenticeship/studying		
replace edu_primary	  = 0 if pgpbbil03>1 

* East and west Germany regions for income prediction
gen east	=	(bula==4 | bula==8 | bula==13 | bula==14 | bula==16)
gen south 	= 	(bula==1 | bula==2 | bula==7 | bula==11)

* State and year Dummies 
foreach x of numlist 2003/2018 {

	gen		y`x' = (syear==`x')
	
}	

foreach x of numlist 1/16 {
	
	gen		state`x' = (bula==`x')

}

*===============================================================================
* Household equivalised income calculation
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

* Step 4: Use CPI Data to Calculate income in 2018 Prices

* Generate Cross-Wave Variable with CPI for 2018 (highest CPI)
egen		cpi_2018 		=	max(cpi) // To calculate CIVs in 2018 prices

* Generate HH-equivalent income CPI adjusted and in 1000€
gen			hhnetto_equivCPI=   ((hhnetto_equiv*cpi_2018)/cpi)/1000
gen			hhnetto_CPI		=	((hhnetto*cpi_2018)/cpi)/1000

* Replace labour incomes with 0 for non-working population
replace 	net_labour_income = 0 if net_labour_income==-2
replace		net_labour_income = net_labour_income/1000

*===============================================================================
* Individual Leisure Capacity
*===============================================================================
/* L. Huang et al. (2018) report leisure capacity as the percentage of time not
spend in paid employment. Time spend in paid employment is calculated on several
measures; actual hours worked each week (wrkhrs), months in full- and parttime
employment (fulltime_/parttime_months). 

Further, questionnaires contained measures on hours of sleep on weekdays (sleephours_wkday) 
and week-ends (sleephours_wkend). 

Although not in every wave it allows for a rough measure of sleeping times.  

Mean Sleeping Time Workday: 6.93 (sum sleephours_wkday if sleephours_wkday>=0)
Mean Sleeping Time Weekend: 7.77 (sum sleephours_wkend if sleephours_wkend>=0)

Not all individuals work fulltime. We calculate mean weekly sleeping time by 
3.5*6.93 + 3.5*7.77 = 51.45 or 30.625% of all hours in a year (52*7*24=8736)
*/

di in red 		"Calculating Individual Leisure Capacity"

replace wrkhrs=0 if wrkhrs==-2 // for non-working workhours=-2, now corrected

* Generate Annual Working Hours, assumption: Weekly Workhours representative for full year
gen wrkhrs_annual	=	12*4*wrkhrs

* Generate Annual Sleeping Time -> See comment above
gen	sleephrs_annual	=	12*4*51.45

* Cross-Wave: Hours in a Year
gen annual_hours	=	8736

* Generate Leisure Capacity (Rough Measure for Now), % of time for leisure available
gen leisure_cap		=	(annual_hours - sleephrs_annual - wrkhrs_annual)/annual_hours 

*===============================================================================
* Create Instrumental variable according to Luechinger (2009) and Pischke (2011)
*===============================================================================
run 	./04_01_SOEP_QALY_prep_instrument.do

*===============================================================================
* Conditioning on spell >=3, avoiding singleton observations in FE regressions
*===============================================================================

* Generate indicator for SF12 waves
gen		sf12wave	=	(syear==2002 | syear==2004 | syear==2006 | syear==2008 | ///
						 syear==2010 | syear==2012 | syear==2014 | syear==2016 | ///
						 syear==2018)

* Keep only observations with SF12 survey available or imputable						 
by pid:	gen		triplet = (sf12wave==1) | (sf12wave[_n-1]==1 & syear[_n-1]==syear-1 ///
						  & sf12wave[_n+1]==1 & syear[_n+1]==syear+1)						 
					
drop	if triplet==0
drop	triplet sf12wave

* Keep only relevant variables for the analysis
keep pid syear disability* edu* sex married div_sep_wid unmarried pensioner unemployed 	///
	 employed student no_lf mcs pcs age lifesat female east sf12ind_UK  ///
	 leisure_cap hhnetto_equivCPI valid interview_date hobby_hours ///
	 occupation industry gross_labour_income net_labour_income bula east tenure jobsince ///
	 wrkhrs econact hid hhnetto* health south hhsize_equiv mcs pcs newwork_lastyear  ///
	 labour_inc_no_pred hh_pred_labourinc_log_lag  hh_pred_labourinc_log ///
	 employed sf12ind_NL hh_pred_labourinc_lin hh_pred_labourinc_lin_lag hh_pred_labourinc_lin ///
	 full_obs_empl y* state* self_employed SFPhys SFRole SFSocial SFPain SFMental ///
	 SFVital plc0050 plc0051_v2   
	 
*-------------------------------------------------------------------------------
* Create baseline Data (with/without outliers) and subsamples 
*-------------------------------------------------------------------------------
run   	./04_02_SOEP_QALY_prep_baselinedata.do 

*-------------------------------------------------------------------------------
* Create health state data
*-------------------------------------------------------------------------------
run		./04_03_SOEP_QALY_prep_hstatedata.do 

*-------------------------------------------------------------------------------
* Create unimputed baseline dataset without income outliers
*-------------------------------------------------------------------------------
run		./04_04_SOEP_QALY_prep_noimputationdata.do

*-------------------------------------------------------------------------------
* Create dataset for individuals without information on industry and occupation
*-------------------------------------------------------------------------------
run		./04_05_SOEP_QALY_prep_noindoc.do


*===============================================================================
* END PROGRAM
*===============================================================================
capture log close

exit
