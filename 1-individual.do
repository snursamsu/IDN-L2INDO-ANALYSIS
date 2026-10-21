/*==============================================================================
  L2Indo Individual-Level Panel — Do-file 1 of 3
  
  PURPOSE:
  Builds the individual-level panel by merging base roster with weights,
  migration, employment, and wellbeing modules. Constructs individual-level
  analysis variables and runs individual-level analyses.
  
  INPUTS:
  - "$temp/L2IndoBase@R{rnd}.dta"          (from 0-weights)
  - "$in/PanelWeightALL@{rnd}.dta"      (from 0-weights)
  - Monthly modules: M03 (wellbeing), M04 (migration), M05 (activity), M08 (savings)
  
  OUTPUTS:
  - "$source/Anon_IND_L2Indo_Analysisfile.dta"
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
		global base "$root\Data\Baseline"
		global samp "$root\L2Indo Launch Materials\Sample"
		global in "$root\Data\Clean"
		global out "$root\L2Indo Team Folder\Analysis"
		global source "$root\L2Indo Team Folder\Team Data"
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
        global source "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Main data"        
        global temp "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Temp"
        global dlog "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Log"
	}

	log using "$dlog/1-individual.smcl", replace


/*----------------------------------------------------------------------
  2. CLEAN MODULES (deduplicate)
----------------------------------------------------------------------*/

	use "$in/l2indo_M03_wellbeing.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile wbclean
	save `wbclean'
	
	use "$in\l2indo_M04_migration.dta", clear 
	bys hhid fmid mofd: keep if _n==1
	tempfile migclean
	save `migclean'	
	
	use "$in\l2indo_M05_activity.dta", clear 
	bys hhid fmid mofd: keep if _n==1
	tempfile actclean
	save `actclean'	

// New bank account opening
	use "$in\l2indo_M08_savings.dta" 
	g sv45n = sv45
	keep hhid mofd sv45n
	rename sv45n fmid
	keep if fmid!=.
	tempfile new_account
	save `new_account'


/*----------------------------------------------------------------------
  3. OPEN BASE + MERGE WEIGHTS + MODULES
----------------------------------------------------------------------*/

	use "$temp\L2IndoBase@R`rnd'", clear
	duplicates tag hhid fmid mofd, g(dupid)
	tab dupid
	bys hhid fmid mofd: g cnt = _n
	drop if cnt>1
	drop cnt
	drop if hhid==.
	
// Merge panel weights
	merge m:1 hhid mofd using "$in/PanelWeightALL@R`rnd'"
	tab _m
	drop if _m==2
	count if _m==1
	if r(N) > 0 {
		di as text "NOTE: `r(N)' hhid-mofd obs without weights"
	}
	keep if _m==3
	drop _m
			
// Merge migration
	merge 1:m hhid fmid mofd using `migclean'
	drop _m
	
// Merge employment
	merge 1:m hhid fmid mofd using `actclean'
	drop _m
	
