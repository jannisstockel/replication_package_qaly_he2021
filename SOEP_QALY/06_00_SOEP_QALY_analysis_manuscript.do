*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP 

Last Edit:	18.03.2021 20:55			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta
			- SOEP_merged_finalNOIMPUTATION.dta
			- SOEP_merged_finalIMPUTATION_incloutlier.dta
			- SOEP_merged_finalIMPUTATION_hstate
			- SOEP_merged_finalIMPUTATION_emplonly.dta
			
Output: 	Output Graphs and Tables in the order of creation
			- Table 1
			- Table A1.2
			- Table A4.1
			- Table 2
			- Table A3.1 
			- Figure A3.5-3.7
			- Table 3 
			- Table A2.1 
			- Figure 1
			- Table 4 
			- Table 5 
			- Table 6 
			- Table 4.2-4.4 
			- Table 7 
			- Table A2.2 
			- Figure 3
*/
*===============================================================================

clear all
version 16
capture log close
set more off, permanently

log using "./Output/06_SOEP_QALY_analysis_manuscript", text replace

*===============================================================================
* BEGIN PROGRAM
*===============================================================================

*-------------------------------------------------------------------------------
* Create Globals containing variables used in the analyses
*-------------------------------------------------------------------------------

* Global containing covariates used across OLS regressions
global	covariates 		"disability age* married edu_primary edu_tertiary hobby_hours hobby_hours_sq unemployed wrkhrs tenure"

* Global containing the three important controls; income, sf12 and disability (UK & Dutch)
global	mqaly_ols		"hhnetto_equivCPI* sf12ind_UK sf12ind_UKlag"
global	mqaly_iv		"sf12ind_UK sf12ind_UKlag"
global  mqaly_ols_log	"sf12ind_UK sf12ind_UKlag"

* Globals containing variables for the IV estimations
global	covariates_iv	"disability age* married edu_primary edu_tertiary hobby_hours hobby_hours_sq unemployed wrkhrs tenure"
global	endog_base		"hhnetto_equivCPI hhnetto_equivCPIlag"
global	endog_log		"log_hhnetto_equivCPI log_hhnetto_equivCPIlag"
global 	instruments 	"hh_pred_labourinc_lin hh_pred_labourinc_lin_lag"
global	instruments_log	"hh_pred_labourinc_log hh_pred_labourinc_log_lag"

* Globals containing year dummies and 
global	years			"y2003 y2004 y2005 y2006 y2007 y2008 y2009 y2010 y2011 y2012 y2013 y2014 y2015 y2016 y2017 y2018"
global  states			"state1 state2 state3 state4 state5 state6 state7 state8 state9 state10 state11 state12 state13 state14 state15 state16"


*===============================================================================
* Results Dofiles
*===============================================================================

*-------------------------------------------------------------------------------
* Table 1: Descriptive Statistics
*-------------------------------------------------------------------------------

* Load Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

* Adjust labels for Table 1
label var	hhnetto_equivCPI "Income in 1000's"
label var	edu_secondary "Secondary education"

* Create Table 1
cd 			"./Output/Tables" // Temporary change directory to save table

* Copy lines for values into descstat_OLS_IV.tex	
sutex lifesat hhnetto_equivCPI sf12ind_UK ///
			disability age married edu_primary edu_secondary  ///
			edu_tertiary hobby_hours employed unemployed wrkhrs tenure if hhnetto_equivCPIlag !=., digits(2) label  key(descstat) replace  ///
			file(table1.tex)  
cd 			"../../"			


*-------------------------------------------------------------------------------
* Table A1.2: Characteristics of employed with and without industry/occupation information
*-------------------------------------------------------------------------------

* Load Dataset
use "./Data_panel/SOEP_merged_noindocc.dta", replace

gen dropped_missing_info_IV = 0
recode dropped_missing_info_IV (0=1) if labour_inc_no_pred ==1 | problemh ==1 | problemh_lag ==1

cd 			"./Output/Tables" // Temporary change directory to save table


* Copy lines for values into table	
sutex lifesat hhnetto_equivCPI sf12ind_UK ///
			disability age married edu_primary edu_secondary  ///
			edu_tertiary hobby_hours employed unemployed wrkhrs tenure if dropped_missing_info_IV ==1 & econact ==11 , digits(2) label  key(descstat) replace  ///
			file(tableA1_2_1.tex)  
			
