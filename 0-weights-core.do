/*==============================================================================
  L2Indo Panel Weights — Standalone Do-file for Two Baselines
  Created by Samuel Nursamsu
  Last modified October 9, 2026
  Last round: 31
  *--------------------------------------
  
  PURPOSE:
  Creates monthly panel weights (popw, indw) for the L2Indo survey by:
  1. Building household-level baseline characteristics from the roster
  2. Running entropy balancing (ebalance) separately for each baseline
  3. Scaling within each baseline to province population totals
  4. Combining both baselines with proportional scaling so the total 
     weighted population is stable across rounds
  
  CHANGELOG:
  September 29, 2026
  - Fixing section 11 from 50 - 50 split between baseline 1 and 2 sample
    to Proportional split according to share of sample in each period
==============================================================================*/

	clear all
	set more off
    cap log close

/*----------------------------------------------------------------------
  1. SETUP — Locals and Globals
----------------------------------------------------------------------*/

	local rnd 31
	local mofdloc 800 		// September 2026
	
	// TODO: set this to the first round B2 households were interviewed
	local b2_first_round 18	 // <-- adjust as needed

	local suser = upper(c(username))
	
	* Will
	if ("`suser'" == "WB454594") {
		global root "C:\Users\WB454594\OneDrive - WBG\Indonesia\Listening to Indonesia"
	}
	* Sam 
	else if ("`suser'" == "WB594719") {
        global root "C:\Users\wb594719\OneDrive - WBG\Listening to Indonesia"
        global base "$root\Data\Baseline"
        global base2 "$root\Data\Baseline II Confidential\Data\dta"
        global samp "$root\L2Indo Launch Materials\Sample"
        global gdat "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents"
        global in "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Cleaned data"
        global out "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Main data"
        global temp "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Temp"
        global dlog "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Log"
	}
	
    log using "$dlog/0-weights@R`rnd'.smcl", replace

/*----------------------------------------------------------------------
  2. LOAD SAMPLE FILES (stratification info)
----------------------------------------------------------------------*/

	// Baseline 1 sample
	use "$samp/L2Indo_sample@2.dta", clear
	keep hhid microbus
	g baseline = 1
    destring hhid, replace
	tempfile samp_b1
	save `samp_b1'
	
	// Baseline 2 sample — microbus from M1B7
	use "$base2/Module1MainData.dta", clear
    g microbus = m1b7==1
    /* IMPORTANT ADDITION: to ensure we get who got tested for blood lead,
        lead test kit, and air quality monitoring */
    g bll_id    = m1b11==1
    g tkit_id   = m1b12==1
    g aqm_id    = m1b10==1    
    keep hhid microbus bll_id tkit_id aqm_id
    * FIX HHID HERE FOR SECOND BASELINE
    rename hhid hhid2
    g hhid = "825" + hhid2
    destring hhid, replace
    order hhid, first
    
	g baseline = 2
    
    tempfile samp_b2
	save `samp_b2'
	
    // Combine
	append using `samp_b1'
	tempfile samp
	save `samp'


/*----------------------------------------------------------------------
  3. LOAD BASELINE INDIVIDUAL DATA (both baselines)
  
  We only need the variables that feed into the ebalance covariates:
  - gender (m1c_4) → to create `female'
  - disability (m1c_16a-f) → to create `disability'
  The roster provides hhsize, and the weights/welfare files provide 
  the rest (popw, pc_def_inc, microbus, province_id).
----------------------------------------------------------------------*/

