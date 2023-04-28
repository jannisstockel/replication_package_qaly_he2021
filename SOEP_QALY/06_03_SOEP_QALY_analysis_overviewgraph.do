*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Robustness Checks

Last Edit:	18.03.2021 20:55			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- CIV_overview.xlsx
			
Output: 	Overview Figure 3.
*/
*===============================================================================
clear all 
version 16 

*===============================================================================
* BEGIN PROGRAMME
*===============================================================================
*-------------------------------------------------------------------------------
* Results Overview Graph
*-------------------------------------------------------------------------------

* Load in data 
import excel CIV_overview.xlsx, sheet("civqalys") firstrow

* Define label values for specification titles 
label define specifications 1 "Baseline" 2 " " 3 "East" 4 "West" 5 " " 6 "w/o 2008/2009" 7 "2002-2007" 8 "2010-2018" ///
							9 " " 10 "Aged < 50" 11 "Aged >= 50" 12 "Male" 13 "Female"  /// 
							14 " " 15 "With Outliers" 16 "Log-Income" 17 " "  ///
							18 "All splines" 19 "w/o 4th spline" 20 " " ///
							21 "Dutch-Tariff" 22 " " 23 "HState Baseline" 24 "Good Health" ///
							25 "Bad Health" 26 " " 27 "No Imputation" 28 "Working only" /// 
							29 "No Self-Employed" 30 "No bonus income" 31 "Ind/occ missings"
							
label values spec specifications							

replace 	civ_ols 		= civ_ols/1000
replace 	civ_iv 			= civ_iv/1000
replace 	civ_olspiece 	= civ_olspiece/1000 
			
* Generate graph - greyscale, horizontal
twoway (dropline civ_ols spec 		if specgroup=="baseline", msymbol(Oh) msize(large) col("black%85")) /// 
	   (dropline civ_iv spec 		if specgroup=="baseline", msymbol(Dh) msize(large) col("black%45")) ///
	   (dropline civ_ols spec 		if specgroup=="population", msymbol(Oh) msize(large) col("black%85")) /// 
	   (dropline civ_iv spec 		if specgroup=="population", msymbol(Dh) msize(large) col("black%45")) ///
	   (dropline civ_ols spec 		if specgroup=="region", msymbol(Oh) msize(large) col("black%85")) /// 
	   (dropline civ_iv spec 		if specgroup=="region", msymbol(Dh) msize(large) col("black%45")) ///
	   (dropline civ_ols spec 		if specgroup=="obsperiod", msymbol(Oh) msize(large) col("black%85")) /// 
	   (dropline civ_iv spec 		if specgroup=="obsperiod", msymbol(Dh) msize(large) col("black%45")) ///
	   (dropline civ_ols spec 		if specgroup=="incomespecs", msymbol(Oh) msize(large) col("black%85")) ///
	   (dropline civ_iv spec 		if specgroup=="incomespecs", msymbol(Dh) msize(large) col("black%45")) ///	
	   (dropline civ_olspiece spec 	if specgroup=="incomespecs", msymbol(O) msize(large) col("black")) ///
	   (dropline civ_ols spec 		if specgroup=="tariff", msymbol(Oh) msize(large) col("black%85")) /// 
	   (dropline civ_iv spec 		if specgroup=="tariff", msymbol(Dh) msize(large) col("black%45")) ///
	   (dropline civ_ols spec 		if specgroup=="hstate", msymbol(Oh) msize(large) col("black%85")) /// 
	   (dropline civ_iv spec 		if specgroup=="hstate", msymbol(Dh) msize(large) col("black%45")) ///
	   (dropline civ_ols spec 		if specgroup=="robust", msymbol(Oh) msize(large) col("black")) /// 
	   (dropline civ_iv spec 		if specgroup=="robust", msymbol(Dh) msize(large) col("black%45")) ///
	   , graphregion(col(white)) yline(58.56, lcolor("black%85") lwidth(thin) lpattern(dash_dot)) ///
	   yline(22.66, lcolor("black%45") lwidth(thin) lpattern(dash_dot)) ///
	   yscale(range(0 160)) ylabel(0(20)160, format(%9.0f) nogrid) xscale(range(1 31)) ///
	   xlabel(1(1)31, valuelabel angle(45) labsize(small)) xtitle("") ///
	   ytitle("CIV-QALY in 1,000€") legend(region(col(white)) col(1) ring(0) position(11) order(1 "OLS" 11 "OLS-Piecewise" 2 "IV" ) size(small) symxsize(6)) ///
	   text(82 3.5 "{subscript:|}{superscript:________}{subscript:|}", orientation(horizontal)) ///
	   text(88 3.5 "Regions",  place(c) size(small)) xline(3.5, lwidth(12) lc(gs15))  ///
	   text(76 7 "{subscript:|}{superscript:____________}{subscript:|}", orientation(horizontal)) ///
	   text(82 7 "Time-periods",  place(c) size(small)) ///
	   text(103 11.5 "{subscript:|}{superscript:________________}{subscript:|}", orientation(horizontal) place(c)) ///
	   text(110 11.5 "Subgroups",  place(c) size(small)) xline(11.5, lwidth(20) lc(gs15)) ///
	   text(158 17 "{subscript:|}{superscript:__________________}{subscript:|}", orientation(horizontal)) ///
	   text(164 17 "Income specifications",  place(c) size(small)) ///
	   text(68 23 "{subscript:|}{superscript:__________________}{subscript:|}", orientation(horizontal)) ///
	   text(76 23 "Health specifications",  place(c) size(small)) xline(23, lwidth(24) lc(gs15)) /// 
	   text(86 29 "{subscript:|}{superscript:__________________}{subscript:|}", orientation(horizontal)) ///
	   text(100 29 "Robustness", place(c) size(small)) text(92 29 "Checks", place(c) size(small)) 
	   
graph export "./Output/Graphs/figure3.png", replace				

*===============================================================================
* BEGIN PROGRAMME
*===============================================================================		
		