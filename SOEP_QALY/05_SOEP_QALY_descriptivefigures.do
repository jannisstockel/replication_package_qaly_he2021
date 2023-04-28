*===============================================================================
/*	
Descriptives: The Value of Health Paper - German SOEP 

Last Edit:	18.03.2021 20:55		
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Dataset used for baseline analysis. 
			- SOEP_merged_finalIMPUTATION.dta

Output: 	Descriptive graphs 
			- Figure 2 
			- Figure A3.1 
			- Figure A3.2 
			- Figure A4.1 
			- Figure A4.2 
*/
*===============================================================================
clear all
version 16
capture log close
set more off

log using "./Output/05_SOEP_QALY_figures", text replace
*===============================================================================
* BEGIN PROGRAM
*===============================================================================

*-------------------------------------------------------------------------------
* UK vs Dutch Tariff figure 
*-------------------------------------------------------------------------------

use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace	

preserve
drop	if	valid==0				
				
sum		sf12ind_UK 
local   uk_mean = r(mean)

sum		sf12ind_NL 
local   nl_mean = r(mean)
								
graph twoway (hist sf12ind_UK, color(black%20) width(0.05)) (hist sf12ind_NL, fcolor(none) lcolor(black) width(0.05)), ///
				graphregion(color(white)) ytitle("Density") xtitle("SF-6D Utility") ///
				legend(col(1) ring(0) position(11) order(1 "UK-Tariff" 2 "NL-Tariff") symxsize(4)) ///
				xline(`uk_mean', lcol("black%35") lpattern(dash_dot)) xline(`nl_mean', lcol(black) lpattern(dash_dot))
				
				
graph export 	"./Output/Graphs/figure2.png", replace
restore

*-------------------------------------------------------------------------------
* Distribution of Incomes Across Industry, Figure A3.1 and A3.2
*-------------------------------------------------------------------------------

drop if industry==. | occupation==.

* Calculate Numbers on industry-occupation cells 
tostring industry, generate(industry_strg) // make industry/occupation to string
tostring occupation, generate(occupation_strg)

gen 	ind_occ_cell = industry_strg + occupation_strg // create unique industry occupation cell

local level "industry occupation ind_occ_cell"

* Cell populations: Unique individuals
foreach x of local level {
	
	preserve
	sort 	pid `x' 
	by 		pid `x': keep if _n==1

	collapse (count) n = pid, by(`x')
	
	sum n, detail
	restore
	
}

* Cell populations: Individual-year observations
foreach x of local level {
	
	preserve
	collapse (count) n = pid, by(`x')
	
	sum n, detail
	restore
	
}

* Generate hourly and predicted weekly net labour income
gen		hourly_earnings 	= net_labour_inc/wrkhrs
gen 	net_fulltime_inc 	= hourly_earnings * 40 

* Collapse to industry level mean + standard deviation + N in cell
preserve
collapse (mean) mean_netto = net_fulltime_inc (sd) sd_netto = net_fulltime_inc (count) n = net_labour_inc, by(industry)

* Generate Super-Industry Groups 
gen 	industry_sector = 1 if industry<=6 
replace industry_sector = 2 if industry>6 & industry<=20 
replace industry_sector = 3 if industry>= 21

label define industry_sectors 1 "Agriculture/Resource Production" 2 "Manufacturing" 3 "Services"
label values industry_sector industry_sectors

* Sort in ascending order within industry sectors 
sort industry_sector mean_netto
gen  id = _n 

replace id = id + 1 	if industry_sector == 2
replace id = id + 2 	if industry_sector == 3

* Generate upper/lower CI
gen high_netto= mean_netto + invttail(n-1,0.025)*(sd_netto / sqrt(n))
gen low_netto = mean_netto - invttail(n-1,0.025)*(sd_netto / sqrt(n))

* Attach labels to ranked IDs
label define industries_ranked 1 "Agriculture" 6 "Mining" 4 "Construction" 2 "Wood" 3 "Stone/Glass" /// 
						5 "Metal"  7 " " /// Agriculture/Resources
						21 "Non-electrical machinery" 18 "Electronics" 19 "Transportation equipment"  ///
						10 "Professional equipment" 14 "Food/Tobacco" 9 "Clothing" ///
						11 "Paper" 13 "Printing" 20 "Chemicals" 15 "Petroleum/Rubber" /// 
						8 "Other manufacturing" 12 "Transportation" 16 "Telecommunication" ///
						17 "Utilities" 22 " " /// Manufacturing
						27 "Wholesale trade" 25 "Retail trade" 33 "Finance/Insurance" /// 
						30 "Business services" 24 "Personal/repair services" ///
						29 "Recreational services" 28 "Healthcare" 32 "Education" ///
						26 "Other" 31 "Public administration" 23 "Hospitality"
						
label values id industries_ranked

* Generate Plot
twoway (scatter mean_netto id, msize(small) msymbol(oh) col("black%85")) ///
	   (rcap high_netto low_netto id, msize(medlarge) lwidth(vthin) col("black%40")) ///
	   , graphregion(col(white)) yscale(range(1 3)) ylabel(1(0.5)3, nogrid) xscale(range(1 33)) /// 
	   xlabel(1(1)33, valuelabel angle(45) labsize(vsmall)) xtitle("") ///
	   ytitle("Monthly Earnings in 1,000€") /// 
	   legend(region(col(white)) col(1) ring(0) position(5) /// 
	   order(1 "Mean" 2 "95%-CI") size(vsmall) symxsize(6)) /// 
	   text(2.85 3.5 "{subscript:|}{superscript:__________________}{subscript:|}", orientation(horizontal)) ///
	   text(3.05 3.5 "Agriculture &",  place(c) size(vsmall)) text(2.95 3.5 "Resource Production",  place(c) size(vsmall)) ///	
	   text(2.55 14.5 "{subscript:|}{superscript:______________________________________________}{subscript:|}", orientation(horizontal)) ///
	   text(2.65 14.5 "Manufacturing",  place(c) size(vsmall))   ///
	   text(2.45 28 "{subscript:|}{superscript:____________________________________}{subscript:|}", orientation(horizontal)) ///
	   text(2.55 28 "Services",  place(c) size(vsmall))  				

graph export "./Output/Graphs/figureA3_1.png", replace				

restore 

* Collapse to occupation level mean + standard deviation + N in cell
collapse (mean) mean_netto = net_fulltime_inc (sd) sd_netto = net_fulltime_inc (count) n = net_labour_inc, by(occupation)

* Generate upper/lower CI
gen high_netto= mean_netto + invttail(n-1,0.025)*(sd_netto / sqrt(n))
gen low_netto = mean_netto - invttail(n-1,0.025)*(sd_netto / sqrt(n))

* Generate new ID ranked by income
sort mean_netto 
gen		id = _n 

* Attach labels to ranked IDs
label define occupations_ranked 14 "Managerial" 19 "Engineers" 16 "IT Professional" /// 
						15 "Natural Scientist" 22 "Medical Professional" 9 "Caregiver/Nurse" ///
						20 "Post-secondary teachers" 18 "Other teachers" 10 "Counsellors/Librarians" ///
						17 "Social scientists/Urban planners" 8 "Social/Religous workers" ///
						21 "Lawyers/Judges" 12 "Writers/Artists" 11 "Technicians/Supporting occupations" /// 
						5 "Sales occupations" 7 "Clerical/Administrative support" 3 "Private household workers" ///
						13 "Protective services workers" 2 "Other service workers" ///
						1 "Farmers" 6 "Crafts/repair workers" 4 "Operators/Laborers"
						
label values id	occupations_ranked		
	
* Create Plot
twoway (scatter mean_netto id, msize(small) msymbol(oh) col("black%85")) ///
	   (rcap high_netto low_netto id, msize(medlarge) lwidth(vthin) col("black%40")) ///
	   , graphregion(col(white)) yscale(range(1 4)) ylabel(1(0.5)4, nogrid) xscale(range(1 22)) /// 
	   xlabel(1(1)22, valuelabel angle(45) labsize(vsmall)) xtitle("") ///
	   ytitle("Monthly Earnings in 1,000€") /// 
	   legend(region(col(white)) col(1) ring(0) position(5) /// 
	   order(1 "Mean" 2 "95%-CI") size(vsmall) symxsize(6)) /// 
	   
graph export "./Output/Graphs/figureA3_2.png", replace		

*-------------------------------------------------------------------------------
* SF6D Distributions Graphs, Figure A4.1, Panel a) and b)
*-------------------------------------------------------------------------------