// Merge new bank account
	merge m:1 hhid fmid mofd using `new_account'
	tostring hhid, gen(strhhid)
	tostring fmid, gen(strfmid)
	g uniqueid = strhhid + strfmid
	la var uniqueid "Unique individual identifier (hhid + fmid)"
	destring uniqueid, replace
	xtset uniqueid mofd

	g new_account = 0
	replace new_account =1 if _m==3
	la var new_account "Opened new bank account this month"
	drop _m
	
	gen acct_cumulative = new_account
	la var acct_cumulative "Ever opened new bank account (cumulative)"
	sort uniqueid mofd
	by uniqueid: replace acct_cumulative = 1 if acct_cumulative[_n-1] == 1


/*----------------------------------------------------------------------
  4. CONSTRUCT INDIVIDUAL-LEVEL VARIABLES
----------------------------------------------------------------------*/

// Employment
	g hh_work = .
	replace hh_work = 1 if ac1==1
	replace hh_work = 0 if ac1==2
	la var hh_work "Any HH member worked this month"
	
	rename ac2 ind_work
	replace ind_work=1 if ac9==1
	replace ind_work = . if age<15
	replace ind_work = . if age>=63
	la var ind_work "Individual worked this month (ages 15-62)"
	
	g any_fem_work = .
	replace any_fem_work=1 if ind_work==1 & female==1
	la var any_fem_work "Female individual worked this month"
	
	g unemp = .
	replace unemp =1 if ac14==1
	replace unemp =0 if ind_work==1
	replace unemp = . if age<15
	replace unemp = . if age>=63
	la var unemp "Unemployed (looking for work, ages 15-62)"

// Label agricultural production
	la var ac7A "Agriculture product: Rice"
	la var ac7B "Agriculture product: Spices"
	la var ac7C "Agriculture product: Tobacco"
	la var ac7D "Agriculture product: Fruit"
	la var ac7E "Agriculture product: Corn"
	la var ac7F "Agriculture product: Soya bean"
	la var ac7G "Agriculture product: Mung bean"
	la var ac7H "Agriculture product: Peanut"
	la var ac7I "Agriculture product: Cassava"
	la var ac7J "Agriculture product: Sweet potato"
	la var ac7K "Agriculture product: Potato"
	la var ac7L "Agriculture product: Carrot"
	la var ac7M "Agriculture product: Shallot"
	la var ac7N "Agriculture product: Chilies"
	la var ac7O "Agriculture product: Other vegetables"

// Merge wellbeing
	merge m:1 hhid mofd using `wbclean'
	drop if mofd>`mofdloc'
	assert _m!=2
	drop _m	
	drop dur_*

// Set panel
	xtset uniqueid round

// Migration
	g migrant_hh = 0
	replace migrant_hh =1 if mg8==1
	la var migrant_hh "HH has a migrant member this month"
	g migrant_sum = 0
	replace migrant_sum =1 if mig==1
	la var migrant_sum "Individual is a migrant (from baseline)"
	g think_mig_hh = 0
	replace think_mig_hh = 1 if mg1==1
	la var think_mig_hh "HH considering migration"

// Self-employed
	g self_emp = .
	replace self_emp = 1 if ac3==5
	replace self_emp = 0 if ac3==1 | ac3==2 | ac3==3 | ac3==4 | ac3==96
	la var self_emp "Self-employed"
	g self_emp_any = self_emp
	la var self_emp_any "Self-employed (for HH max)"
	g self_emp_sum = self_emp
	la var self_emp_sum "Self-employed (for HH sum)"

// Government employment
	g gov_emp = . 
	replace gov_emp = 1 if ac3==1
	replace gov_emp = 1 if ac3==2
	replace gov_emp = 0 if ac3==3 | ac3==4 | ac3==5 | ac3==96
	la var gov_emp "Government employee"
	g gov_emp_any = gov_emp
	la var gov_emp_any "Government employee (for HH max)"
	g gov_emp_sum = gov_emp
	la var gov_emp_sum "Government employee (for HH sum)"

// Part-time / full-time
	g part_time = .
	replace part_time =1 if ac5==1
	replace part_time =0 if ac5==2
	la var part_time "Part-time worker"
	g part_time_any = part_time
	la var part_time_any "Part-time worker (for HH max)"
	g part_time_sum = part_time
	la var part_time_sum "Part-time worker (for HH sum)"

	g full_time = .
	replace full_time =1 if ac5==2
	replace full_time =0 if ac5==1
	la var full_time "Full-time worker"
	g full_time_any = full_time
	la var full_time_any "Full-time worker (for HH max)"
	g full_time_sum = full_time
	la var full_time_sum "Full-time worker (for HH sum)"

// Remittances
	egen all_rem = rowtotal(mg23 mg15)
	la var all_rem "Total remittance income (sent + received)"

// Employment aggregates
	g emp_hh = 0
	replace emp_hh = 1 if ac1==1
	la var emp_hh "Any HH member employed"
	g emp_sum = 0
	replace emp_sum = 1 if ind_work==1
	la var emp_sum "Individual employed (for HH sum)"

// Work lost
	g work_lost_hh =.
	replace work_lost_hh=1 if ac9==1
	replace work_lost_hh=0 if ac9==2
	la var work_lost_hh "HH member lost work this month"

// Looking for work
	g looking_work = .
	replace looking_work =0 if age_group_emp!=.
	replace looking_work =1 if ac14==1
	la var looking_work "Actively looking for work"

// Middle class (individual level)
	g upmid_class = .
	g lowmid_class = .
	g subj_poor =.
	replace upmid_class = 1 if wb32==4
	replace upmid_class = 1 if wb32==5
	replace upmid_class = 0 if wb32!=. & upmid_class==.
	replace subj_poor = 1 if wb32==1
	replace subj_poor = 1 if wb32==2
	replace subj_poor = 0 if wb32!=. & subj_poor==.
	replace lowmid_class = 1 if wb32==3
	replace lowmid_class = 0 if subj_poor==1
	la var upmid_class "Self-assessed upper middle class or above"
	la var lowmid_class "Self-assessed lower middle class"
	la var subj_poor "Self-assessed poor or very poor"
	
	g clean_class = .
	replace clean_class=1 if subj_poor == 1
	replace clean_class=2 if lowmid_class == 1
	replace clean_class=3 if upmid_class == 1
	label define class 1"Poor" 2"Lower middle class" 3"Upper middle class"
	label values clean_class class
	la var clean_class "Self-assessed economic class (3 categories)"

	tab school, g(sch_dum)
	rename sch_dum1 primary
	rename sch_dum2 jnrsecond
	rename sch_dum3 srsecond
	rename sch_dum4 tertiary
	la var primary "Highest education: primary"
	la var jnrsecond "Highest education: junior secondary"
	la var srsecond "Highest education: senior secondary"
	la var tertiary "Highest education: tertiary"

// Air pollution exposure
	g outside = .
	forvalue i=1/20 {
		replace outside = ac15_`i' if fmid==`i'
	}
	la var outside "Hours spent outdoors (individual-specific)"
	cap drop ac15_*

