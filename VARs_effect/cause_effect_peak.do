import delimited "JSTdatasetR4.csv", encoding(UTF-8) clear


// Part1 : Compute business cycle peaks (Table 1)

// Note that for real gdp, they used rgdppc, not rgdpmad.

levelsof country, local(country_list)

foreach countryi of local country_list {

	import delimited "JSTdatasetR4.csv", encoding(UTF-8) clear
	qui keep if country=="`countryi'"
	qui gen peaks_w_crisis_country=0

	qui gen peaks_country=.
	
	local num_total=`=_N'-1
	forvalues i=1/`num_total'{
	
		if (`i'==1){
			if (rgdppc[`i']>rgdppc[`i'+1]){
				qui replace peaks_country=1 in 1
				
				local k=`i'+1
				
				while(1){
					if (rgdppc[`k']<rgdppc[`k'+1]){
					
						forvalues i_jud=`i'/`k'{
							if (crisisjst[`i_jud']==1) {
							qui replace peaks_w_crisis_country=1 in `i'
							}
							else {
							continue
							}
						}	
						continue,break
					} //end if
					local k=`k'+1
				} //end while	
			} 
			else{
			qui replace peaks_country=0 in 1
			}
		} //end if (`i'==1)		

		//-----------------------------------------------------------------
		
		else if ((rgdppc[`i']>rgdppc[`i'-1])&(rgdppc[`i']>rgdppc[`i'+1])){
			qui replace peaks_country=1 in `i'
			local k=`i'+1
			while(1){
				if rgdppc[`k']<rgdppc[`k'+1]{
					forvalues i_jud=`i'/`k'{
						if (crisisjst[`i_jud']==1) {
						qui replace peaks_w_crisis_country=1 in `i'
						}
						else {
						continue
						}
					}
					continue,break
				}
				local k=`k'+1
			} //end while
		} // end else if
		
		//-----------------------------------------------------------------
		else {
			qui replace peaks_country=0 in `i'
		}
	} // end 1->N-1		
	
	qui replace peaks_country=0 in `=_N'
	qui save "temp/`countryi'_crisis_peak.dta", replace
	
} // end for country	

// Merge all files
local files : dir "temp" files "*_crisis_peak.dta"
use "temp/Australia_crisis_peak.dta",clear
foreach f of local files{
	qui append using "temp/`f'"
}
duplicates drop
rename peaks_country peak
rename peaks_w_crisis_country peak_crisis

// Compute excess credit 
//Computing mean credit growth for a country: calculate the mean annual growth in the ratio total loans to gdp, excluding the war years.

//Computing excess credit: for each recession, calculate the mean credit growth of the years spanning the expansion phase (including the trough and peak years), then subtract the mean credit growth for that country. If there are any NA values for credit growth in the expansion phase, we set excess credit to be NA.


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


save "JSTdatasetR4_temp.dta",replace
use "JSTdatasetR4_temp.dta",clear

// Part 2: Create ratio, ratio growth variables

levelsof country, local(country_list)


foreach countryi of local country_list {
	use "JSTdatasetR4_temp.dta",clear
	keep if country=="`countryi'"

	qui gen ratios_country=.
	qui gen ratios_growth_country=.
	
	forvalues i=1/`=_N'{
		if (year[`i']>=1914&year[`i']<=1918)|(year[`i']>=1939&year[`i']<=1945){
			continue
			}
		qui replace ratios_country=tloans[`i']/gdp[`i'] in `i'
		
		if (`i'~=1){
		qui replace ratios_growth_country=(ratios_country[`i']-ratios_country[`i'-1])/ratios_country[`i'-1]*100 in `i'
		}
	}
	
	qui save "temp/`countryi'_ratio.dta", replace
}


// Merge all temp ratio data
local files : dir "temp" files "*_ratio.dta"
use "temp/Australia_ratio.dta",clear
foreach f of local files{
	append using "temp/`f'"
}
duplicates drop
rename ratios_country ltgdp_ratio
rename ratios_growth_country ltgdp_growth

//--------------------------------------------------------------------------------------------------

save "JSTdatasetR4_temp.dta",replace

//Part 3: Create excess credit variable
use "JSTdatasetR4_temp.dta",clear

levelsof country, local(country_list)