sutex lifesat hhnetto_equivCPI sf12ind_UK ///
			disability age married edu_primary edu_secondary  ///
			edu_tertiary hobby_hours employed unemployed wrkhrs tenure if dropped_missing_info_IV ==0 & econact ==11, digits(2) label  key(descstat) replace  ///
			file(tableA1_2_2.tex)  

cd			"../../"

*-------------------------------------------------------------------------------
* Table A4.1: Characteristics of health state dependence sample
*-------------------------------------------------------------------------------

* Load dataset
use		 "./Data_panel/SOEP_merged_finalIMPUTATION_hstate.dta", replace

* Drop Individuals not in the health state dependency sample
drop	if	hstate_sample==0

cd 			"./Output/Tables" // Temporary change directory to save table

* Copy lines for values into table	

sutex lifesat hhnetto_equivCPI sf12ind_UK ///
			disability age married edu_primary edu_secondary  ///
			edu_tertiary hobby_hours employed unemployed wrkhrs tenure if hhnetto_equivCPIlag !=., digits(2) label  key(descstat) replace file(tableA4_1.tex)  
			
cd			"../../"


*-------------------------------------------------------------------------------
* Table 2 & Table A3.1: Baseline Regessions Imputed/Unimputed & First Stage
*-------------------------------------------------------------------------------
do 		./06_01_01_baseline.do

* Create Table 2 
cd 			"./Output/Tables" 
esttab		OLS_UK IV_UK OLS_UK_noimp IV_UK_noimp /// 
			using table2.tex, replace b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV") ///
			mgroups("\textbf{SF-6D Imputation}" "\textbf{No Imputation}", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) /// 
			span erepeat(\cmidrule(lr){@span})) keep($mqaly_ols $covariates)  /// 
			interaction(" $\times$ ")style(tex) alignment(lc) stats(Test_Statistics widstat idstat estat bic N Individuals CIV /// 
			, fmt(%9.0fc %9.0fc %9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc)  labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "Individuals"  "\hline \\ \textbf{CIV in \EUR{}}") ) nonumbers nogaps wide nonotes

* Table A3.1 output file 
esttab   	st1* using tableA3_1.tex, replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
			label nodep mtitles("\textbf{Income}" "\textbf{Lagged income}")  /// 
			keep($instruments $mqaly_iv $covariates_iv) ///
			interaction(" $\times$ ")style(tex) alignment(lc) stats(N  /// 
			, fmt(%9.0fc )  labels("Individuals * Years") ) nonumbers nogaps wide nonotes			

cd 			"../../"			


*-------------------------------------------------------------------------------
* Figures A3.5 to A3.7: IV validation 
*-------------------------------------------------------------------------------			
do			./06_01_SOEP_QALY_incomeprediction_error.do

*-------------------------------------------------------------------------------
* Table 3 & Table A2.1: Subgroups: Regions, Time-periods, Age, Gender
*-------------------------------------------------------------------------------
do		./06_01_02_subgroups.do 

* Create Table 3 and Table A2.1 output file
cd 			"./Output/Tables" 

* Table 3
esttab   	OLS_UK IV_UK OLS_UK_east IV_UK_east OLS_UK_west IV_UK_west OLS_UK_nocrisis IV_UK_nocrisis OLS_UK_precrisis IV_UK_precrisis OLS_UK_postcrisis IV_UK_postcrisis /// 
			using table3.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") ///
			mgroups("\textbf{Baseline}" "\textbf{East}" "\textbf{West}" "\textbf{w/o 2007-2009}" "\textbf{2002-2006}" "\textbf{2010-2018}" ///
			, pattern(1 0 1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag)  ///
			interaction(" $\times$ ") style(tex) alignment(lllllllllllll) stats(Test_Statistics widstat idstat estat bic N CIV , fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc)  /// 
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}} ") ) gaps nonumbers nonotes

