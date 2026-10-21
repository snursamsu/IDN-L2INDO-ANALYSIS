/*==============================================================================
  L2Indo Incomes → Individual Merge — Do-file 3 of 3
  
  PURPOSE:
  Merges the HH-level per capita income (pc_inc_real_spadef) back into the 
  individual-level file. This resolves the circular dependency: incomes are 
  constructed in the HH do-file (2-household.do) but needed at individual 
  level for employment/income analysis.
  
  RUN ORDER:
  0-weights.do → 1-individual.do → 2-household.do → THIS FILE
  
  INPUTS:
  - "$source/Anon_IND_L2Indo_Analysisfile.dta"  (from 1-individual.do)
  - "$out/incomes_temp.dta"                      (from 2-household.do)
  
  OUTPUTS:
  - "$source/Anon_IND_L2Indo_Analysisfile.dta"   (updated with income vars)
==============================================================================*/

	clear all
	set more off
	cap log close

/*----------------------------------------------------------------------
  1. SETUP
----------------------------------------------------------------------*/

	local rnd 31
	local mofdloc 800 /// September 2026
    
	local suser = upper(c(username))
	* Will
	if ("`suser'" == "WB454594") {
		global root "C:\Users\WB454594\OneDrive - WBG\Indonesia\Listening to Indonesia"
		global in "$root\Data\Clean"
		global out "$root\L2Indo Team Folder\Analysis"
		global source "$root\L2Indo Team Folder\Team Data"
	}
	* Sam 
	else if ("`suser'" == "WB594719") {
		global root "C:\Users\wb594719\OneDrive - WBG\Listening to Indonesia"
        global in "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Cleaned data"
        global out "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Main data"
        global source "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Main data" 
		global dlog "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Log"
	}

	log using "$dlog/3-incomes-to-ind-R`rnd'.smcl", replace


/*----------------------------------------------------------------------
  2. MERGE INCOME DATA INTO INDIVIDUAL FILE
----------------------------------------------------------------------*/

	use "$source/Anon_IND_L2Indo_Analysisfile_R`rnd'.dta", clear
	
    cap drop pc_inc_real_spadef ln_pc_inc mean_pc_inc pc_inc_dev pc_inc_change pc_inc_vol pc_inc_real_spadef_sd mean_totfoodinsec dev_totfoodinsec totfoodinsec_change totfoodinsec_vol totfoodinsec_sd_rolling selfemp_lag agemp_lag govemp_lag empstart ind_work_lag churn
    
	merge m:1 hhid mofd using "$temp/incomes_temp.dta"
	drop if _m==2
	
	count if _m==1
	if r(N) > 0 {
		di as text "NOTE: `r(N)' individual obs without HH income data"
	}
	drop _m
	cap drop dupid

	la var pc_inc_real_spadef "Real spatially deflated per capita income (from HH file)"


/*----------------------------------------------------------------------
  3. CONSTRUCT INCOME-DEPENDENT INDIVIDUAL VARIABLES
----------------------------------------------------------------------*/

// Log income
	g ln_pc_inc = ln(pc_inc_real_spadef)
	la var ln_pc_inc "Log real spatially deflated pc income"

// Income volatility measures
	xtset uniqueid round
	
	egen mean_pc_inc = mean(pc_inc_real_spadef), by(hhid)
	la var mean_pc_inc "HH mean real spatially deflated pc income (all rounds)"
	gen pc_inc_dev = abs(pc_inc_real_spadef - mean_pc_inc)
	la var pc_inc_dev "Absolute deviation of pc income from HH mean"
	gen pc_inc_change = pc_inc_real_spadef - L.pc_inc_real_spadef
	la var pc_inc_change "Month-on-month change in real pc income"
	gen pc_inc_vol = pc_inc_change^2
	la var pc_inc_vol "Squared change in real pc income (volatility)"
	
	rangestat (sd) pc_inc_real_spadef, interval(mofd -3 0) by(hhid)
	la var pc_inc_real_spadef_sd "Rolling 3-month SD of real pc income"

// Food insecurity volatility (requires totfoodinsec from individual file)
	egen mean_totfoodinsec = mean(totfoodinsec), by(hhid)
	la var mean_totfoodinsec "HH mean food insecurity count (all rounds)"
	gen dev_totfoodinsec = abs(totfoodinsec - mean_totfoodinsec)
	la var dev_totfoodinsec "Absolute deviation of food insecurity from HH mean"
	gen totfoodinsec_change = totfoodinsec - L.totfoodinsec
	la var totfoodinsec_change "Month-on-month change in food insecurity count"
	gen totfoodinsec_vol = totfoodinsec_change^2
	la var totfoodinsec_vol "Squared change in food insecurity (volatility)"
	rangestat (sd) totfoodinsec, interval(mofd -3 0) by(hhid)
	rename totfoodinsec_sd totfoodinsec_sd_rolling
	la var totfoodinsec_sd_rolling "Rolling 3-month SD of food insecurity"

// Employment churning (requires panel structure)
	g selfemp_lag = L.self_emp_any
	la var selfemp_lag "Lagged self-employment status"
	g agemp_lag = L.ag_work_dum
	la var agemp_lag "Lagged agricultural employment status"
	g govemp_lag = L.gov_emp
	la var govemp_lag "Lagged government employment status"
	g empstart = .
	replace empstart = 1 if ind_work==1 & round==1
	sort uniqueid round
	bysort uniqueid (mofd): replace empstart = empstart[_n-1] if empstart==.
	la var empstart "Was employed in round 1"
	xtset uniqueid round
	g ind_work_lag = L.ind_work
	la var ind_work_lag "Lagged individual employment status"
	g churn = ind_work != ind_work_lag
	la var churn "Employment status changed from previous month"


/*----------------------------------------------------------------------
  4. SAVE UPDATED INDIVIDUAL FILE
----------------------------------------------------------------------*/

	save "$source/Anon_IND_L2Indo_Analysisfile_R`rnd'.dta", replace

	di as result "Individual file updated with income and volatility variables."
	log close

