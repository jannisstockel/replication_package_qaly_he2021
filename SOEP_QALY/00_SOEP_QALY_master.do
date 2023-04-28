*===============================================================================
/*	
MASTER: The Value of Health Paper - German SOEP

Last Edit: 	18.03.2021 20:32
			
Authors: 	Sebastian Himmler (himmler@eshpm.eur.nl)
			Jannis Stöckel (stockel@eshpm.eur.nl)

Outline: 	This dofile runs all analyses presented in the paper "The
			Value of Health - Empirical Issues when estimating the Monetary Value 
			of a QALY using Well-being data" (Himmler, Stöckel, van Exel, and Brouwer
			; Health Economics 2021) and creates the dataset underlying the analyses. 
		 
Input: 		SOEP data release v35 (2002-2018)
			- Cross-year files: pgen.dta, pl.dta, hgen.dta, health.dta
			- By-year files: skind.dta/sp.dta (2002) to bikind.dta/bip.dta (2018)  

Output: 	- Intermediate datasets 
			- Cleaned and formatted dataset as described in the paper
			- Analyses described in the paper
			- All figures and tables as described in the paper apart from Table A1.1
*/
*===============================================================================
clear 	all
version 16
capture log close
set 	more off

* Install necessary packages not part of regular stata distribution 
ssc install tsspell

*===============================================================================
* BEGIN PROGRAM
*===============================================================================

* Extract variables from raw SOEP files
do 	./01_00_SOEP_QALY_extract.do

* Merge to new dataset in raw format, all waves all individuals
do	./02_SOEP_QALY_merge.do

* Clean merged data
do 	./03_SOEP_QALY_clean.do

* Transform and create variables for analyses
do 	./04_00_SOEP_QALY_prep.do

* Step 5: Descriptives
do 	./05_SOEP_QALY_descriptivefigures.do

* Step 6: Analysis & Output 
do	./06_00_SOEP_QALY_analysis_manuscript.do

*===============================================================================
* END PROGRAM
*===============================================================================

exit
