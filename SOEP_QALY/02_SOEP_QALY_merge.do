*===============================================================================
/*	
Merge: The Value of Health Paper - German SOEP

Last Edit: 	18.03.2021 20:32			
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)

Outline: 	This dofile merges the separated reduced long-format datasets into a 
			combined, raw dataset covering the waves of 1984-2018.
			
Input: 		Reduced SOEP datasets including extracted variables in long-format.
			- pl_ex.dta, extracted individual-level responses cross-year 
			- pgen_ex.dta, extracted generated variables for individuals, cross-year 
			- hgen_ex.dta, extracted generated variables for houesholds,cross-year
			- SOEP_final_utilities_UK and SOEP_final_utilities_NL, SF12 utilities
			  cross-year 

Output:  	Merged long-format raw SOEP data
			- SOEP_merged_raw.dta
*/
*===============================================================================
clear 	all
version 16
capture log close
set 	more off

log using 	"./Output/02_SOEP_QALY_merge", text replace
*===============================================================================
* BEGIN PROGRAM
*===============================================================================

* Load in individual level extracted variables
use 		"./Data_merge/pl_ex.dta", replace

*===============================================================================
* Step 1: Merge background variables from individual surveys
*===============================================================================

di in red 	"Merge background variables from individual responses"

merge 1:1 	pid syear using "./Data_merge/pgen_ex.dta"
keep 		if _merge==3
drop 		_merge 

*===============================================================================
* Step 2: Merge with household hevel hariables
*===============================================================================

di in red  "Merge with household-level variables"

* Generated Variables
merge m:1   hid syear using "./Data_merge/hgen_ex.dta"
keep 		if _merge==3
drop        _merge


*===============================================================================
* Step 3: Merge with Health variables on the individual level
*===============================================================================

di in red 	"Merge with health questionnaire responses"

merge 1:1 	pid syear using "./Data_source/sf12health/sf12waves.dta"
drop		_merge

*===============================================================================
* Step 4: Merge with Calculated HH-level number of children in age brackets 
*===============================================================================

di in red 	"Merge with HH-level number of children (calculated)"

merge m:1	hid syear using "./Data_merge/kind_ex.dta" 
drop 		if _merge==2	// Drop hh not found in master file (individual responses)
drop		_merge

* HH with no matched obervation from using 
replace 	oldt		=	0 if oldt		==.
replace 	youngt		=	0 if youngt		==.
replace		childrent	=	0 if childrent	==.

*===============================================================================
* Step 5: Merge with SF12 health utility values
*===============================================================================

di in red 	"Merge with calculated SF12 health index values"

//UK tariff calculated following Brazier 2004
merge 1:1	pid syear using "./Data_source/SOEP_final_utilities_UK.dta", keepusing(sf12ind_UK SFPhys SFRole SFSocial SFPain SFMental SFVital valid mcs pcs)
drop _merge

//Dutch tariff calculated following Jonkers 2018 
merge 1:1	pid syear using "./Data_source/SOEP_final_utilities_NL.dta", keepusing(sf12ind_NL)

*===============================================================================
* Remove observation before 2002
*===============================================================================

di in red 	"Remove Observations before 2002, no SF12-health questionnaire"

tab 		syear _merge
drop 		if syear<2002
drop		_merge

*===============================================================================
* Add 2002-2018 Annual CPI Data from German Statistics Office
*===============================================================================

di in red 	"Add Consumer Price Indices for 2002-2018, from German Stats Office"

merge m:1	syear using "./cpi_germanyDESTATIS_Feb2020.dta"
drop		_merge

save 		"./Data_panel/SOEP_merged_raw.dta", replace 

*===============================================================================
* END PROGRAM
*===============================================================================
capture log close

exit
