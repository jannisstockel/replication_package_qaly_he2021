*===============================================================================
/*	
Analysis: The Value of Health Paper - German SOEP: Income Specifications

Last Edit:	18.03.2021 20:55			
			
Author: 	Sebastian Himmler & Jannis Stöckel

Outline: 	This dofile creates multiple descriptive graphs presented in the 
			main body of the paper and the appendices. 
		 
Input: 		Multiple analyis datasets 
			- SOEP_merged_finalIMPUTATION.dta

Output: 	Results from income specifications presented in Table 4 and Figure 1. 
*/
*===============================================================================

*===============================================================================
* Income Outliers and Log-Income OLS & IV Models 
*===============================================================================

*-------------------------------------------------------------------------------
* OLS/IV Model including income outliers  
*-------------------------------------------------------------------------------
* Load Dataset including outliers
use		"./Data_panel/SOEP_merged_finalIMPUTATION_incloutlier.dta",  replace

* OLS 
xtreg 	lifesat $mqaly_ols $covariates $years $states, fe robust

matrix B1	=	e(b)
scalar 	OLS_UK_woutl_sc		=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define OLS_UK_woutl1 = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(OLS_UK_woutl_sc*1000)]
estimate store OLS_UK_woutl1

estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_UK_woutl_sc*1000

* IV 
xtivreg2 	lifesat $mqaly_iv $covariates_iv $years $states ($endog_base = $instruments) ///
			, fe robust first endog($endog_base)

matrix B1	=	e(b)		

scalar 	IV_UK_woutl_sc	=	(B1[1,3] + B1[1,4])/(B1[1,1] + B1[1,2])

matrix 	define IV_UK_woutl1 = [B1[1,1]\B1[1,2]\B1[1,3]\B1[1,4]\e(N)\(IV_UK_woutl_sc*1000)]
estimates store IV_UK_woutl1			

estadd scalar Individuals = e(N_g)
estadd scalar CIV = IV_UK_woutl_sc*1000

*-------------------------------------------------------------------------------
* OLS/IV Model using Log-Income specification
*-------------------------------------------------------------------------------

* Load Dataset without outliers as used in main analysis 
use		"./Data_panel/SOEP_merged_finalIMPUTATION.dta", replace

* Calculate median annual income for calculation
sum hhnetto_equivCPI, detail
scalar med_inc = r(p50)*12

* OLS 
xtreg 	lifesat log_hhnetto_equivCPI sf12ind_UK $covariates  $years $states if log_hhnetto_equivCPIlag !=., fe robust
		
* Equation implemented as described in methods section		
scalar 	CV_log_nolag_sc =	med_inc*((exp(-(_b[sf12ind_UK]/10)/_b[log_hhnetto_equivCPI])-1))*10

matrix 	define 	OLS_UK_log_nolag = [_b[log_hhnetto_equivCPI]\0\_b[sf12ind_UK]\0\e(N)\(CV_log_nolag_sc*1000)]
matrix list OLS_UK_log_nolag
estimates store OLS_UK_log_nolag
estadd scalar Individuals = e(N_clust)
estadd scalar CIV = (-1)*CV_log_nolag_sc*1000

* IV 
xtivreg2 lifesat  sf12ind_UK $covariates_iv $years $states (log_hhnetto_equivCPI = hh_pred_labourinc_log) if log_hhnetto_equivCPI !=. & log_hhnetto_equivCPIlag !=., fe robust first endog(log_hhnetto_equivCPI)

scalar 	CV_log_nolag_IV_sc =	med_inc*((exp(-(_b[sf12ind_UK]/10)/_b[log_hhnetto_equivCPI])-1))*10

matrix 	define 	IV_UK_log_nolag = [_b[log_hhnetto_equivCPI]\0\_b[sf12ind_UK]\0\e(N)\(CV_log_nolag_IV_sc*1000)]
matrix list IV_UK_log_nolag
estimates store IV_UK_log_nolag

estadd scalar Individuals = e(N_g)
estadd scalar CIV = (-1)*CV_log_nolag_IV_sc*1000

*-------------------------------------------------------------------------------
* OLS-Piecewise Regression
*-------------------------------------------------------------------------------

* Implementation based on
/* Ólafsdóttir, T., Ásgeirsdóttir, T. L., & Norton, E. C. (2020). 
Valuing pain using the subjective well-being method. Economics & Human Biology, 37, 100827.
*/
* Create deciles
xtile decile = hhnetto_equivCPI, nq(10)

forvalue i = 1/10 {

	sum hhnetto_equivCPI if decile ==`i'
	scalar decile`i' = r(max)

}

