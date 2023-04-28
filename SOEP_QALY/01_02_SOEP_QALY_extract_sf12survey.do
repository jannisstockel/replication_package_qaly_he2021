*===============================================================================
/*	
Extract: The Value of Health Paper - German SOEP: SF-12 Questionnaires

Last Edit:	18.03.2021 20:32			
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)

Outline: 	This dofile extracts the variables of interest from the differen SOEP
			long-format datasets as released in v35 to calculate the SF-6D health
			utilities.
		 
Input: 		SOEP datasets of SF12 health questionnaires (separate by year) and the
			cross-year long-format health-related variables. 
			- health.dta, consistent items cross-year file 
			- sp.dta (2002) to bip.dta (2018), individual-level response by year
			
Output: 	Datasets with calculated SF-6D utilities following UK and NL Tariff 
			based scoring.
			- sf12waves.dta, health questionnaire responses cross-year 
			- SOEP_final_utilities_UK.dta and SOEP_final_utilities_NL.dta
*/
*===============================================================================

*===============================================================================
* BEGIN PROGRAMME
*===============================================================================

*===============================================================================
* Harmonize variable naming for different year-files
*===============================================================================

* Year 2002
use 		"./Data_source/sf12health/source/sp.dta", replace 

keep pid syear sp8907 sp8908 sp88 sp8902

rename sp8907 sf5	
rename sp8908 sf6
rename sp88   sf2
rename sp8902 sf11

save 		"./Data_source/sf12health/w2002.dta", replace 

* Year 2004
use 		"./Data_source/sf12health/source/up.dta", replace 
 
keep pid syear up8607 up8608 up85 up8602

rename up8607 sf5
rename up8608 sf6
rename up85   sf2
rename up8602 sf11

save 		"./Data_source/sf12health/w2004.dta", replace 

* Year 2006
use 		"./Data_source/sf12health/source/wp.dta", replace 
 
keep pid syear wp9007 wp9008 wp89 wp9002

rename wp9007 sf5
rename wp9008 sf6
rename wp89   sf2
rename wp9002 sf11

save 		"./Data_source/sf12health/w2006.dta", replace 

* Year 2008
use 		"./Data_source/sf12health/source/yp.dta", replace 
 
keep pid syear yp10207 yp10208 yp101 yp10202

rename yp10207 	sf5
rename yp10208 	sf6
rename yp101	sf2
rename yp10202 	sf11

save 		"./Data_source/sf12health/w2008.dta", replace 

* Year 2010
use 		"./Data_source/sf12health/source/bap.dta", replace 
 
keep pid syear bap9007 bap9008 bap89 bap9002

rename bap9007 	sf5
rename bap9008 	sf6
rename bap89	sf2
rename bap9002 	sf11
	
save 		"./Data_source/sf12health/w2010.dta", replace 

* Year 2012
use 		"./Data_source/sf12health/source/bcp.dta", replace 

keep pid syear bcp9407 bcp9408 bcp93 bcp9402

rename bcp9407 sf5
rename bcp9408 sf6
rename bcp93   sf2
rename bcp9402 sf11

save 		"./Data_source/sf12health/w2012.dta", replace 

* Year 2014
use 		"./Data_source/sf12health/source/bep.dta", replace 

keep pid syear bep9207 bep9208 bep91 bep9202

rename bep9207 	sf5
rename bep9208 	sf6
rename bep91	sf2
rename bep9202 	sf11

save 		"./Data_source/sf12health/w2014.dta", replace 

* Year 2016
use 		"./Data_source/sf12health/source/bgp.dta", replace 

keep pid syear bgp10807 bgp10808 bgp107 bgp10802

rename bgp10807  sf5
rename bgp10808  sf6
rename bgp107	 sf2
rename bgp10802  sf11

save 		"./Data_source/sf12health/w2016.dta", replace 

* Year 2018
use		"./Data_source/sf12health/source/bip.dta", replace

keep pid syear bip_137_07 bip_137_08 bip_137_02 bip_136

rename bip_137_07 sf5
rename bip_137_08 sf6
rename bip_136	  sf2
rename bip_137_02 sf11

* Append with information from 2002/4/6/8/10/12/14/16
foreach x of numlist 2002 2004 2006 2008 2010 2012 2014 2016 {

	append 	using 	"./Data_source/sf12health/w`x'"

} 

save		"./Data_source/sf12health/sf12waves.dta", replace 

*===============================================================================
* Combine complete SF12 Questionnaire Information and Calculate Tariffs
*===============================================================================

*-------------------------------------------------------------------------------
* Extract Variables: SF-12 Results & General Health Questionnaire
*-------------------------------------------------------------------------------

* Extract base variables from separate datasets
use 		"./Data_source/health.dta", replace

keep 	syear pid bp_nbs vt_nbs sf_nbs valid mcs pcs

rename		bp_nbs sf8
rename 		vt_nbs sf10		
rename 		sf_nbs sf12

* Merge with remaining sf12 questionnaire items 
merge 1:1 	pid syear using "./Data_source/sf12health/sf12waves.dta"
keep 		if _merge==3
drop 		_merge 

