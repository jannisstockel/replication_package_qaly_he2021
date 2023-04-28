*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Income Prediction Details

Last Edit:	18.03.2021 20:55			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta
			
Output: 	Graphs related to the income instrument details:
			- Figure A3.5 
			- Figure A3.6 
			- Figure A3.7
*/
*===============================================================================


* Load in Dataset
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

*-------------------------------------------------------------------------------
* 					Figure A3.5: QQ-plot of observed and predicted incomes
*-------------------------------------------------------------------------------

* Prepare data
xtset pid syear

* Predicted vs actual income to have an idea about the prediction error, therefore, use labour income instead of total income
* Plot for those with non zero labour income (and then also non-zero predicted labour income)

label var net_labour_income "Net household labour income in €1,000"
label var hh_pred_labourinc_lin "Predicted net household labour income in €1,000"

sum net_labour_income if net_labour_income !=0, detail 

* Dropping very high incomes above 20k net and providing indication where 80% of the population are
qqplot net_labour_income hh_pred_labourinc_lin if net_labour_income != 0 & net_labour_income < 20, yline(.499) yline(3.37)


graph export "./Output/Graphs/figureA3_5.png", replace

*-------------------------------------------------------------------------------
*					Figure A3.6: Life satisfaction and industry
*-------------------------------------------------------------------------------

xtreg lifesat hhnetto_equivCPI hhnetto_equivCPIlag $covariates ib(freq).industry, fe robust

label drop industries
label define industries 1 "Agriculture" 2 "Mining" 3 "Construction" 4 "Wood" 5 "Stone/Glass" /// 
			6 "Metal" 7 "Non-electrical machinery" 8 "Electronics" 9 "Transportation equipment" ///
			10 "Food/Tobacco" 11 "Professional equipment" 12 "Clothing" 13 "Paper" 14 "Printing" ///
			15 "Chemicals" 16 "Petroleum/Rubber" 17 "Other manufacturing" 18 "Transportation" ///
			19 "Telecommunication" 20 "Utilities" 21 "Wholesale trade" 22 "Retail trade" ///
			23 "Finance/Insurance" 24 "Business Services" 26 "Personal/repair services" ///
			27 "Recreational services" 28 "Healthcare" 30 "Education" 32 "Other" 33 "Public administration" 34 "Hopsitality", add
		
label value industry industries		

coefplot ,  msymbol(oh) sort baselevels  drop(hhnetto_equivCPI hhnetto_equivCPIlag $covariates _cons) xline(0) label graphregion(col(white)) grid(none)

graph export "./Output/Graphs/figureA3_6.png", replace

*-------------------------------------------------------------------------------
*					Figure A3.7: Life satisfaction and occupation
*-------------------------------------------------------------------------------

xtreg lifesat hhnetto_equivCPI hhnetto_equivCPIlag $covariates ib(freq).occupation, fe robust

label drop occupations
label define occupations 1 "Managerial" 2 "Engineers" 3 "IT Professional" 4 "Natural Scientist" ///
			5 "Medical Professional" 6 "Caregiver/Nurse" 7 "Post-secondary teachers" 8 "Other teachers" ///
			9 "Counsellors/Librarians" 10 "Social scientists/Urban planners" 11 "Social/Religious workers" ///
			12 "Lawyers/Judges" 13 "Writers/Artists" 14 "Technicians/Supporting occupations" /// 
			15 "Sales occupations" 16 "Clerical/Administrative support" 17 "Private household workers" ///
			18 "Protective service workers" 19 "Other service workers" 20 "Farmers" ///
			21 "Crafts/Repair workers" 22 "Operators/Laborers"

label value occupation occupations

coefplot ,  msymbol(oh) sort baselevels  drop(hhnetto_equivCPI hhnetto_equivCPIlag $covariates _cons) xline(0) label graphregion(col(white)) grid(none)

graph export "./Output/Graphs/figureA3_7.png", replace



