clear
cap drop _all
cap graph drop _all

/********************* READ IN THE DATA ***********************/
use "JSTdatasetR4.dta"

sort ifs year								/* ifs indicates the country */
xtset  ifs year, yearly

/******************** Some Data transformations ***************/
gen lgdpr = 100*ln(rgdppc*pop)				/* convert to RGDP and take log */
gen lcpi = 100*ln(cpi)						

gen dlcpi = d.lcpi
gen dlgdpr = d.lgdpr
gen dstir = d.stir
gen lstir = l.stir

/* Generate LHS variables for the LPs */

foreach x in lgdpr lcpi stir {
forv h = 0/4 {
*gen `x'`h' = f`h'.`x' - l.`x' 			// Use for cumulative IRF
gen `x'`h' = f`h'.`x' - l.f`h'.`x'		// Use for usual IRF

}
}

********************************************
* Set Sample if only interested in post-WW2
********************************************
*keep if year>=1950

**************************************************************
* Compute LPs. Note: a loop is more elegant but tricky to code
* because I am using Cholesky identification and controls vary
* by regression
**************************************************************


** Real GDP to STIR

eststo clear
cap drop b u d Years Zero
gen Years = _n-1 if _n<=6
gen Zero =  0    if _n<=6
gen b=0
gen u=0
gen d=0
qui forv h = 0/4 {
xtreg lgdpr`h' l(1/3).dlgdpr l(1/3).dlcpi l(1/3).dstir, fe cluster(iso)
replace b = _b[l.dstir]                     if _n == `h'+2
replace u = _b[l.dstir] + 1.645* _se[l.dstir]  if _n == `h'+2
replace d = _b[l.dstir] - 1.645* _se[l.dstir]  if _n == `h'+2
eststo 
}
nois esttab , se nocons keep(L.dstir)
twoway ///
		(rarea u d  Years,  ///
		fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
		(line b Years, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line Zero Years, lcolor(black)), legend(off) ///
		title("Response of GDPR to 1pp shock to STIR (Cholesky)", color(black) size(medsmall)) ///
		ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
		graphregion(color(white)) plotregion(color(white))
		
		gr rename g_gdpr , replace
		
** Real CPI to STIR (Note: l(0/3).dlgdpr in xtreg)

eststo clear
cap drop b u d Years Zero
gen Years = _n-1 if _n<=6
gen Zero =  0    if _n<=6
gen b=0
gen u=0
gen d=0
qui forv h = 0/4 {
xtreg lcpi`h' l(0/3).dlgdpr l(1/3).dlcpi l(1/3).dstir, fe cluster(iso)
replace b = _b[l.dstir]                     if _n == `h'+2
replace u = _b[l.dstir] + 1.645* _se[l.dstir]  if _n == `h'+2
replace d = _b[l.dstir] - 1.645* _se[l.dstir]  if _n == `h'+2
eststo 
}
nois esttab , se nocons keep(L.dstir)
twoway ///
		(rarea u d  Years,  ///
		fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
		(line b Years, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line Zero Years, lcolor(black)), legend(off) ///
		title("Response of CPI to 1pp shock to STIR (Cholesky)", color(black) size(medsmall)) ///
		ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
		graphregion(color(white)) plotregion(color(white))
		
		gr rename g_cpi , replace

** Real STIR to STIR (Note: l(0/3).dlgdpr and l(0/3).dlcpi in xtreg)
** Also note _n == `h'+1 and _b[dstir]

eststo clear
cap drop b u d Years Zero
gen Years = _n-1 if _n<=6
gen Zero =  0    if _n<=6
gen b=0
gen u=0
gen d=0
qui forv h = 0/4 {
xtreg stir`h' l(0/3).dlgdpr l(0/3).dlcpi l(0/3).dstir, fe cluster(iso)
replace b = _b[dstir]                     if _n == `h'+1
replace u = _b[dstir] + 1.645* _se[dstir]  if _n == `h'+1
replace d = _b[dstir] - 1.645* _se[dstir]  if _n == `h'+1
eststo 
}
nois esttab , se nocons keep(dstir)
twoway ///
		(rarea u d  Years,  ///
		fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
		(line b Years, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line Zero Years, lcolor(black)), legend(off) ///
		title("Response of STIR to 1pp shock to STIR (Cholesky)", color(black) size(medsmall)) ///
		ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
		graphregion(color(white)) plotregion(color(white))
		
		gr rename g_stir , replace

gr combine g_gdpr g_cpi g_stir, cols(1)
gr rename g_all1, replace


*****************************************************
* Repeat exercise with LP.ado file
* Be sure to load into your personal ado directory
* See instructions here: 
* https://www.stata.com/support/faqs/programming/personal-ado-directory/

* Generate lags
foreach x in dlgdpr dlcpi dstir {
forv h = 1/5 {
gen `x'`h' = l`h'.`x'		
}
}

* Define local with controls

local controls dlgdpr1 dlgdpr2 dlgdpr3 dlcpi1 dlcpi2 dlcpi3 dstir2 dstir3		

lp dlgdpr, hor(5) lags(3)				///
	cholesky							///
	///ydiff							/// Use for cumulative but use level
	shock(dstir1)						///
	other(`controls')				/// Easier to know what are the controls
	fe 									///
	cluster(iso)						///
	graph								///
	print								
	
	gr rename g2_gdpr , replace
	
lp dlcpi, hor(5) lags(3)				///
	cholesky							///
	///ydiff							/// Use for cumulative but use level here
	shock(dstir1)						///
	other(`controls' dlgdpr)		/// Easier to know what are the controls
	fe 									///
	cluster(iso)						///
	graph								///
	print								
	
	gr rename g2_dlcpi , replace

lp dstir, hor(5) lags(3)				///
	cholesky							///
	///ydiff							/// Use for cumulative but use level here
	shock(stir)						///
	other(`controls' dlgdpr dlcpi lstir)		/// Easier to know what are the controls
	///noylags								///
	fe 									///
	cluster(iso)						///
	graph								///
	print								
	
	gr rename g2_dstir , replace	

gr combine g2_gdpr g2_dlcpi g2_dstir, cols(1)
gr rename g_all2, replace

gr combine g_all1 g_all2
gr rename g_all, replace


