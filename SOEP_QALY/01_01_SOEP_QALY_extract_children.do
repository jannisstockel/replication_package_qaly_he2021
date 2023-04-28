*===============================================================================
/*	
Extract: The Value of Health Paper - German SOEP: Children information

Last Edit:	118.03.2021 20:33			
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)

Outline: 	This dofile extracts the variables of interest from the differen SOEP
			long-format datasets as released in v35 to construct the number of children 
			living in a given household. 
		 
Input: 		SOEP datasets of cohabiting children (separate by year).
			- skind.dta (2002) to bikind.dta (2018)
			
Output: 	Datasets with calculated children living in household for all waves
			between 2002 to 2018. 
			- kind_ex.dta 
*/
*===============================================================================

*===============================================================================
* BEGIN PROGRAM
*===============================================================================

*===============================================================================
* Harmonise Variable Naming for Waves BH and BI (2017/2018)
*===============================================================================

* Wave BH - 2017
use 	"./Data_source/Children/unharmonised/bhkind.dta", replace 

rename	bhk_78_03 bhkgjahr 

save	"./Data_source/Children/source/bhkind.dta", replace

* Wave BI - 2018
use 	"./Data_source/Children/unharmonised/bikind.dta", replace 

rename	bik_79_03 bikgjahr 

save	"./Data_source/Children/source/bikind.dta", replace

*===============================================================================
* Calculating Children Composition of Household
*===============================================================================

global waves2 "s t u v w x y z ba bb bc bd be bf bg bh bi"

foreach x of global waves2  {

	use 	"./Data_source/Children/source/`x'kind.dta", replace
		
	* Renaming Variables of Interest	
	rename	`x'kgjahr	birthyear

	* Generating Age and Indicators
	drop if 		birthyear<0
	gen 	age		=	syear - birthyear
	gen		young	=	(age<14)
	gen 	old		=	(age>=14)
	
	* Counting Children in certain age groups in each houeshold
	sort 	hid 
	
	by	 	hid:	egen	young_count	=	sum(young)	
	by		hid:	egen	youngt		=	max(young_count)
	
	by		hid:	egen	old_count	=	sum(old)
	by		hid:	egen	oldt		=	max(old_count)
	
	gen		childrent		=	oldt + youngt	
	
	by		hid:	keep if _n==1				// Collaps dataset to 1 per household
	
	* Reducing Dataset
	keep	hid syear oldt youngt childrent
	
	* Saving New Dataset	
	save 	"./Data_source/Children/`x'kind_harmonised.dta", replace

}

*===============================================================================
*	Merging Extraction of Children per Household into Long-Format File
*===============================================================================

use		"./Data_source/Children/skind_harmonised.dta", replace

global waves3	"t u v w x y z ba bb bc bd be bf bg bh bi"

foreach x of global waves3 {

	append using 	"./Data_source/Children/`x'kind_harmonised.dta"

}

save	"./Data_merge/kind_ex.dta", replace 

*===============================================================================
* END PROGRAM
*===============================================================================