* Load Dataset
use "./Data_panel/SOEP_merged_finalIMPUTATION_hstate.dta", replace 

* Generate locals for mean lines 
sum 	sf12ind_UK 		if hstate_sample==0
local	mean_rest 	=	r(mean)	
sum 	sf12ind_UK 		if hstate_sample==1
local	mean_hstate =	r(mean)
sum 	sf12ind_UK 		if hstate_sample==1 & hstate_good==1
local	mean_good 	=	r(mean)
sum 	sf12ind_UK 		if hstate_sample==1 & hstate_bad==1
local	mean_bad 	=	r(mean)		

* Graph: SF6D Non health state change sample vs hstate sample
graph twoway	(hist sf12ind_UK if hstate_sample==0, color("black%20") width(0.025)) ///
				(hist sf12ind_UK if hstate_sample==1, fcolor(none) lcolor(black) width(0.025)), ///
				graphregion(color(white)) ytitle("Density") xtitle("SF-6D Utility") ///
				legend(col(1) ring(0) position(11) order(1 "Stable Health" 2 "Changing Health") size(small) symxsize(4)) ///
				xline(`mean_rest', lcol("black%35") lpattern(dash_dot)) xline(`mean_hstate', lcol(black) lpattern(dash_dot)) ///
				title("(a) SF-6D by Health Trajectory", size(medium) col(black)) saving(sf6d_hchange, replace)	
				
* Graph: SF6D Hstate sample: Good Health vs Bad Health
graph twoway	(hist sf12ind_UK if hstate_sample==1 & hstate_good==1, color("black%20") width(0.025)) ///
				(hist sf12ind_UK if hstate_sample==1 & hstate_bad==1, fcolor(none) lcolor(black) width(0.025)), ///
				graphregion(color(white)) ytitle("Density") xtitle("SF-6D Utility") ///
				legend(col(1) ring(0) position(11) order(1 "Good Health" 2 "Bad Health") size(small) symxsize(4)) ///
				xline(`mean_good', lcol("black%35") lpattern(dash_dot)) xline(`mean_bad', lcol(black) lpattern(dash_dot)) ///
				title("(b) SF-6D by Health State", size(medium) col(black))	saving(sf6d_hstate, replace)
							
*-------------------------------------------------------------------------------
* Income Distribution Graphs, Figure A4.1, Panel c) and d) 
*-------------------------------------------------------------------------------
drop if hstate_sample==0
drop if obs_count!=1