* Create Income groups in an iterative process: 10 Groups 
mkspline income1 .9780919 income2  1.200868 income3  1.378056 income4 1.546853 ///
income5 1.73 income6 1.95778 income7 2.232593  income8 2.635473 income9 ///
3.37744 income10 = hhnetto_equivCPI

xtreg 	lifesat income* sf12ind_UK sf12ind_UKlag $covariates $years $states, fe robust
estat ic

test income1 = income2
test income2 = income3
test income3 = income4
test income4 = income5
test income5 = income6
test income6 = income7
test income7 = income8
test income8 = income9
test income9 = income10

drop income*

mkspline income1 1.200868 income2  1.546853 income3 2.635473 income4 = hhnetto_equivCPI

xtreg 	lifesat income* sf12ind_UK $covariates $years $states, fe robust
estat ic

mat s = r(S)
scalar BIC = s[1,6]

test income1 = income2 // All splines significantly different from each other, AIC and BIC smaller (=better) than in linear and log
test income2 = income3
test income3 = income4

estimate store OLS_UK_piece

* Attach labels for Table
label var	income1 "$1^{st}$ income spline"
label var	income2 "$2^{nd}$ income spline"
label var	income3 "$3^{rd}$ income spline"
label var	income4 "$4^{th}$ income spline"

* Calculate WTPs for different groups
scalar WTPs1 = (_b[sf12ind_UK])/(_b[income1])*1000	
scalar WTPs2 = (_b[sf12ind_UK])/(_b[income2])*1000	
scalar WTPs3 = (_b[sf12ind_UK])/(_b[income3])*1000
scalar WTPs4 = (_b[sf12ind_UK])/(_b[income4])*1000

sum age if hhnetto_equivCPI 	< 1.200868
scalar N1 = r(N)
sum age if hhnetto_equivCPI 	>= 1.200868 & hhnetto_equivCPI < 1.546853 
scalar N2 = r(N)
sum age if hhnetto_equivCPI 	>= 1.546853  & hhnetto_equivCPI < 2.635473 
scalar N3 = r(N)
sum age if hhnetto_equivCPI 	>= 2.635473 
scalar N4 = r(N)

scalar Nsum = N1+N2+N3+N4

scalar OLS_splines_sc = (WTPs1*(N1/Nsum)+ WTPs2*(N2/Nsum)+ WTPs3*(N3/Nsum)+ WTPs4*(N4/Nsum))
di OLS_splines_sc

// Alternative without upper spline which are not significant

scalar OLS_splines_lower_sc = (WTPs1*(N1/(N1+N2+N3))+ WTPs2*(N2/(N1+N2+N3))+WTPs3*(N3/(N1+N2+N3)))
di OLS_splines_lower_sc

* Results without income lags
matrix 	define OLS_splines = [_b[income1]\_b[income2]\_b[income3]\_b[income4]\_b[sf12ind_UK]\e(N)\WTPs1\WTPs2\WTPs3\WTPs4\OLS_splines_lower_sc\OLS_splines_sc]

matrix list OLS_splines

estadd scalar Individuals = e(N_clust)
estadd scalar CIV = OLS_splines_sc
estadd scalar CIV_lower = OLS_splines_lower_sc
estadd scalar WTPs1
estadd scalar WTPs2
estadd scalar WTPs3
estadd scalar WTPs4

* Add Number of Observations 
estadd scalar N1
estadd scalar N2
estadd scalar N3
estadd scalar N4

* Creating Figure 1 
graph drop _all

twoway 	(scatter lifesat hhnetto_equivCPI if hhnetto_equivCPI <5, jitter(7) msize(0.5) col("black%1") ///
		xline(1.200868, lcol("black") lpattern(dash_dot)) xline(1.546853, lcol("black") lpattern(dash_dot)) xline(2.635473, lcol("black") lpattern(dash_dot))) ///
		(lfit lifesat hhnetto_equivCPI if hhnetto_equivCPI < 1.200868 , range(. 1.200868) col(black)) 			///
		(lfit lifesat hhnetto_equivCPI if hhnetto_equivCPI >= 1.200868 & hhnetto_equivCPI < 1.546853, range(1.200868 1.546853) col(black)) ///
		(lfit lifesat hhnetto_equivCPI if hhnetto_equivCPI >= 1.546853 & hhnetto_equivCPI < 2.635473, range(1.546853 2.635473) col(black)) ///
		(lfit lifesat hhnetto_equivCPI if hhnetto_equivCPI >= 2.635473 , range(2.635473 5) col(black)), legend(off) ///
		ytitle("Life satisfaction (10: best possible life)") xtitle("Equivalised net household income in 1,000€") ///
		yscale(range(-0.5,10.5)) ylabel(0(2)10) xscale(range(0,5.2)) xlabel(0(1)5) /// 
		graphregion(col(white))

graph export "./Output/Graphs/figure1.png", replace