*-------------------------------------------------------------------------------
* Recoding of variables with numerical answers
*-------------------------------------------------------------------------------
replace	sf8 = 1 	if sf8<24 & sf8>23
replace sf8 = 2 	if sf8<33 & sf8>32
replace sf8 = 3 	if sf8<42 & sf8>41
replace sf8 = 4 	if sf8<51 & sf8>50
replace sf8 = 5 	if sf8<60 & sf8>59

replace	sf10 = 1 	if sf10<27 & sf10>26
replace sf10 = 2 	if sf10<38 & sf10>37
replace sf10 = 3 	if sf10<49 & sf10>48
replace sf10 = 4 	if sf10<60 & sf10>59
replace sf10 = 5 	if sf10<71 & sf10>70

replace	sf12 = 1 	if sf12<15 & sf12>14
replace sf12 = 2 	if sf12<26 & sf12>25
replace sf12 = 3 	if sf12<36 & sf12>35
replace sf12 = 4 	if sf12<47 & sf12>46
replace sf12 = 5 	if sf12<58 & sf12>57

*-------------------------------------------------------------------------------
* Preparing data 
*-------------------------------------------------------------------------------

gen sf22 =.
recode sf22 (.=1) if sf2 ==1
recode sf22 (.=2) if sf2 ==2
recode sf22 (.=3) if sf2 ==3

drop sf2
ren sf22 sf2

gen sf112 =.
recode sf112 (.=1) if sf11 ==1
recode sf112 (.=2) if sf11 ==2
recode sf112 (.=3) if sf11 ==3
recode sf112 (.=4) if sf11 ==4
recode sf112 (.=5) if sf11 ==5

drop sf11
ren sf112 sf11

gen sf52 =.
recode sf52 (.=1) if sf5 ==1
recode sf52 (.=2) if sf5 ==2
recode sf52 (.=3) if sf5 ==3
recode sf52 (.=4) if sf5 ==4
recode sf52 (.=5) if sf5 ==5

drop sf5
ren sf52 sf5

gen sf62 =.
recode sf62 (.=1) if sf6 ==1
recode sf62 (.=2) if sf6 ==2
recode sf62 (.=3) if sf6 ==3
recode sf62 (.=4) if sf6 ==4
recode sf62 (.=5) if sf6 ==5

drop sf6
ren sf62 sf6

label variable sf8 "bodily pain - 5 lowest"
label variable sf10 "vitality - 5 best"
label variable sf11 "mental health - 5 best"
label variable sf12 "social functioning - 5 best"
label variable sf5 "role limitations physical - 5 best"
label variable sf6 "role limitations emotional - 5 best"
label variable sf2 "physical functioning - 3 best"

*Physical functioning dimension*
*scsf2a

gen SFPhys = .
recode SFPhys (.=1) if sf2 ==3
recode SFPhys (.=2) if sf2 ==2
recode SFPhys (.=3) if sf2 ==1

*Role limitations dimension*

//health and mental
*scsf3b scsf4a
gen SFRole = .

recode SFRole (.=1) if sf5 ==5 & sf6 ==5
recode SFRole (.=2) if inrange(sf5, 1, 4) & sf6 ==5
recode SFRole (.=3) if inrange(sf6, 1, 4) & sf5 ==5
recode SFRole (.=4) if inrange(sf5, 1, 4) & inrange(sf6, 1, 4)

*Social functioning dimension*
gen SFSocial = .

recode SFSocial (.=1) if sf12 ==5
recode SFSocial (.=2) if sf12 ==4
recode SFSocial (.=3) if sf12 ==3
recode SFSocial (.=4) if sf12 ==2
recode SFSocial (.=5) if sf12 ==1

*Bodily pain dimension*
gen SFPain = .

recode SFPain (.=1) if sf8 ==5
recode SFPain (.=2) if sf8 ==4
recode SFPain (.=3) if sf8 ==3
recode SFPain (.=4) if sf8 ==2
recode SFPain (.=5) if sf8 ==1

*Mental health dimension*
gen SFMental = .

recode SFMental (.=1) if sf11 ==5
recode SFMental (.=2) if sf11 ==4
recode SFMental (.=3) if sf11 ==3
recode SFMental (.=4) if sf11 ==2
recode SFMental (.=5) if sf11 ==1


*Vitality dimension*
gen SFVital = .

recode SFVital (.=1) if sf10 ==5
recode SFVital (.=2) if sf10 ==4
recode SFVital (.=3) if sf10 ==3
recode SFVital (.=4) if sf10 ==2
recode SFVital (.=5) if sf10 ==1

*Most category
/*
gen most = .
recode most (.=1) if SFPhys ==3
recode most (.=1) if SFRole ==3 | SFRole ==4
recode most (.=1) if SFSocial ==4 | SFSocial ==5
recode most (.=1) if SFPain ==4 | SFPain ==5
recode most (.=1) if SFMental ==4 | SFMental ==5
recode most (.=1) if SFVital ==4 | SFVital ==5
*/