* Table A2.1			
esttab   	OLS_UK IV_UK OLS_UK_young IV_UK_young OLS_UK_old IV_UK_old OLS_UK_male IV_UK_male OLS_UK_female IV_UK_female /// 
			using tableA2_1.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") /// 
			mgroups("\textbf{Baseline}" "\textbf{Age$<$50}" "\textbf{Age$\geq$50}" "\textbf{Male}" "\textbf{Female}", pattern(1 0 1 0 1 0 1 0 1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag) ///
			interaction(" $\times$ ") style(tex) alignment(lllllll) stats(Test_Statistics widstat idstat estat bic N CIV , fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) ///
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}} ") ) gaps nonumbers nonotes

cd 			"../../"			

   		
*-------------------------------------------------------------------------------
* Table 4 Income specifications: 
*-------------------------------------------------------------------------------
do 		./06_01_03_incomespecifications.do 

* Create Table 4 
cd 			"./Output/Tables" 

esttab		OLS_UK IV_UK OLS_UK_woutl1 IV_UK_woutl1 OLS_UK_log_nolag IV_UK_log_nolag OLS_UK_piece /// 
			using table4.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS") /// 
			mgroups("\textbf{Baseline}" "\textbf{Without Outliers}" "\textbf{Log income}" "\textbf{Piecewise}", pattern(1 0 1 0 1 0 1) /// 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag log_hhnetto_equivCPI income1 income2 income3 income4) ///
			interaction(" $\times$ ") style(tex) alignment(lllllll) stats(Test_Statistics widstat idstat estat bic N CIV CIV_lower WTPs1 WTPs2 WTPs3 WTPs4 N1 N2 N3 N4, fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) ///
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}}" "w/o $4^{th}$ spline" "Spline 1 only" "Spline 2 only" "Spline 3 only" "Spline 4 only" "\\ \textbf{Observations} \\ Spline 1" "Spline 2" "Spline 3" "Spline 4")) gaps nonumbers nonotes			

cd 			"../../"			


*-------------------------------------------------------------------------------
* Table 5: Choice of SF6D Tariff 
*-------------------------------------------------------------------------------
do 		./06_01_04_tariffchoice.do 

* Table 5
cd 			"./Output/Tables" 

esttab		OLS_UK IV_UK OLS_NL IV_NL /// 
			using table5.tex, replace b(2) se not star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV") ///
			mgroups("\textbf{UK Tariff}" "\textbf{Dutch Tariff}", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) /// 
			span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag )  /// 
			interaction(" $\times$ ") style(tex) alignment(cccc) stats(Test_Statistics widstat idstat estat bic N CIV /// 
			, fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc)  labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}}") ) gaps nonumbers nonotes

cd 			"../../"			
  

*-------------------------------------------------------------------------------
* Table 6 & Tables 4.2 to 4.4: Health State Dependency
*-------------------------------------------------------------------------------
do 		./06_01_05_hstatedependence.do 

* Table 6
cd 			"./Output/Tables" 

esttab   	OLS_UK_hstate IV_UK_hstate OLS_UK_good IV_UK_good OLS_UK_bad IV_UK_bad /// 
			using table6.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV") /// 
			mgroups("\textbf{Baseline}" "\textbf{Good Health}" "\textbf{Bad Health}", pattern(1 0 1 0 1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag) ///
			interaction(" $\times$ ") style(tex) alignment(lllllll) stats(Test_Statistics widstat idstat estat bic N CIV , fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) ///
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}} ") ) gaps nonumbers nonotes
	
* Table A4.2
esttab   	OLS_UK_hstate_incvar IV_UK_hstate_incvar OLS_UK_good_incvar IV_UK_good_incvar OLS_UK_bad_incvar IV_UK_bad_incvar /// 
			using tableA4_2.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV") /// 
			mgroups("\textbf{Baseline}" "\textbf{Good Health}" "\textbf{Bad Health}", pattern(1 0 1 0 1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag) ///
			interaction(" $\times$ ") style(tex) alignment(lllllll) stats(Test_Statistics widstat idstat estat bic N CIV , fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) ///
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}} ") ) gaps nonumbers nonotes