* Baseline 1 individuals
*-----------------------
	use "$base/M1_C1.dta", clear
	destring hhid, replace
	rename m1c_1 pid
	g baseline = 1
    
    * Baseline 1 variables construction
    *----------------------------------	
	// Female indicator
	g female = 0
	replace female = 1 if m1c_4 == 3
	
	// Disability indicator
	g disability = 0
        replace disability = . if m1c_16b == .
	loc disvars a b c d e f 
	foreach i of loc disvars {
		replace disability = 1 if m1c_16`i' == 3
		replace disability = 1 if m1c_16`i' == 4
	}
    
    // education indicator
    ren m1c_10a sch_highest_attend
        la var sch_highest_attend "Highest level of school attended"    
    
    // migration
    gen sameloc5 = m1c_7a_x 
    la var sameloc5 "Same location as 5 years ago"    
    
    // Age group (decade bins)
    g age = m1c_5a
    forvalues i = 1/5 {
        label define age_group `i' "`=10*`i'' - `=10*`i' + 9'", add
    }
    label define age_group 6 "60 +", add
    gen int age_group:age_group = min(floor(age/10), 6)
    replace age_group = . if age_group <= 0
    la var age_group "Age group (decade bins)"    
    
    * save baseline 1 individual
    *---------------------------
    keep hhid pid baseline female disability sch_highest_attend sameloc5 age_group
	tempfile indbase_b1
	save `indbase_b1'
	
* Baseline 2 individuals
*-----------------------
    use "$base2/Module1IndivInfo.dta", clear   
    rename m1c1_pid pid
    * to merge with adjusted hhid for panel
    rename hhid hhid2
    merge m:1 hhid2 using `samp_b2'
        drop _m
    order hhid, first
    
    * Baseline 2 variables construction
    *----------------------------------
    // Female indicator
	g female = m1c4==2
	
	// Disability indicator
	g disability = 0
        replace disability = . if m1c16b == .    
	loc disvars a b c d e f 
	foreach i of loc disvars {
		replace disability = 1 if m1c16`i' == 3
		replace disability = 1 if m1c16`i' == 4
	}
    
    // education indicator
    ren m1c10 sch_highest_attend
        la var sch_highest_attend "Highest level of school attended"        
    
    // migration
    gen sameloc5 = m1c7_option 
    replace sameloc5 = 6 if sameloc5==95
    la var sameloc5 "Same location as 5 years ago"      

    // Age group (decade bins)
    g age = m1c5a
    destring age, replace
    forvalues i = 1/5 {
        label define age_group `i' "`=10*`i'' - `=10*`i' + 9'", add
    }
    label define age_group 6 "60 +", add
    gen int age_group:age_group = min(floor(age/10), 6)
    replace age_group = . if age_group <= 0
    la var age_group "Age group (decade bins)"    
    
    * save baseline 2 individual
    *---------------------------
    keep hhid pid baseline female disability sch_highest_attend sameloc5 age_group
    tempfile indbase_b2
    save `indbase_b2'
	
* Combine baseline 1 and 2
*-------------------------
	append using `indbase_b1'
	tempfile indbase
	save `indbase'

/*----------------------------------------------------------------------
  4. LOAD WEIGHTS AND WELFARE (both baselines)
----------------------------------------------------------------------*/

* Weights
*--------
	// B1 weights
	use "$base\Adjusted_Weights@1.dta", clear
    destring hhid, replace
    merge 1:1 hhid using `samp_b1',keepusing(microbus)
        drop _m
	g baseline = 1
	tempfile wt_b1
	save `wt_b1'
	
	// B2 weights
	use "$base2\Adjusted_Weights@1.dta", clear
    * to merge with adjusted hhid for panel
    rename hhid hhid2
    merge 1:1 hhid2 using `samp_b2'
        drop _m
    drop hhid2
    order hhid, first    
	tempfile wt_b2
    save `wt_b2'
	// Combine weights
	append using `wt_b1'
	
	* Save combined weights
    *----------------------
	tempfile weights
	save `weights'
	
* Welfare
*--------
	// B1 welfare
	use "$base\base_welfare@1.dta", clear
    destring hhid, replace
	tempfile welf_b1
	save `welf_b1'
	
	// B2 welfare
	use "$base2\base_welfare@1.dta", clear		
	* adjust hhid back to string with leading zeros
    g hhid2 = string(hhid, "%05.0f")
    drop hhid
    * take air quality monitor id, bll id, and test kit id
    merge 1:1 hhid2 using `samp_b2'
    drop _m
    order hhid, first
    tempfile welf_b2
    save `welf_b2'
    
	// Combine welfare
	append using `welf_b1'
	tempfile welfare
	save `welfare'