*===============================================================================
* Dutch tariff
*===============================================================================

preserve

*Weights from:
*Jonker, M. F., Donkers, B., de Bekker-Grob, E. W., & Stolk, E. A. (2018). 
*Advocating a Paradigm Shift in Health-State Valuations: The Estimation of 
*Time-Preference Corrected QALY Tariffs. Value in Health, 21(8), 993–1001. doi:10.1016/j.jval.2018.01.016
*Hyperbolic, table 3, column 4

gen pf1 = 0
recode pf1 (0=-0.05) if SFPhys ==2
recode pf1 (0=-0.21) if SFPhys ==3

gen rll = 0
recode rll (0=-0.09) if SFRole ==2
recode rll (0=-0.11) if SFRole ==3
recode rll (0=-0.19) if SFRole ==4

gen scl = 0
recode scl (0=-0.03) if SFSocial ==2
recode scl (0=-0.05) if SFSocial ==3
recode scl (0=-0.12) if SFSocial ==4
recode scl (0=-0.20) if SFSocial ==5

gen pnl = 0
recode pnl (0=-0.06) if SFPain ==2
recode pnl (0=-0.18) if SFPain ==3
recode pnl (0=-0.25) if SFPain ==4
recode pnl (0=-0.42) if SFPain ==5


gen mhl = 0
recode mhl (0=-0.06) if SFMental ==2
recode mhl (0=-0.11) if SFMental ==3
recode mhl (0=-0.25) if SFMental ==4
recode mhl (0=-0.39) if SFMental ==5

gen vl = 0
recode vl (0=-0.04) if SFVital ==2
recode vl (0=-0.08) if SFVital ==3
recode vl (0=-0.15) if SFVital ==4
recode vl (0=-0.21) if SFVital ==5


*gen mstl =0
*recode mstl (0=-0.077) if most ==1

//SF6D utility index
gen flag_missing =0
recode flag_missing (0=1) if sf8 <1
recode flag_missing (0=1) if sf10 <1
recode flag_missing (0=1) if sf12 <1
recode flag_missing (0=1) if sf2 <1
recode flag_missing (0=1) if sf11 <1
recode flag_missing (0=1) if sf5 <1
recode flag_missing (0=1) if sf6 <1

gen SF12ind =.
replace SF12ind = (1 + pf1 + rll + scl + pnl + mhl + vl) if flag_missing !=1

rename SF12ind sf12ind_NL
keep pid syear sf12ind_NL valid mcs pcs

save "./Data_source/SOEP_final_utilities_NL.dta", replace

restore

*===============================================================================
* UK tariff
*===============================================================================

*Most category
gen most = .
recode most (.=1) if SFPhys ==3
recode most (.=1) if SFRole ==3 | SFRole ==4
recode most (.=1) if SFSocial ==4 | SFSocial ==5
recode most (.=1) if SFPain ==4 | SFPain ==5
recode most (.=1) if SFMental ==4 | SFMental ==5
recode most (.=1) if SFVital ==4 | SFVital ==5

*Weighting of domain scores from Brazier JE, Roberts JR, (2004) The estimation of a preference-based index from the SF-12. Medical Care, 42: 851-859.*;

gen pf1 = 0
recode pf1 (0=-0.045) if SFPhys ==3

gen rll = 0
recode rll (0=-0.063) if inrange(SFRole, 2, 4)

gen scl = 0
recode scl (0=-0.063) if SFSocial ==2
recode scl (0=-0.066) if SFSocial ==3
recode scl (0=-0.081) if SFSocial ==4
recode scl (0=-0.093) if SFSocial ==5

gen pnl = 0
recode pnl (0=-0.042) if SFPain ==3
recode pnl (0=-0.077) if SFPain ==4
recode pnl (0=-0.137) if SFPain ==5

gen mhl = 0
recode mhl (0=-0.059) if SFMental ==2 | SFMental ==3
recode mhl (0=-0.113) if SFMental ==4
recode mhl (0=-0.134) if SFMental ==5

gen vl = 0
recode vl (0=-0.078) if inrange(SFVital, 2, 4)
recode vl (0=-0.106) if SFVital ==5

gen mstl =0
recode mstl (0=-0.077) if most ==1

//SF6D utility index
gen flag_missing =0
recode flag_missing (0=1) if sf8 <1
recode flag_missing (0=1) if sf10 <1
recode flag_missing (0=1) if sf12 <1
recode flag_missing (0=1) if sf2 <1
recode flag_missing (0=1) if sf11 <1
recode flag_missing (0=1) if sf5 <1
recode flag_missing (0=1) if sf6 <1

gen SF12ind =.
replace SF12ind = (1 + pf1 + rll + scl + pnl + mhl + vl+ mstl) if flag_missing !=1
rename SF12ind 	sf12ind_UK
keep pid syear  sf12ind_UK SFPhys SFRole SFSocial SFPain SFMental SFVital valid mcs pcs

save "./Data_source/SOEP_final_utilities_UK.dta", replace
*===============================================================================
* END PROGRAMME
*===============================================================================
