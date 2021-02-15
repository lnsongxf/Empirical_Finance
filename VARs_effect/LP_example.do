clear
graph drop _all
cap drop all
use "AED_INTERESTRATES.DTA"
describe
summarize

* Choose impulse response horizon
local hmax = 12

/* Generate LHS variables for the LPs */

* levels
forvalues h = 0/`hmax' {
	gen gs10_`h' = f`h'.gs10 
}

* differences
forvalues h = 0/`hmax' {
	gen gs10d`h' = f`h'.gs10 - l.f`h'.gs10 
}

* Cumulative
forvalues h = 0/`hmax' {
	gen gs10c`h' = f`h'.gs10 - l.gs10 
}

 
/* Run the LPs */
* Levels
eststo clear
cap drop b u d Years Zero
gen Years = _n-1 if _n<=`hmax'
gen Zero =  0    if _n<=`hmax'
gen b=0
gen u=0
gen d=0
forv h = 0/`hmax' {
	* levels
	 reg gs10_`h' l(0/4).gs1 l(1/3).gs10, vce(robust)
replace b = _b[gs1]                    if _n == `h'+1
replace u = _b[gs1] + 1.645* _se[gs1]  if _n == `h'+1
replace d = _b[gs1] - 1.645* _se[gs1]  if _n == `h'+1
eststo
}
* nois esttab , se nocons keep(gs1)
gen b_level = b

* Differences
eststo clear
cap drop b u d Years Zero
gen Years = _n-1 if _n<=`hmax'
gen Zero =  0    if _n<=`hmax'
gen b=0
gen u=0
gen d=0
forv h = 0/`hmax' {
	 reg gs10d`h' l(0/4).dgs1 l(1/3).dgs10, vce(robust)
replace b = _b[dgs1]                     if _n == `h'+1
replace u = _b[dgs1] + 1.645* _se[dgs1]  if _n == `h'+1
replace d = _b[dgs1] - 1.645* _se[dgs1]  if _n == `h'+1
eststo
}
* nois esttab , se nocons keep(dgs1)

twoway ///
(rarea u d  Years,  ///
fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) ///
lpattern(solid) lwidth(thick)) ///
(line Zero Years, lcolor(black)), legend(off) ///
title("Impulse response of GS10 to 1pp shock to GS1", color(black) size(medsmall)) ///
ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
graphregion(color(white)) plotregion(color(white))

gr rename fig_diff, replace

* Cumulative
eststo clear
cap drop b u d Years Zero
gen Years = _n-1 if _n<=`hmax'
gen Zero =  0    if _n<=`hmax'
gen b=0
gen u=0
gen d=0
forv h = 0/`hmax' {
	 reg gs10c`h' l(0/4).dgs1 l(1/3).dgs10, vce(robust)
replace b = _b[dgs1]                     if _n == `h'+1
replace u = _b[dgs1] + 1.645* _se[dgs1]  if _n == `h'+1
replace d = _b[dgs1] - 1.645* _se[dgs1]  if _n == `h'+1
eststo
}
* nois esttab , se nocons keep(dgs1)

twoway ///
(rarea u d  Years,  ///
fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) ///
(line b_level Years, lcolor(red) lpattern(dash) lwidth(vthick)) ///
(line Zero Years, lcolor(black)), legend(off) ///
title("Cumulative response of GS10 to 1pp shock to GS1", color(black) size(medsmall)) ///
subtitle("Levels on levels (solid blue) vs. Cumulative (dash red)", color(black) size(small)) ///
ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
graphregion(color(white)) plotregion(color(white))

gr rename fig_cum, replace

gr combine fig_diff fig_cum, ///
graphregion(color(white)) plotregion(color(white)) ///
title("Levels and cumulated impulse responses") ///
note("Note: 90% confidence bands displayed")

 
/* THE END */