/*----------------------------------------------------------------------
  5. BUILD ROSTER + BASELINE CHARACTERISTICS
  
  This merges the monthly panel roster with baseline individual data 
  to get gender and disability, then merges with weights and welfare.
  The roster already contains both B1 and B2 households.
----------------------------------------------------------------------*/

	// Load monthly roster
	use "$in/l2indo_M01_roster.dta", clear
	drop name
	rename fmid pid
    
    // drop if more than initial rounds (can happen if late submission)
    drop if mofd>`mofdloc'
    
    // Household size from panel survey (present members)
	g hhsize_temp = residing==1
	bys hhid mofd: egen hhsize = total(hhsize_temp)
	drop hhsize_temp

	// Merge baseline individual data (both B1 and B2)
    merge m:1 hhid pid using `indbase', keepusing(female disability sch_highest_attend sameloc5 age_group)
	rename _m roster_merge
	
	// Merge weights (popw, hhweight, province_id, microbus)
	merge m:1 hhid using `weights'
	drop if _m == 2
	drop _m
	
	// Merge welfare (pc_def_inc)
	merge m:1 hhid using `welfare', keepusing(province province_id district district_id bps_code pc_def_inc)
	drop if _m == 2
	drop _m
	
	// Create weight variables
	g base_indweight = popw / hhsize
	ren popw base_popw
	ren hhweight base_hhweight
	ren pc_def_inc base_pc_def_inc
	
    *----------------------------------------
    * Create derived variables
    *----------------------------------------
    
    // School (harmonized education level)
    g school = .
    replace school = 1 if inlist(sch_highest_attend,1,2)
    replace school = 2 if inlist(sch_highest_attend,4,5)
    replace school = 3 if inlist(sch_highest_attend,7,8,9,10)
    replace school = 4 if inlist(sch_highest_attend,11,12,13)
    label define school 1 "primary" 2 "junior secondary" 3 "senior secondary" 4 "tertiary"
    label values school school
    la var school "Harmonized levels of school attended"
    
    // Age group for employment
    g age_group_emp = age_group
    replace age_group_emp = . if age < 15
    la var age_group_emp "Age groups for employment analysis (15+)"

    // Migration status
    g mig = .
    replace mig = 0 if sameloc5 == 1
    replace mig = 0 if sameloc5 == 6
    replace mig = 1 if sameloc5 == 5
    la var mig "Migrant (lived in different location 5 years ago)"

    // Calendar month
    g month = month(date)
    la var month "Calendar month of interview"
    
    // Island grouping
    g island = .
    replace island = 1 if province_id >= 11 & province_id <= 21
    replace island = 2 if province_id >= 31 & province_id <= 51
    replace island = 3 if province_id >= 52 & province_id <= 53
    replace island = 4 if province_id >= 61 & province_id <= 65
    replace island = 5 if province_id >= 71 & province_id <= 76
    replace island = 6 if province_id >= 81 & province_id <= 94
    label define island 1 "Sumatera" 2 "Java-Bali" 3 "Nusa-tenggara" 4 "Kalimantan" 5 "Sulawesi" 6 "Maluku & Papua"
    label values island island
    la var island "Major island groups"

    // Baseline income decile
    cap confirm variable base_decil
    if _rc != 0 {
        xtile base_decil = base_pc_def_inc [aw=base_indweight], nq(10)
        la var base_decil "Baseline decile of spatially deflated pc income"
    }
    
	// Tag baseline for HHs that didn't get it from the merge
	// (B2 HHs should already have baseline==2 from the weights merge)
	
    save "$temp/l2indoroster_reweight@R`rnd'.dta", replace

    // Save individual-level base for merging do-files (NEED TO FIX, SO FAR USE FROM THE INITIAL FILE)
    preserve
        drop if round==.
        rename pid fmid
        save "$temp/L2IndoBase@R`rnd'", replace
    restore
    
/*----------------------------------------------------------------------
  6. CREATE REWEIGHT REFERENCE FILES (one per baseline)
  
  These represent the FULL baseline population — the target that 
  ebalance will try to match each round's respondents to.
  
  We only collapse the variables actually used by ebalance:
  female, disability (sum), base_pc_def_inc (mean), 
  hhsize, base_popw, microbus (max).
----------------------------------------------------------------------*/

	use "$temp/l2indoroster_reweight@R`rnd'.dta", clear
	bys hhid pid: keep if _n == 1
	
	collapse (sum) female disability ///
		(mean) base_pc_def_inc ///
		(max) hhsize base_popw base_hhweight microbus baseline round, ///
		by(hhid province_id)
	
	rename female hh_female
	rename disability hh_disability
	drop round
	
	// Save separately by baseline
	preserve
		keep if baseline == 1
		save "$temp\Reweightfile@1@R`rnd'.dta", replace
	restore
	preserve
		keep if baseline == 2
		save "$temp\Reweightfile@2@R`rnd'.dta", replace
	restore


