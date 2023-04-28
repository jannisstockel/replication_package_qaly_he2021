*===============================================================================
/*	
Extract: The Value of Health Paper - German SOEP

Last Edit:	18.03.2021 20:32			
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)

Outline: 	This dofile extracts the variables of interest from the differen SOEP
			long-format datasets as released in v35.
		 
Input: 		Raw SOEP datasets cross-year and individual year;
			- pgen.dta, generated individual level variables
			- pl.dta, variables from individual questionnaires and occupational details
			- hgen.dta, generated household level variables
			- _kind.dta, information on children and household structure (2002-2018)
			- _p.dta, individual-level questionnaire results (2002-2018)
			
Output: 	Reduced SOEP datasets including identifiers and variables of interest 
			- pgen_ex.dta, extracted variables from pgen.dta
			- pl_ex.dta, extracted variables from pl.dta 
			- hgen_ex.dta, extracted variables from hgen.dta
			- kind_ex.dta, cross-year children data based on annual files 
			- sf12waves.dta, health questionnaire responses cross-waves
			- SOEP_final_utilities_UK.dta and SOEP_final_utilities_NL.dta
			  containing SF12 and health survey information for all years available. 
*/
*===============================================================================
clear 	all
version 16
capture log close
set 	more off

log using 	"./Output/01_00_SOEP_QALY_extract", text replace
*===============================================================================
* BEGIN PROGRAM
*===============================================================================

*===============================================================================
* Extract Variables: Marital Staturs, Economic Activity, Education, Working hours
*===============================================================================

* Load in SOEP file on generated individual-level variables
use 		"./Data_source/pgen.dta", replace 

di in red 	"Extract: Marital Status, Economic Activity & Education"

* Marital Status 
rename 		pgfamstd 	marstat

* Economic Activity 
rename 		pglfs 		econact

* Working hours (actual not contractual) per week
rename 		pgtatzeit   wrkhrs

* Labour income (gross) for instrument
rename 		pglabgro	gross_labour_income

* Labour income (net) for instrument
rename 		pglabnet	net_labour_income

* Employment Details 
rename		pgstib 		empl_details

* Keep only variables of interest
keep 		pid syear marstat econact wrkhrs pgpsbil* pgpbbil* *_labour_income empl_details

* Sort dataset before merge
sort 		pid syear

* Save data extract from SOEP
save 		"./Data_merge/pgen_ex.dta", replace

*===============================================================================
* Extract Variables: Income, disability, age, life satisfaction, smoking behaviour 
*===============================================================================

* Load dataset on individual-level survey responses
use 		"./Data_source/pl.dta", replace 

di in red 	"Extract: Disability, income, age & life satisfaction"

* Interview date variable
gen		intdaty	=	syear
rename	pmonin		intdatm
rename 	ptagin		intdatd	
gen 	interview_date=mdy(intdatm, intdatd, intdaty)
format 	interview_date %td

* Sex
rename 		pla0009_v2	sex

* Life/Health/Leisure Satisfaction
rename 		plh0182 	lifesat
rename 		plh0171		healthsat
rename 		plh0173		jobsat 
rename 		plh0174		hhoccsat
rename		plh0175		hhincsat
rename		plh0176		pincsat
rename		plh0177		accosat
rename		plh0178		leisuresat
rename		plh0179		childcaresat
rename		ple0008		health

* Age 
rename 		ple0010_h 	birthyear

* Disability
rename 		ple0040 	disabled 
rename 		ple0041 	disabled_percent

* Smoking behaviour and history 
rename 		ple0081_h 	smoker
rename 		ple0082		smokestrt_age
rename 		ple0084		smokeend_year
rename 		ple0085     smokeend_month
rename 		ple0086_v2  smoke_ncigs
rename 		ple0086_v3  smoke_npipes
rename 		ple0086_v4  smoke_ncigars    

* Sleeping hours workday and weekend
rename 		pli0059		sleephrs_wkday
rename		pli0060		sleephrs_wkend

* Reported Time Use on Regular Weekdays
rename		pli0038_h	employ_hours
rename		pli0040		errands_hours
rename		pli0043_h	hh_hours
rename 		pli0044_h	children_hours
rename		pli0047_v1	train_hours
rename 		pli0049_h	rep_hours
rename 		pli0051 	hobby_hours