* Table A4.3
esttab   	OLS_UK_hstate_working IV_UK_hstate_working OLS_UK_good_working IV_UK_good_working OLS_UK_bad_working IV_UK_bad_working /// 
			using tableA4_3.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV") /// 
			mgroups("\textbf{Baseline}" "\textbf{Good Health}" "\textbf{Bad Health}", pattern(1 0 1 0 1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag) ///
			interaction(" $\times$ ") style(tex) alignment(lllllll) stats(Test_Statistics widstat idstat estat bic N CIV , fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) ///
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}} ") ) gaps nonumbers nonote		

* Table A4.4
esttab   	OLS_UK_hstate_severe IV_UK_hstate_severe OLS_UK_good_severe IV_UK_good_severe OLS_UK_bad_severe IV_UK_bad_severe /// 
			using tableA4_4.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV") /// 
			mgroups("\textbf{Baseline}" "\textbf{Good Health}" "\textbf{Bad Health}", pattern(1 0 1 0 1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag) ///
			interaction(" $\times$ ") style(tex) alignment(lllllll) stats(Test_Statistics widstat idstat estat bic N CIV , fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) ///
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}} ") ) gaps nonumbers nonote			

cd 			"../../"			


*-------------------------------------------------------------------------------
* Table A2.2 & 7: SF-6D Summary Score and Robustness Checks 
*-------------------------------------------------------------------------------
do		./06_02_SOEP_QALY_robust.do

* Create Table 7
cd 			"./Output/Tables" 
esttab   	OLS_UK IV_UK OLS_UK_working IV_UK_working OLS_UK_employed IV_UK_employed  OLS_wo_bonus IV_wo_bonus OLS_UK_w_IV_info /// 
			using table7.tex, replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS") /// 
			mgroups("\textbf{Baseline}" "\textbf{Working only}" "\textbf{No Self-Employed}" "\textbf{No bonus inc}" "\textbf{Ind/occ}", pattern(1 0 1 0 1 0 1 0 1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag) ///
			interaction(" $\times$ ") style(tex) alignment(llllll) stats(Test_Statistics widstat idstat estat bic N CIV , fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) ///
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}} ") ) gaps nonumbers nonotes

* Create Table A2.2 
esttab   	OLS_UK_noimp IV_UK_noimp OLS_sum IV_sum OLS_sfdim IV_sfdim using tableA2_2.tex /// 
			, wide replace b(2) not se star(* 0.10 ** 0.05 *** 0.01) label nodep ///
			mtitles("OLS" "IV" "OLS" "IV" "OLS" "IV") mgroups("\textbf{No imputation}" "\textbf{SF Summary Score}" "\textbf{SF-Dimensions}", pattern(1 0 1 0 1 0) /// 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
			keep(hhnetto_equivCPI hhnetto_equivCPIlag sf12ind_UK sf12ind_UKlag SF6D_sum_alt SF6D_sum_alt_lag SFPhys2 SFPhys3 SFRole2 SFRole3 SFRole4 SFSocial2 SFSocial3 SFSocial4 SFSocial5 SFPain2 SFPain3 SFPain4 SFPain5 SFMental2 SFMental3 SFMental4 SFMental5 SFVital2 SFVital3 SFVital4 SFVital5) /// 
			interaction(" $\times$ ") style(tex) alignment(llllll) stats(Test_Statistics widstat idstat estat bic N CIV CIV_ph CIV_rl CIV_soc  CIV_pain CIV_mental CIV_vital, fmt(%9.0fc %9.1fc %9.1fc %9.1fc %9.0fc %9.0fc %9.0fc) /// 
			labels("\\ \textbf{Model statistics}" "\hline \\ Cragg-Donald" "Anderson"  "Endogeneity test"  "\\ BIC" "Observations" "\hline \\ \textbf{CIV in \EUR{}}" "Physical Function" "Role Function" "Social Function" "Pain" "Mental Health" "Vitality") ) nonumbers nonotes nogaps

cd 			"../../"			

*-------------------------------------------------------------------------------
* Figures 2 & A3.1-A3.2 & A4.1-A4.2
*-------------------------------------------------------------------------------

do		05_SOEP_QALY_descriptivefigures
	
exit 


*===============================================================================
* 					Figure 3: Results overview graph 
*===============================================================================			
do			./06_03_SOEP_QALY_analysis_overviewgraph.do 


*===============================================================================
* End Program
*===============================================================================
capture log close

exit