/*----------------------------------------------------------------------
  7. CREATE PROVINCE SCALING FACTORS (one per baseline)
  
  These are the province-level population totals that each baseline's 
  weights will be scaled to match.
----------------------------------------------------------------------*/

	// B1 scaling factors
	use "$temp\Reweightfile@1@R`rnd'.dta", clear
	drop if province_id == .
	collapse (sum) base_popw, by(province_id)
	rename base_popw scale
	tempfile scale_b1
	save `scale_b1'
	
	// B2 scaling factors
	use "$temp\Reweightfile@2@R`rnd'.dta", clear
	drop if province_id == .
	collapse (sum) base_popw, by(province_id)
	rename base_popw scale
	tempfile scale_b2
	save `scale_b2'


/*----------------------------------------------------------------------
  8. CREATE HOUSEHOLD-LEVEL MONTHLY PANEL BASE
  
  Collapse the individual-level roster to household-month level.
  This tells us which households responded in which round.
----------------------------------------------------------------------*/

    use "$temp/l2indoroster_reweight@R`rnd'.dta", clear
	drop if roster_merge == 2

	collapse (sum) female disability ///
		(mean) base_pc_def_inc ///
		(max) hhsize base_popw base_hhweight microbus baseline round, ///
		by(hhid mofd province_id district_id)
	
	rename female hh_female
	rename disability hh_disability
	
	save "$temp\L2Indo_HHBase@R`rnd'", replace


/*----------------------------------------------------------------------
  9. ENTROPY BALANCING — BASELINE 1
  
  For each round, find weights that make responding B1 households 
  match the full B1 baseline population on:
  microbus, hhsize, base_pc_def_inc, hh_female, hh_disability, province
----------------------------------------------------------------------*/

	// Get passport data — which HHs responded when
	use "$in\l2indo_M00_passport.dta", clear
	bys hhid mofd: keep if _n == 1
	keep hhid mofd round
	
	// Merge with HH base to get baseline characteristics
	merge 1:1 mofd hhid using "$temp\L2Indo_HHBase@R`rnd'"
    drop if missing(baseline)               // drop here if doesn't merge anywhere, strange data
    save "$temp/0_weighting_passport_b1_b2@R`rnd'.dta", replace

	// --- B1 ebalance ---
	use "$temp/0_weighting_passport_b1_b2@R`rnd'.dta", clear
	keep if baseline == 1
	drop _m
	g base = 0
	
	// Append B1 reference population (the target)
	append using "$temp\Reweightfile@1@R`rnd'.dta"
	replace base = 1 if base == .
	
	// Ebalance: treat=1 is full baseline, treat=0 is round respondents
	g treat = .
	replace treat = 1 if base == 1
	
	g ad_weight = .
	
	forvalues i = 1/`rnd' {
		cap drop regweight`i'
		replace treat = 0 if round == `i'
		
		ebalance treat microbus hhsize base_pc_def_inc hh_female hh_disability ///
			i.province_id, gen(regweight`i')
		replace ad_weight = regweight`i' if regweight`i' != .
	}
	
	cap drop treat
	drop if base == 1
	
	// Apply adjustment and scale to province totals
	g popw = base_popw * ad_weight
	
	merge m:1 province_id using `scale_b1'
	drop if _m != 3
	drop _m
	
	bys province_id mofd: egen wetoscale = total(popw)
	replace popw = popw * (scale / wetoscale)
	drop wetoscale scale
	
	g indw = popw / hhsize
	
	keep hhid round mofd indw popw baseline
	
	tempfile pw_b1
	save `pw_b1'
    save "$temp/temp_weights_b1@R`rnd'.dta", replace    

/*----------------------------------------------------------------------
  10. ENTROPY BALANCING — BASELINE 2
  
  Same logic as B1, but only for rounds where B2 households are present.
----------------------------------------------------------------------*/

	use "$temp/0_weighting_passport_b1_b2@R`rnd'.dta", clear
	keep if baseline == 2
	drop _m
	g base = 0
	
	// Append B2 reference population
	append using "$temp\Reweightfile@2@R`rnd'.dta"
	replace base = 1 if base == .
	
	g treat = .
	replace treat = 1 if base == 1
	
	g ad_weight = .
	
    /* Slightly Different than baseline 2. 
       Drop hh_disability microbus since not enough sample */
	forvalues i = `b2_first_round'/`rnd' {
		cap drop regweight`i'
		replace treat = 0 if round == `i'
		
		cap ebalance treat microbus hhsize base_pc_def_inc hh_female ///
			i.province_id, gen(regweight`i')
		if _rc == 0 {
			replace ad_weight = regweight`i' if regweight`i' != .
		}
		else {
			di as text "Note: ebalance did not converge for round `i' (B2) — skipping"
		}
	}
	
	cap drop treat
	drop if base == 1
	
	// Apply adjustment and scale to province totals
	g popw = base_popw * ad_weight
	
	merge m:1 province_id using `scale_b2'
	drop if _m != 3
	drop _m
	
	bys province_id mofd: egen wetoscale = total(popw)
	replace popw = popw * (scale / wetoscale)
	drop wetoscale scale
	
	g indw = popw / hhsize
	
	keep hhid round mofd indw popw baseline
	
	tempfile pw_b2
	save `pw_b2'
    save "$temp/temp_weights_b2@R`rnd'.dta", replace