* Indicator of reported changed job since last-year's participation
rename		plb0031_h	newwork_lastyear

* Variable on job tenure
gen day_jobstart = 1 // Start of job normalized to 1st day of month (avoid negatives)
gen jobsince= mdy(plb0035, day_jobstart, plb0036_h) if plb0035 >0 & plb0036_h >0		
format 	jobsince %td

* Sort dataset before merge (ID - Year panel structure)
sort 		pid syear

*===============================================================================
* Extract Variables: Industry, occupation
*===============================================================================

di in red 	"Extract: Industry, occupations"
*Summarising NACE industry codes according to Pischke (2011)
*Missing 25, 29, 31 intentional according to Pischke

gen industry =.
recode industry (.=1) if p_nace>=0 & p_nace <=5 	// Agriculture
recode industry (.=2) if p_nace >=10 & p_nace <=14  // Mining
recode industry (.=3) if p_nace ==45 				// Construction
recode industry (.=4) if p_nace ==20 | p_nace==36   // Wood
recode industry (.=5) if p_nace ==26 				// Stone/Glass
recode industry (.=6) if p_nace ==27 | p_nace==28 	// Metal
recode industry (.=7) if p_nace ==29 | p_nace==30 	// Non-electrical machinery
recode industry (.=8) if p_nace ==31 | p_nace==32	// Electronics
recode industry (.=9) if p_nace ==34 | p_nace==35	// Transportation equipment
recode industry (.=10) if p_nace ==33				// Professional equipment
recode industry (.=11) if p_nace ==15 | p_nace==16 	// Food/Tobacco 
recode industry (.=12) if p_nace >=17 & p_nace<=19 	// Clothing
recode industry (.=13) if p_nace ==21 				// Paper
recode industry (.=14) if p_nace ==22				// Printing
recode industry (.=15) if p_nace ==24				// Chemicals
recode industry (.=16) if p_nace ==23 | p_nace==25 	// Petroleum/Rubber
recode industry (.=17) if p_nace ==37				// Other manufacturing
recode industry (.=18) if p_nace>=60 & p_nace<=63	// Transportation
recode industry (.=19) if p_nace ==64				// Communication
recode industry (.=20) if p_nace==40 | p_nace==41 | p_nace==90 // Utilities
recode industry (.=21) if p_nace ==51				// Wholesale trade
recode industry (.=22) if p_nace==50 | p_nace==52	// Retail trade
recode industry (.=23) if p_nace>=65 & p_nace<=71	// Finance/Insurance
recode industry (.=24) if p_nace>=72 & p_nace<=74	// Business
recode industry (.=26) if p_nace>=95 & p_nace<=97	// Personal/repair
recode industry (.=27) if p_nace ==92				// Recreational 
recode industry (.=28) if p_nace ==85				// Health
recode industry (.=30) if p_nace ==80				// Education
recode industry (.=32) if p_nace==91 | p_nace==93	// Other
recode industry (.=33) if p_nace==75 | p_nace==99	// Public administration

*in Pischke missing "Gastgewerbe" = "Hospitality"
recode industry (.=34) if p_nace ==55				// Hospitality
						  
*-------------------------------------------------------------------------------
* Recode ISCO-08 to ISCO-88 for Wave 2018
*-------------------------------------------------------------------------------

* Uncomment to install iscogen command to transfer coding before running this
*ssc	install iscogen

iscogen	isco88 = isco88(p_isco08), from(isco08)

replace	p_isco88	=	p_isco08 	if p_isco08<0 & syear==2018
replace	p_isco88	=	isco88		if p_isco88 == -8	

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

*Summarising occupation codes according to Pischke(2011)
gen occupation =.