foreach countryi of local country_list{
	use "JSTdatasetR4_temp.dta",clear
	cap gen excess_credit=.
	keep if country=="`countryi'"
	// find mean credit growth for country
	// remove NA
	
	local mean_n=0
	local mean_sum=0
	forvalues meani=1/`=_N'{
		if ~(year[`meani']>=1914 & year[`meani']<=1918) & ~(year[`meani']>=1939 & year[`meani']<=1945) & (ltgdp_growth[`meani']~=.){
			local mean_sum=ltgdp_growth[`meani']+`mean_sum'
			local mean_n=1+`mean_n'
		}
	}
	
	
	local mean_credit_growth=`mean_sum'/`mean_n'
	
	mat peak_indices=[0]
	
	// save peak indices
	forvalues peaki=1/`=_N'{
		if (peak[`peaki']==1){
			// di `peaki'
			//local compose_index=colsof(peak_indices)
			//if `compose_index'=={
			//	mat peak_indices=[`peaki']
			//}
			//else{
			mat peak_indices=[peak_indices,`peaki']
			//}
		}
	} //end save index
	
	//mat l peak_indices
	
	
	local cols_peak=colsof(peak_indices)
	
	forvalues indexi=2/`cols_peak'{
		local index=peak_indices[1,`indexi']
		
		if `index'~=1{
			local k=`index'-1
		}
		else{
			local k=1
		}
		
		while(1){
			if (`k'==1|year[`k']==1918|year[`k']==1945|rgdppc[`k']<rgdppc[`k'-1]){
			
				//di `index'
				//di `k'
				// trough
				// mean
				local ltgdp_growth_before_sum=0
				local ltgdp_growth_before_n=0
				forvalues beforei=`k'/`index'{
					//if ltgdp_growth[`beforei']~=.{
					local ltgdp_growth_before_sum=ltgdp_growth[`beforei']+`ltgdp_growth_before_sum'
					local ltgdp_growth_before_n=1+`ltgdp_growth_before_n'
					//}
				} //end mean
				
				local ltgdp_growth_before_mean=`ltgdp_growth_before_sum'/`ltgdp_growth_before_n'
				
				//di "ltgdp_growth_before_mean"
				//di `ltgdp_growth_before_mean'
				//di "mean_credit_growth"
				//di `mean_credit_growth'
				
				replace excess_credit=`ltgdp_growth_before_mean'-`mean_credit_growth' in `index'
				
				
				
				continue,break
			}
			local k=`k'-1
		} //end while
		
	} //end index peak
	save "temp/`countryi'_credit_excess.dta",replace
	
} // end country_list

//merge all data

local files : dir "temp" files "*_credit_excess.dta"
use "temp/Australia_credit_excess.dta",clear
foreach f of local files{
	append using "temp/`f'"
}
duplicates drop
save "JSTdatasetR4_temp.dta",replace


//------------------------------------------------------------------------------------------------------------------------------------------------------

// Part 4: Table 4: Unconditional recession paths, normal vs. financial Bins
use "JSTdatasetR4_temp.dta",clear

mat coefs=J(2,5,0)

forvalues h=1/5{
	use "JSTdatasetR4_temp.dta",clear
	mat data=[.,.]
	mat peak_indices=[0]
	
	// save peak indices
	forvalues peaki=2/`=_N'{
		if (peak[`peaki']==1){
			mat peak_indices=[peak_indices,`peaki']
		}
	} //end save index
	
	// mat l peak_indices
	local cols_peak=colsof(peak_indices)
	
	forvalues compose_regii=2/`cols_peak'{
		local compose_regi=peak_indices[1,`compose_regii']
		
		if ((year[`compose_regi']>=1909&year[`compose_regi']<=1920)|(year[`compose_regi']>=1934&year[`compose_regi']<=1947)|(year[`compose_regi']+`h'>2016)) {
			continue
		}
		
		else{
			local diff_gdp=(log(rgdppc[`compose_regi'+`h'])-log(rgdppc[`compose_regi']))*100
			mat data=[data \ (`diff_gdp',peak_crisis[`compose_regi'])]
			
		}
		
	} // end forvalues compose_regi
	clear
	qui svmat data
	qui drop in 1
	qui gen data3=1-data2
	qui reg data1 data2 data3, noconstant
	mat coefs[1,`h']=_b[data3]
	mat coefs[2,`h']=_b[data2]	
} // for h

// mat l coefs

//---------------------------------------------------------------------------------------------------------------------


// Table 5: Unconditional recession paths, normal vs. financial bins split into excess credit terciles
use "JSTdatasetR4_temp.dta",clear
keep if peak_crisis==1&excess_credit~=.
sort excess_credit
//cumul excess_credit,gen(k)

_pctile excess_credit, percentiles(33(33)100)

local q1=r(r1)
local q2=r(r2)
local q3=r(r3)

use "JSTdatasetR4_temp.dta",clear