/*----------------------------------------------------------------------
  11. COMBINE AND SCALE ACROSS BASELINES — SAMPLE-SHARE APPROACH

  Both baselines represent the same national population independently.
  When combining, we scale each baseline's weights proportionally to
  its share of responding households in each round, so the combined
  weights sum to the national population once (not twice).

  APPROACH:
  In each round, compute:
    bl_share = n_responding_hh_from_this_baseline / n_total_responding_hh
  Then multiply each baseline's weights by its share.

  Example: round 22 has 1400 B1 HHs and 600 B2 HHs = 2000 total
    → B1 weights × (1400/2000) = × 0.70
    → B2 weights × ( 600/2000) = × 0.30

  This is more principled than a fixed phase-in schedule because:
  (1) Shares reflect actual sample retention — no arbitrary parameters
  (2) B2's contribution grows organically as its sample stabilises
  (3) Before B2 enters, B1 share = 1.0 automatically
  (4) If one baseline loses more HHs to attrition, its share declines
      naturally, giving more weight to the better-retained sample

  ADJUSTMENT: `b2_exclude_rounds' still lets you drop B2's very first
  round(s) when sample size is too small for reliable ebalance.
----------------------------------------------------------------------*/

	// Optional: exclude B2's first round (too few HHs for reliable ebalance)
	local b2_exclude_rounds 1
	local b2_entry_round = `b2_first_round' + `b2_exclude_rounds'

	di as text "--- Sample-share weighting ---"
	di as text "B2 first interviewed: round `b2_first_round'"
	di as text "B2 excluded: round(s) `b2_first_round' to `=`b2_entry_round'-1'"
	di as text "B2 enters combined weights: round `b2_entry_round'"
	di as text "Shares determined by responding sample size each round"
	di as text "------------------------------"

	use "$temp/temp_weights_b1@R`rnd'.dta", clear
	append using "$temp/temp_weights_b2@R`rnd'.dta"

	// Sanity: no household appears twice in the same month
	duplicates tag hhid mofd, g(_dup)
	assert _dup == 0
	drop _dup

	// Drop B2 observations from excluded early rounds
	drop if baseline == 2 & round < `b2_entry_round'

	// Count responding HHs per baseline per round
	bys mofd baseline: gen n_hh_bl = _N
	bys mofd:           gen n_hh_total = _N

	// Each baseline's share of the sample in that round
	g bl_share = n_hh_bl / n_hh_total
	la var bl_share "Baseline sample share for this round"

	// Apply shares to weights
	replace popw = popw * bl_share
	replace indw = indw * bl_share

	// Display sample counts and shares by round
	di as text ""
	di as text "--- Sample shares by round and baseline ---"
	table round baseline, stat(mean bl_share) stat(freq) nformat(%9.3f)

	// Verification: total weighted population should be stable across rounds
	bys mofd: egen total_popw = total(popw)
	di as text ""
	di as text "--- Total weighted population by round (should be roughly stable) ---"
	tab mofd, summarize(total_popw) nofreq

	drop n_hh_bl n_hh_total bl_share total_popw

	label var popw "Population weight (household level)"
	label var indw "Population weight (individual level)"
	label var baseline "Baseline sample (1=B1, 2=B2)"

	save "$in/PanelWeightALL@R`rnd'", replace

	di as text ""
	di as result "Panel weights saved: $in/PanelWeightALL@R`rnd'.dta"
	di as result "Covers `rnd' rounds, two baselines"
	di as result "B2 enters at round `b2_entry_round', shares by responding sample size"
	di as text ""

log close