// Minimum wage
	g below_mwage = .
	replace below_mwage=1 if minwageact==1
	replace below_mwage=0 if minwageact==2
	la var below_mwage "Believes workers earn below minimum wage"

// Food security (individual level)
	loc foodin wb24 wb25 wb26 wb27 wb28 wb29 wb30 wb31 
	foreach i of loc foodin {
		tab `i'
		g bin_`i' = .
		replace bin_`i' = 1 if `i'==1
		replace bin_`i' = 0 if `i'==2
	}
	rename bin_wb24 worried
	rename bin_wb25 unhealthy
	rename bin_wb26 low_diversity
	rename bin_wb27 skip_meal
	rename bin_wb28 eat_less
	rename bin_wb29 ran_out
	rename bin_wb30 went_hungry	
	rename bin_wb31 whole_day		
	la var worried "FIES: Worried about not having enough food"
	la var unhealthy "FIES: Unable to eat healthy/nutritious food"
	la var low_diversity "FIES: Ate only a few kinds of foods"
	la var skip_meal "FIES: Had to skip a meal"
	la var eat_less "FIES: Ate less than should"
	la var ran_out "FIES: Ran out of food"
	la var went_hungry "FIES: Went hungry but did not eat"
	la var whole_day "FIES: Went whole day without eating"
	egen totfoodinsec = rowtotal(worried unhealthy low_diversity ///
		skip_meal eat_less ran_out went_hungry whole_day)
	la var totfoodinsec "FIES: Total food insecurity deprivation count (0-8)"

// FIES severity levels (from 202511-analysis)
	gen fies_mild = (worried==1 | unhealthy==1 | low_diversity==1)
	la var fies_mild "FIES: Mild food insecurity"
	gen fies_moderate = (skip_meal==1 | eat_less==1 | went_hungry==1)
	la var fies_moderate "FIES: Moderate food insecurity"
	gen fies_severe = (ran_out==1 | whole_day==1)
	la var fies_severe "FIES: Severe food insecurity"
	gen fies_level = 1 if fies_mild==1 & fies_moderate==0 & fies_severe==0
	replace fies_level = 2 if fies_moderate==1 & fies_severe==0
	replace fies_level = 3 if fies_severe==1
	label define fies 1 "Mild" 2 "Moderate" 3 "Severe"
	label values fies_level fies
	la var fies_level "FIES severity level"

// Agricultural work
	g rice_farm = 0
	replace rice_farm=1 if ac7A==1
	la var rice_farm "HH produces rice"
	g ag_work_dum=.
	replace ag_work_dum=1 if ac6==1
	replace ag_work_dum=0 if ac6==2
	la var ag_work_dum "Individual works in agriculture"
	bys hhid mofd: egen hhag = max(ag_work_dum)
	replace hhag=0 if hhag==.
	la var hhag "Any HH member works in agriculture"
	
// Work hours
	g work_hours = ac5_jam
	la var work_hours "Total weekly work hours"
	rangestat (sd) work_hours, interval(mofd -3 0) by(uniqueid)
	la var work_hours_sd "Rolling 3-month SD of work hours"
	g ac5_jammax = ac5_jam
	la var ac5_jammax "Max weekly work hours (for HH collapse)"


/*----------------------------------------------------------------------
  5. INDIVIDUAL-LEVEL ANALYSIS (from 202511-analysis)
----------------------------------------------------------------------*/

// Working age group
	g agegroup = .
	replace agegroup = 1 if inrange(age,15,24)
	replace agegroup = 2 if inrange(age,25,55)
	la def agegroup 1 "15-24" 2 "25-55"
	la val agegroup agegroup
	la var agegroup "Working age group"

// Searching for jobs
	g jobsearch = 0
	replace jobsearch = 1 if ac13==1 & ac14==1
	la var jobsearch "Seeking jobs"

// Employment status previous month
	sort hhid fmid mofd
	by hhid fmid: g employed_p1m = (ind_work[_n-1]==1)
	replace employed_p1m = . if ind_work[_n-1]==.
	la var employed_p1m "Was employed previous month"

// Employment status current
	g employed = ind_work
	la var employed "Currently employed"


/*----------------------------------------------------------------------
  6. SAVE INDIVIDUAL-LEVEL FILE
----------------------------------------------------------------------*/

	save "$source/Anon_IND_L2Indo_Analysisfile_R`rnd'.dta", replace

	di as result "Individual-level file saved."
	log close