sum		mean_inc_good_fl	
local	mean_good = r(mean)
sum		mean_inc_bad_fl	
local	mean_bad = r(mean)

* Graph: Within-person income mean 
graph twoway 	(hist mean_inc_good_fl if hstate_good==1, color("black%20") width(0.4)) ///				
				(hist mean_inc_bad_fl if hstate_bad==1, fcolor(none) lcolor(black) width(0.4)), ///
				graphregion(color(white)) ytitle("Density") xtitle("Mean Income (within person)") ///
				legend(col(1) ring(0) position(1) order(1 "Good Health" 2 "Bad Health") size(small) symxsize(4)) ///
				title("(c) Incomes by Health State", size(medium) col(black))	saving(inc_hstate, replace)
				
* Graph: Income good health and bad health 	
sum		inc_ratio if nworking==0
local	lower = r(mean)-r(sd)

* Graph: Income ratio good health and bad health 			
graph twoway (hist inc_ratio, color(black%20) width(0.1)), /// 
			 graphregion(color(white)) ytitle("Density") xtitle("Income Ratio Bad Health/Good Health") ///
			 xline(`lower', lcol(black) lpattern(dash_dot)) ///
			 title("(d) Income Changes", size(medium) col(black)) saving(incratio_hstate, replace)

*-------------------------------------------------------------------------------
* Figure A4.1
*-------------------------------------------------------------------------------			 
			 
* Combine Graphs
graph combine sf6d_hchange.gph sf6d_hstate.gph inc_hstate.gph incratio_hstate.gph, imargin(1 1 1 1)	graphregion(col(white))	

graph export "./Output/Graphs/figureA4_1.png", replace

erase		./sf6d_hchange.gph
erase		./sf6d_hstate.gph
erase		./inc_hstate.gph
erase		./incratio_hstate.gph 	

*-------------------------------------------------------------------------------
* Good/Bad Health Component Scores, Figure A4.2
*-------------------------------------------------------------------------------

* Load Dataset to explore health-change related attrition 
use 	"./Data_panel/SOEP_merged_finalIMPUTATION_hstate.dta", replace 

sort	pid syear

drop if hstate_sample==0

preserve
by pid: keep if _n==1 

* Calculate Mean change levels for later plotting
sum 	mcs_change 
local	mcs_change_mean = r(mean)
sum pcs_change 
local	pcs_change_mean = r(mean)

* Main Graph: Scatterplot Mental vs Physical  Health Changes
graph twoway scatter mcs_change pcs_change, msize(0.5) mcolor("black%15") jitter(1) ///
				xtitle("Physical Score Change") ytitle("") ylabel(, grid gmax) ///
				xline(`pcs_change_mean', lcol(black) lpattern(dash) lwidth(0.15)) /// 
				yline(`mcs_change_mean', lcol(black) lpattern(dash) lwidth(0.15)) ///
				yscale(range(0,40) alt noline) xscale(range(0,32) alt noline) xlabel(, grid gmax) ///
				graphregion(col(white)) saving(scorechange_scatter, replace) 
				
* Supplementary Graph 1: Mental Score Change				
graph twoway hist mcs_change, horizontal width(1) col("black%35") xscale(alt reverse noline) ///
				yline(`mcs_change_mean', lcol(black) lpattern(dash) lwidth(0.15)) ///
				yscale(range(0,40) noline) ylabel(, gmax) xlabel(0(0.05)0.1) ///
				fxsize(25) ytitle("Mental Score Change") xtitle("") ///
				graphregion(col(white)) saving(scorechange_hist_mcs, replace)
				
* Supplementary Graph 2: Physical Score Change 				
graph twoway hist pcs_change, width(1) col("black%35") yscale(alt reverse noline) ///
				xscale(noline) xtitle("") ytitle("") fysize(25) ytitle("") xscale(range(0,32)) ///
			    xlabel(, grid gmax) xline(`pcs_change_mean', lcol(black) lpattern(dash) lwidth(0.15)) ///
				graphregion(col(white)) saving(scorechange_hist_pcs, replace)				

* Combine Graphs
graph combine scorechange_hist_mcs.gph scorechange_scatter.gph scorechange_hist_pcs.gph ///
				, hole(3) imargin(0 0 0 0) graphregion(margin(l=1 r=1)) graphregion(col(white)) 

graph export  "./Output/Graphs/figureA4_2.png", replace 

erase 	./scorechange_hist_mcs.gph
erase 	./scorechange_hist_pcs.gph
erase 	./scorechange_scatter.gph				

restore

*===============================================================================
* End Program
*===============================================================================
capture log close

exit