mat coefs=J(4,5,0)


forvalues h=1/5{
	
	use "JSTdatasetR4_temp.dta",clear
	
	mat data=[.,.,.,.,.]

	mat peak_indices=[0]
	
	// save peak indices
	forvalues peaki=2/`=_N'{
		if (peak[`peaki']==1){
			mat peak_indices=[peak_indices,`peaki']
		}
	} //end save index
	
	// mat l peak_indices
	local cols_peak=colsof(peak_indices)
	
	forvalues peakii=1/`cols_peak'{
		local peaki=peak_indices[1,`peakii']
		
		if (year[`peaki']>=1909&year[`peaki']<=1920)|(year[`peaki']>=1934&year[`peaki']<=1947)|(year[`peaki']+`h'>2016){
			continue
		}
		if (peak_crisis[`peaki']==1)&(excess_credit[`peaki']==.){
			continue
		}
		mat tercile=[0,0,0]
		if (peak_crisis[`peaki']==1){
			if excess_credit[`peaki']<=`q1'{
				mat tercile=[1,0,0]
			}
			else if excess_credit[`peaki']<=`q2'{
				mat tercile=[0,1,0]
			}
			else{
				mat tercile=[0,0,1]
			}
		} //end if peak_crisis
		
		local diff_gdp=(log(rgdppc[`peaki'+`h'])-log(rgdppc[`peaki']))*100
		mat data=[data \ (`diff_gdp',1-peak_crisis[`peaki'],tercile)]
		
	
	} // end for peaks_indices
	
	clear
	svmat data
	drop if data1==.
	
	qui reg data1 data2 data3 data4 data5, noconstant
	
	mat coefs[1,`h']=_b[data2]
	mat coefs[2,`h']=_b[data3]
	mat coefs[3,`h']=_b[data4]
	mat coefs[4,`h']=_b[data5]
	
	
} // end h

// mat l coefs

//-----------------------------------------------------------------------------------------------------------------------------------

// Table 6: Normal v. financial Bins with excess credit as a continuous treatment in each bin

use "JSTdatasetR4_temp.dta",clear
local n_mean_sum=0
local n_mean_n=0
local f_mean_sum=0
local f_mean_n=0
forvalues i=1/`=_N'{
	if (excess_credit[`i']~=.&peak_crisis[`i']==1){
		local n_mean_sum=`n_mean_sum'+excess_credit[`i']
		local n_mean_n=`n_mean_n'+1
	}
	if (excess_credit[`i']~=.&peak_crisis[`i']==0){
		local f_mean_sum=`f_mean_sum'+excess_credit[`i']
		local f_mean_n=`f_mean_n'+1
	}
}

local n_mean=`n_mean_sum'/`n_mean_n'
local f_mean=`f_mean_sum'/`f_mean_n'

mat coefs=J(4,5,0)

forvalues h=1/5{

	use "JSTdatasetR4_temp.dta",clear
	mat data=[.,.,.,.,.]
	mat peak_indices=[0]
	
	// save peak indices
	forvalues peaki=1/`=_N'{
		if (peak[`peaki']==1){
			mat peak_indices=[peak_indices,`peaki']
		}
	} //end save index
	
	// mat l peak_indices
	local cols_peak=colsof(peak_indices)
	
	forvalues peakii=2/`cols_peak'{
		local peaki=peak_indices[1,`peakii']
		if ((year[`peaki']>=1909&year[`peaki']<=1920)|(year[`peaki']>=1934&year[`peaki']<=1947)|year[`peaki']+`h'>2016) {
			continue
		}
		if (excess_credit[`peaki']==.) {
			continue
		}
		if (peak_crisis[`peaki']==1) {
			mat credit=[0,excess_credit[`peaki']-`f_mean']
		}
		else {
			mat credit=[excess_credit[`peaki']-`n_mean',0]
		}
		local diff_gdp=(log(rgdppc[`peaki'+`h'])-log(rgdppc[`peaki']))*100
		mat data=[data\ (`diff_gdp',1-peak_crisis[`peaki'],peak_crisis[`peaki'],credit)]
	}
	clear
	svmat data
	drop if data1==.
	qui reg data1 data2 data3 data4 data5, noconstant
	mat coefs[1,`h']=_b[data2]
	mat coefs[2,`h']=_b[data3]
	mat coefs[3,`h']=_b[data4]
	mat coefs[4,`h']=_b[data5]

} //end for h

mat l coefs


use "JSTdatasetR4_temp.dta",clear
// Part 7: Local projections
* 1. growth rate of real GDP per capita
* 2. growth rate of real loans per capita
* 4. short term interest rates on govt. securities (stir)
* 5. long term interest rte on govt. securities (ltrate)
* 6. investment to GDP ratio (iy)
cap gen rloans=tloans/cpi
cap gen current_to_gdp=ca/gdp

cap gen countries=""
cap gen countries_indices=.
levelsof country,local(country_list)
local i_con=1
foreach countryi of local country_list{
	qui replace countries="`countryi'" in `i_con'
	qui replace countries_indices=`i_con' in `i_con'
	local i_con=`i_con'+1
}
local n_con=`i_con'-1

save "JSTdatasetR4_temp.dta",replace

mat coefs=J(2,5,0)

forvalues h=1/5{

	use "JSTdatasetR4_temp.dta",clear
	mat peak_indices=[0]
	
	mat data=J(1,34,.)
	local merge_data=0
	
	// save peak indices
	forvalues peaki=1/`=_N'{
		if (peak[`peaki']==1){
			mat peak_indices=[peak_indices,`peaki']
		}
	} //end save index
	
	// mat l peak_indices
	local cols_peak=colsof(peak_indices)
	
	forvalues peakii=2/`cols_peak'{
		
		local peaki=peak_indices[1,`peakii']
		
		if ((year[`peaki']>=1909&year[`peaki']<=1920)|(year[`peaki']>=1934&year[`peaki']<=1947)|(year[`peaki']+`h'>2016)|(year[`peaki']-2<1870)){
			continue
		}
		
		if ((rgdppc[`peaki'-2]==.)|(rgdppc[`peaki'-1]==.)|(rgdppc[`peaki']==.)|(rloans[`peaki'-2]==.)|(rloans[`peaki'-1]==.)|(rloans[`peaki']==.)|(stir[`peaki'-1]==.)|(stir[`peaki']==.)|(ltrate[`peaki'-1]==.)|(ltrate[`peaki']==.)|(iy[`peaki'-1]==.)|(iy[`peaki']==.)|(current_to_gdp[`peaki'-1]==.)|(current_to_gdp[`peaki']==.)){
			continue
		}
		
		
		mat gdp_growth=[100*(log(rgdppc[`peaki'-1])-log(rgdppc[`peaki'-2])),100*(log(rgdppc[`peaki'])-log(rgdppc[`peaki'-1]))]
		mat rloans_growth=[100*(log(rloans[`peaki'-1])-log(rloans[`peaki'-2])),100*(log(rloans[`peaki'])-log(rloans[`peaki'-1]))]
		mat cpi=[cpi[`peaki'-1],cpi[`peaki']]
		
		mat rates=[stir[`peaki'-1], stir[`peaki'], ltrate[`peaki'-1], ltrate[`peaki']]
		mat itogdp=[iy[`peaki'-1], iy[`peaki']]
		mat ctogdp=[current_to_gdp[`peaki'-1], current_to_gdp[`peaki']]
		mat fixed_effects=J(1,`n_con',0)
		
		// Find country
		local country_index=0
		forvalues country_find=1/`n_con'{
			if (countries[`country_find']==country[`peaki']){
				local country_index=countries_indices[`country_find']
				continue,break
			}
			else{
				continue
			}
		}
		
		mat fixed_effects[1,`country_index']=1
		
		//mat l fixed_effects
		
		mat controls =[gdp_growth,rloans_growth,cpi,rates,itogdp,ctogdp]
		
		//mat l controls
		
		local diff_gdp=100* (log(rgdppc[`peaki'+`h'])-log(rgdppc[`peaki']))
		
		//mat line_data=[`diff_gdp',1-peak_crisis[`peaki'],peak_crisis[`peaki'],controls,fixed_effects]
		
		//matrix colnames line_data=c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14 c15 c16 c17 c18 c19 c20 c21 c22 c23 c24 c25 c26 c27 c28 c29 c30 c31 c32 c33 c34
		
		// mat l line_data
		
		
		mat data_local=[`diff_gdp',1-peak_crisis[`peaki'],peak_crisis[`peaki'],controls,fixed_effects]
		//mat l data_local
		if `merge_data'==0{
			mat data=data_local
			//di "First"
			//mat l data
			local merge_data=1
		}
		else{
			//di "Second"
			mat data=[data\data_local]
			//mat l data
		}	
		
	} // endvalues peakii
	
	
	clear
	svmat data
	qui reg data1 data2-data34, noconstant
	mat coefs[1,`h']=_b[data2]
	mat coefs[2,`h']=_b[data3]
}

mat l coefs