* Administrative and managerial occupations
recode occupation (.=1) if (p_isco88 >=1000 & p_isco88 <=1319) | (p_isco88 ==2400) | (p_isco88 >=2410 & p_isco88 <=2419) | (p_isco88 ==2470) | (p_isco88 >=3440 & p_isco88 <=3449)
* Engineers
recode occupation (.=2) if (p_isco88 >=2000 & p_isco88 <=2100) | (p_isco88 >=2140 & p_isco88 <=2149)
* Math and computer scientists
recode occupation (.=3) if (p_isco88 >=2120 & p_isco88 <=2139) 
* Natural Scientists
recode occupation (.=4) if (p_isco88 >=2110 & p_isco88 <=2114) | (p_isco88 >=2210 & p_isco88 <=2213) 
* Health professionals
recode occupation (.=5) if (p_isco88 ==2200) | (p_isco88 >=2220 & p_isco88 <=2222)
* Health treatment occupations
recode occupation (.=6) if (p_isco88 >=2223 & p_isco88 <=2230) | (p_isco88 >=3220 & p_isco88 <=3223) | (p_isco88 >=3230 & p_isco88 <=3232)
* Post-secondary teachers
recode occupation (.=7) if (p_isco88 ==2310)
* Other teachers
recode occupation (.=8) if (p_isco88 ==2300) | (p_isco88 >=2320 & p_isco88 <=2359)
* Counsellors, librarians, archivists
recode occupation (.=9) if (p_isco88 >=2430 & p_isco88 <=2432)
* Social scientists and urban planners
recode occupation (.=10) if (p_isco88 >=2440 & p_isco88 <=2445)
* Social and religious workers
recode occupation (.=11) if (p_isco88 ==2446) | (p_isco88 ==2460) | (p_isco88 ==3460) | (p_isco88 ==3480)
* Lawyers and judges
recode occupation (.=12) if (p_isco88 >=2420 & p_isco88 <=2429) 
* Writers, artists, athletes
recode occupation (.=13) if (p_isco88 >=2450 & p_isco88 <=2455) | (p_isco88 >=3470 & p_isco88 <=3478) 
* Technicians and support occupations
recode occupation (.=14) if (p_isco88 >=3000 & p_isco88 <=3213) | (p_isco88 >=3224 & p_isco88 <=3229) 
* Sales occupations
recode occupation (.=15) if (p_isco88 >=3400 & p_isco88 <=3429) | (p_isco88 ==5000) | (p_isco88 >=5200 & p_isco88 <=5220) 
* Clerical and administrative support occupations
recode occupation (.=16) if (p_isco88 >=3300 & p_isco88 <=3340) | (p_isco88 >=3430 & p_isco88 <=3434) | (p_isco88 >=4000 & p_isco88 <=4223)
* Private household workers
recode occupation (.=17) if (p_isco88 ==5121) | (p_isco88 ==5131) | (p_isco88 ==5133)
* Protective service workers
recode occupation (.=18) if (p_isco88 ==3450) | (p_isco88 >=5160 & p_isco88 <=5169)
* Service workers, exc 17 (private hh workers) and 18 (protective service)
recode occupation (.=19) if (p_isco88 ==5132) | (p_isco88 >=5100 & p_isco88 <=5120) | (p_isco88 >=5122 & p_isco88 <=5130) | (p_isco88 >=5139 & p_isco88 <=5149)
* Farming occupations
recode occupation (.=20) if (p_isco88 >=6000 & p_isco88 <=6154)
* Crafts and repair workers
recode occupation (.=21) if (p_isco88 >=7000 & p_isco88 <=7442)
* Operators and Laborers
recode occupation (.=22) if (p_isco88 >=8000 & p_isco88 <=9330)

* Keeping reduced variable set for further steps
keep 		pid hid syear disabled* birthyear sex smoke* sleephrs*	*_hours *sat ///
			jobsince health newwork_lastyear industry occupation interview_date plc0050 plc0051_v2
	
* Save data extract of individual-level survey responses
save 		"./Data_merge/pl_ex.dta", replace 

*===============================================================================
* Extract Variables: Household Characteristics - Income, composition, leisure
*===============================================================================

* Load generated data on household characteristics
use   		"./Data_source/hgen.dta", replace 

di in red 	"Extract Household Variables: Income and Composition"

* Generated Household Income
rename 		hghinc		hhnetto

* Generated Household Types
rename 		hgtyp1hh 	hhtype1
rename 		hgtyp2hh	hhtype2

* Bundesländer/States
rename 		hgnuts1		bula

sort 		hid syear

keep		hid syear hhnetto hhtype* bula

save        "./Data_merge/hgen_ex.dta", replace

*===============================================================================
* Number of Children in Household - Subdofile
*===============================================================================

do 			./01_01_SOEP_QALY_extract_children.do 

*===============================================================================
* SF12 Health Information - Subdofile 
*===============================================================================

do			./01_02_SOEP_QALY_extract_sf12survey.do

*===============================================================================
* END PROGRAM
*===============================================================================
capture log close

exit
