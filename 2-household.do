/*==============================================================================
  L2Indo Household-Level Panel — Do-file 2 of 3
  
  PURPOSE:
  Collapses individual data to HH level, merges all HH modules, constructs
  analysis variables (income, class, food security, views, shocks, finance),
  and runs HH-level analyses.
  
  REQUIRES:
  - Run 1-individual.do first (it produces the individual file that gets
    collapsed here, plus the individual variables needed for HH aggregation)
  
  INPUTS:
  - "$source/Anon_IND_L2Indo_Analysisfile.dta"  (from 1-individual.do)
  - "$in/L2Indo_HHBase@{rnd}.dta"               (from 0-weights)
  - "$in/PanelWeightALL@{rnd}.dta"              (from 0-weights)
  - Monthly modules: M02-M13
  - Spatial deflators, poverty lines, urban/rural data
  
  OUTPUTS:
  - "$source/Anon_HH_L2Indo_Analysisfile.dta"
  - "$out/incomes_temp.dta"                      (for 3-incomes-to-ind.do)
  - "$temp/hh-l2indo.dta"                        (working file for experiments)
  - Regression outputs in $temp
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

	log using "$dlog/2-household-R`rnd'.smcl", replace


/*======================================================================
  PART A: COLLAPSE INDIVIDUAL → HOUSEHOLD + MERGE MODULES
======================================================================*/

/*----------------------------------------------------------------------
  2. COLLAPSE INDIVIDUAL DATA TO HH LEVEL
----------------------------------------------------------------------*/

	use "$source/Anon_IND_L2Indo_Analysisfile_R`rnd'.dta", clear

	collapse (sum) migrant_sum emp_sum all_rem ///
		self_emp_sum gov_emp_sum part_time_sum full_time_sum ac5_jam ///
		(mean) hhag emp_hh think_mig_hh migrant_hh work_lost_hh ///
		(max) looking_work self_emp_any gov_emp_any unemp part_time_any full_time_any ///
			female acct_cumulative rice_farm ac5_jammax any_fem_work ///
			ag_work_dum, by(hhid mofd)

	tempfile migact
	save `migact'


/*----------------------------------------------------------------------
  3. CLEAN ALL HH-LEVEL MODULES
----------------------------------------------------------------------*/

	use "$in/l2indo_M02_shocks.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile shclean
	save `shclean'
	
	use "$in/l2indo_M03_wellbeing.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile wbclean
	save `wbclean'
	
	use "$in/l2indo_M06_views.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile vclean
	save `vclean'
	
	use "$in/l2indo_M07_incomes.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile inclean
	save `inclean'
	
	use "$in/l2indo_M08_savings.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile svclean
	save `svclean'
	
	use "$in/l2indo_M09_greenagenda.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile greenclean
	save `greenclean'
	
	use "$in/l2indo_M10_experiment.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile exp
	save `exp'
	
	use "$in/l2indo_M11_internet.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile intclean
	save `intclean'

	use "$in/l2indo_M12_ecommerce.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile ecommerce
	save `ecommerce'	
    
	use "$in/l2indo_M13_trust.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile trust
	save `trust'
    
	use "$in/l2indo_M14_gasoline.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile gasoline
	save `gasoline'

	use "$in/l2indo_M15_coping.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile coping
	save `coping'

	use "$in/l2indo_M16_aqm.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile aqm
	save `aqm'
    
	use "$in/l2indo_M17_lpg.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile lpg
	save `lpg'
    
	use "$in/l2indo_M18_electricity.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile elec
	save `elec'    

	use "$in/l2indo_M19_govspending.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile govspending
	save `govspending'    

	use "$in/l2indo_M20_housing.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile housing
	save `housing'        
    
	use "$in/l2indo_M21_inequality.dta", clear
	bys hhid mofd: keep if _n==1
	tempfile inequality
	save `inequality'        
    
    
/*----------------------------------------------------------------------
  4. MERGE ALL HH-LEVEL MODULES
----------------------------------------------------------------------*/

// Open HH base
	use "$temp\L2Indo_HHBase@R`rnd'", replace
	capture drop if _m==1
	capture drop _m
		
// Panel weights
	merge 1:1 hhid mofd using "$in/PanelWeightALL@R`rnd'"
	keep if _m==3
	drop _m

// All modules
	foreach f in shclean wbclean vclean inclean svclean migact intclean greenclean ecommerce trust exp gasoline coping aqm lpg elec govspending housing inequality {
		merge 1:1 hhid mofd using ``f''
		drop if _m==2
		drop _m
	}

// Date variables
	cap drop dur_*
	gen qofd = qofd(date)
	la var qofd "Quarter of interview"
	gen yofd = yofd(date)
	la var yofd "Year of interview"
	g cal_month = month(date)
	la var cal_month "Calendar month of interview"
	drop if mofd>`mofdloc'

// Urban/rural (from 202511-analysis)
	cap merge m:1 hhid using "$source/../Additional Data/base1-hhid-urb-id.dta"
	cap drop if _merge==2
	cap drop _merge
	cap order urban, after(island)
	cap la var urban "Urban"


/*======================================================================
  PART B: DEFLATORS AND INCOME CONSTRUCTION
======================================================================*/

/*----------------------------------------------------------------------
  5. INFLATION AND SPATIAL DEFLATORS
----------------------------------------------------------------------*/

**# UPDATE CPI
	g infl = .
	la var infl "CPI inflation deflator (base Jan 2024=1)"
	replace infl = 1.009 if mofd==770
	replace infl = 1.012 if mofd==771
	replace infl = 1.012 if mofd==772
	replace infl = 1.011 if mofd==773
	replace infl = 1.009 if mofd==774
	replace infl = 1.009 if mofd==775
	replace infl = 1.007 if mofd==776
	replace infl = 1.008 if mofd==777
	replace infl = 1.011 if mofd==778
	replace infl = 1.016 if mofd==779
	replace infl = 1.008 if mofd==780
	replace infl = 1.003 if mofd==781
	replace infl = 1.020 if mofd==782
	replace infl = 1.032 if mofd==783
	replace infl = 1.028 if mofd==784
	replace infl = 1.030 if mofd==785
	replace infl = 1.033 if mofd==786
	replace infl = 1.032 if mofd==787
	replace infl = 1.034 if mofd==788
	replace infl = 1.037 if mofd==789
	replace infl = 1.039 if mofd==790
	replace infl = 1.045 if mofd==791
	replace infl = 1.044 if mofd==792
	replace infl = 1.051 if mofd==793
	replace infl = 1.055 if mofd==794
    replace infl = 1.057 if mofd==795
    replace infl = 1.060 if mofd==796
    replace infl = 1.064 if mofd==797
    replace infl = 1.063 if mofd==798
    replace infl = 1.065 if mofd==799
    replace infl = 1.068 if mofd==800    

// Spatial deflators
	g prov = province_id
	g rege = district_id
	g year = yofd
	replace year = 2025 if year==2026
	
    * set crosswalk
    preserve
        use "$gdat/Crosswalk/crosswalk-kabupaten-2024.dta", clear
        keep if year==2024
        expand 2, g(new)
        replace year=2025 if new==1
        drop new
        
        tempfile crosswalk
        save `crosswalk'
    restore
        
	preserve
		use "$gdat/Spatial Deflator/spdef-reg-2024.dta", clear
		append using "$gdat/Spatial Deflator/spdef-reg-2025.dta"
        rename rege kab
        
        *merge
        merge m:1 prov kab year using `crosswalk', keepusing(prov_all kab_all bps_code_all)
        drop if _m==2 
        drop _m prov kab
        ren prov_all prov
        ren kab_all rege 
		duplicates drop
        
        tempfile pdef_all
		save `pdef_all'
	restore 
	
	merge m:1 prov rege year using `pdef_all'
	drop if _m==2
	drop _m
	drop prov rege

// Poverty lines (from 202511-analysis)
	cap {
		g prov = province_id
		g plyear = 2024
		merge m:1 plyear prov urban using "$source/../Additional Data/npl-2000-2024.dta"
		drop if _merge==2
		drop _merge
		drop plyear prov
	}


/*----------------------------------------------------------------------
  6. INCOME CONSTRUCTION
----------------------------------------------------------------------*/

	xtset hhid mofd

	egen hh_inc_nom = rowtotal(inc3 inc7 inc9 inc11 inc13 inc15 all_rem)
	la var hh_inc_nom "Total nominal household income"
	
	g pens_incshare = inc3/hh_inc_nom
	la var pens_incshare "Share of income from pensions"
	g sa_incshare = inc7/hh_inc_nom
	la var sa_incshare "Share of income from social assistance"
	g wage_incshare = inc9/hh_inc_nom
	la var wage_incshare "Share of income from wages"
	g ag_incshare = inc11/hh_inc_nom
	la var ag_incshare "Share of income from agriculture"
	g se_incshare = inc13/hh_inc_nom
	la var se_incshare "Share of income from self-employment"
	g oth_incshare = inc15/hh_inc_nom
	la var oth_incshare "Share of income from other sources"
	g rem_incshare = all_rem/hh_inc_nom
	la var rem_incshare "Share of income from remittances"
	
	loc shares pens_incshare sa_incshare wage_incshare ag_incshare se_incshare oth_incshare rem_incshare
	foreach i of loc shares {
		replace `i' = 0 if `i'==.
	}

	replace hh_inc_nom = 0 if hh_inc_nom==.
	g hh_inc_real = hh_inc_nom/infl
	la var hh_inc_real "Total real household income"
	g inc = hh_inc_nom
	la var inc "Total nominal household income (copy)"
	
	loc real inc3 inc7 inc9 inc11 inc13 inc15 all_rem inc
	foreach i of loc real {
		g `i'_real = .
		g `i'_real_spadef = .
		replace `i'_real = `i'/infl
		replace `i'_real_spadef = `i'/infl/pdef
		g pc_`i'_real = `i'_real/hhsize
		g pc_`i'_real_spadef = `i'_real_spadef/hhsize
		g pc_`i'_real_no0 = pc_`i'_real
		g pc_`i'_real_spadef_no0 = pc_`i'_real_spadef
		replace pc_`i'_real_no0=. if pc_`i'_real_no0==0
		replace pc_`i'_real_spadef_no0=. if pc_`i'_real_spadef_no0==0
	}

	g pc_real_notrans_spadef = .
	replace pc_real_notrans_spadef=pc_inc_real_spadef-pc_inc7_real_spadef if pc_inc7_real_spadef!=.
	la var pc_real_notrans_spadef "Real spatially deflated pc income excl. social assistance"
	
	g ln_pcinc_hf = ln(pc_inc_real_spadef)
	la var ln_pcinc_hf "Log real spatially deflated pc income"

// Per capita nominal/real (from 202511-analysis)
	g hh_pcinc_nom = hh_inc_nom/hhsize
	la var hh_pcinc_nom "Per capita nominal income"
	g hh_pcinc_real = hh_inc_real/hhsize
	la var hh_pcinc_real "Per capita real income"
	cap g pcincplrat = hh_pcinc_real/povline
	cap la var pcincplrat "PC income to poverty line ratio"

// Renamed income components
	rename inc3 pens_inc
	rename inc7 sa_inc
	rename inc9 wage_inc
	rename inc11 ag_inc
	rename inc13 se_inc
	rename inc15 oth_inc
	rename all_rem rem_inc

// Nominal income components (from 202511-analysis)
	g ninc_pens = pens_inc
	g ninc_sa = sa_inc
	g ninc_wage = wage_inc
	g ninc_ag = ag_inc
	g ninc_se = se_inc
	g ninc_rem = rem_inc
	g ninc_oth = oth_inc

// Real income components
	foreach v in pens sa wage ag se rem oth {
		g rinc_`v' = ninc_`v'/infl
		replace ninc_`v' = 0 if missing(ninc_`v')
		g sh_ninc_`v' = ninc_`v'/hh_inc_nom
		replace sh_ninc_`v' = 0 if missing(sh_ninc_`v')
		replace sh_ninc_`v' = . if hh_inc_nom==.
	}

// First differences
	loc incs hh_inc_nom pens_inc sa_inc wage_inc ag_inc se_inc oth_inc rem_inc 
	foreach i of loc incs {
		replace `i' = 0 if `i'==.
		g d_`i' = d.`i'
		g pct_`i' = (d_`i'/d_hh_inc_nom)*100
	}

// Income source dummies
	g pension = (inc1==1) if inc1!=.
	la var pension "Receives pension income"
	g sa = (inc4==1) if inc4!=.
	la var sa "Receives social assistance"
	g wage = (inc8==1) if inc8!=.
	la var wage "Receives wage income"
	g ag = (inc10==1) if inc10!=.
	la var ag "Receives agricultural income"
	g self = (inc12==1) if inc12!=.
	la var self "Receives self-employment income"
	g rem = 0
	replace rem = 1 if rem_inc>0 & rem_inc!=.
	la var rem "Receives remittance income"
	
	egen ag_se_share = rowtotal(ag_incshare se_incshare)
	la var ag_se_share "Combined share of ag + self-employment income"
	g most_ag_self = (ag_se_share>.5) if ag_se_share!=.
	la var most_ag_self "Majority income from agriculture or self-employment"
	g most_wage = (wage_incshare>.5) if wage_incshare!=.
	la var most_wage "Majority income from wages"
	g any_emp = (wage==1 | ag==1 | self==1 | emp_hh==1)
	la var any_emp "Any employment (wage, ag, self, or HH-level)"

// Income source dummies (alternative naming)
	g pension_dum = (inc1==1) if inc1!=.
	la var pension_dum "Receives pension income (dummy)"
	g sa_inc_dum = (inc4==1) if inc4!=.
	la var sa_inc_dum "Receives social assistance income (dummy)"
	g wage_dum = (inc8==1) if inc8!=.
	la var wage_dum "Receives wage income (dummy)"
	g ag_inc_dum = (inc10==1) if inc10!=.
	la var ag_inc_dum "Receives agricultural income (dummy)"
	g self_emp_dum = (inc12==1) if inc12!=.
	la var self_emp_dum "Receives self-employment income (dummy)"

// Coefficient of variation of income
	bys hhid: egen sd_income = sd(pc_inc_real_spadef)
	bys hhid: egen mean_income = mean(pc_inc_real_spadef)
	g cv_income = (sd_income/mean_income)*100
	la var cv_income "Coefficient of variation of pc income (%)"

// CV of each income component (from 202511-analysis)
	foreach v in pens sa wage ag se rem oth {
		replace rinc_`v' = 0 if missing(rinc_`v')
		bys hhid: egen sd_rinc_`v' = sd(rinc_`v')
		bys hhid: egen mean_rinc_`v' = mean(rinc_`v')
		g cv_rinc_`v' = (sd_rinc_`v'/mean_rinc_`v')*100
		la var cv_rinc_`v' "CV of real `v' income (%)"
	}


/*======================================================================
  PART C: SUBJECTIVE WELFARE, VIEWS, SHOCKS, FINANCE
======================================================================*/

/*----------------------------------------------------------------------
  7. SUBJECTIVE WELFARE AND CLASS
----------------------------------------------------------------------*/

// Subjective economic class
	g eclass1 = wb32
	la def ecstd 1 "Extreme Poor" 2 "Poor" 3 "Lower MC" 4 "Upper MC" 5 "Rich"
	la val eclass1 ecstd
	la var eclass1 "Subjective economic class (5 categories)"
	recode wb32 (2=1) (3=2) (4=2) (5=3), gen(eclass2)
	la def ecnew 1 "Poor" 2 "MC" 3 "Rich"
	la val eclass2 ecnew
	la var eclass2 "Subjective economic class (3 categories)"
	recode wb32 (1 2 = 1) (3 = 2) (4 5 = 3), gen(eclass)
	la def eclass 1 "Poor" 2 "Lower MC" 3 "Upper MC"
	la val eclass eclass
	la var eclass "Subjective economic class (Poor/LMC/UMC)"

// Self-assessed poverty
	g self_poor = (vw23==1) if vw23!=.
	la var self_poor "Self-assessed poor"
	g not_self_poor = (vw23==2) if vw23!=.
	la var not_self_poor "Self-assessed not poor"
	egen everpoor = max(self_poor), by(hhid)
	la var everpoor "Ever self-assessed poor (any round)"
	bys hhid: g count = _N
	la var count "Number of rounds HH observed"
	egen countpoor = sum(self_poor), by(hhid)
	la var countpoor "Number of rounds HH self-assessed poor"
	g always_poor = (count==countpoor & countpoor!=0)
	la var always_poor "Self-assessed poor in every observed round"

// Binary class variables
	g upmid_class = .
	g lowmid_class = .
	g subj_poor = .
	replace upmid_class = 1 if wb32==4 | wb32==5
	replace upmid_class = 0 if wb32!=. & upmid_class==.
	replace subj_poor = 1 if wb32==1 | wb32==2
	replace subj_poor = 0 if wb32!=. & subj_poor==.
	replace lowmid_class = 1 if wb32==3
	replace lowmid_class = 0 if subj_poor==1
	la var upmid_class "Self-assessed upper middle class or above"
	la var lowmid_class "Self-assessed lower middle class"
	la var subj_poor "Self-assessed poor or very poor (wb32)"

	xtset hhid mofd
	g past_poor = L.subj_poor
	la var past_poor "Lagged self-assessed poor"
	g stay_poor = (subj_poor==1 & past_poor==1) if subj_poor!=. & past_poor!=.
	la var stay_poor "Remained poor from previous month"
	
	g clean_class = .
	replace clean_class=1 if subj_poor == 1
	replace clean_class=2 if lowmid_class == 1
	replace clean_class=3 if upmid_class == 1
	label define class 1"Poor" 2"Lower middle class" 3"Upper middle class"
	label values clean_class class
	la var clean_class "Self-assessed economic class (3 categories)"

// Optimism
	g class_up5y = (wb33>wb32) if wb33!=. & wb32!=.
	la var class_up5y "Expects to be in higher class in 5 years"

// Able to save
	g able_save = (sv3==1) if sv3!=.
	la var able_save "Able to save this month"


/*----------------------------------------------------------------------
  8. FOOD SECURITY
----------------------------------------------------------------------*/

	loc foodin wb24 wb25 wb26 wb27 wb28 wb29 wb30 wb31 
	foreach i of loc foodin {
		g bin_`i' = (`i'==1) if `i'!=.
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
	la var totfoodinsec "FIES: Total food insecurity count (0-8)"
	g food_insec = (totfoodinsec>0) if totfoodinsec!=.
	la var food_insec "Any food insecurity (FIES count > 0)"
	g food_secure = (totfoodinsec==0) if totfoodinsec!=.
	la var food_secure "Fully food secure (FIES count = 0)"

    
    * generate fies scale
    *--------------------
    gen fies_mild = (worried==1 | unhealth==1 | low_diversity==1)
    gen fies_moderate = (skip_meal==1 | eat_less==1 | went_hungry==1)
    gen fies_severe = (ran_out==1 | whole_day==1)

    gen fies_level = 1 if fies_mild==1 & fies_moderate==0 & fies_severe==0
    replace fies_level = 2 if fies_moderate==1 & fies_severe==0
    replace fies_level = 3 if fies_severe==1
    label define fies 1 "Mild" 2 "Moderate" 3 "Severe"
    label values fies_level fies
    


/*----------------------------------------------------------------------
  9. FINANCIAL SERVICES AND SAVINGS
----------------------------------------------------------------------*/

	g useacct = (sv1==1) if sv1!=.
	la var useacct "Used bank account this month"
	g mobmoney = (sv2==1) if sv2!=.
	la var mobmoney "Used mobile money this month"
	g couldpay = (sv30==1) if sv30!=.
	la var couldpay "Could pay unexpected emergency expense"
	g credit_exist = (sv19==1) if sv19!=.
	la var credit_exist "Has existing loan"
	g borrow = (wb6==1) if wb6!=.
	la var borrow "Borrowed money this month"
	g credit_mnth = (sv12==1) if sv12!=.
	la var credit_mnth "Applied for credit this month"
	g obtain_credit = credit_mnth
	replace obtain_credit = 0 if sv15==2
	la var obtain_credit "Obtained credit this month"
	g unable_save = (able_save==0) if able_save!=.
	la var unable_save "Unable to save this month"

// Savings (from 202509-analysis)
	g nom_mth_save = sv4
	replace nom_mth_save =. if nom_mth_save==0
	g realmth_save = nom_mth_save/infl
	g saving = realmth_save
	replace saving = 0 if saving==.
	g income = hh_inc_nom/infl
	g ln_save = ln(1+saving)
	la var ln_save "Log(1 + real monthly savings)"
	g ln_income = ln(1+income)
	la var ln_income "Log(1 + real monthly income)"
	g save_share = saving/income
	la var save_share "Savings as share of income"

// Saving channels (from 202511-analysis)
	g save_mobile = (sv2==1) if sv2!=.
	la var save_mobile "Saves via mobile"
	g save_formal = (sv1==1) if sv1!=.
	la var save_formal "Saves via formal bank"
	g save_both = (save_mobile==1 & save_formal==1)
	la var save_both "Saves via both mobile and formal"

// Loans (from 202511-analysis)
	g loan_for_new = sv18 if inlist(sv14,1,4)
	replace loan_for_new=. if loan_for_new<1000 & loan_for_new!=0
	replace loan_for_new=0 if inlist(sv21,1,4) & loan_for_new==.
	g loan_for_exs = sv25 if inlist(sv21,1,4)
	replace loan_for_exs=. if loan_for_exs<1000 & loan_for_exs!=0
	replace loan_for_exs=0 if inlist(sv14,1,4) & loan_for_exs==.
	g loan_inf_new = sv18 if inlist(sv14,2,3,5,96)
	replace loan_inf_new=. if loan_inf_new<1000 & loan_inf_new!=0
	replace loan_inf_new=0 if inlist(sv21,2,3,5,96) & loan_inf_new==.
	g loan_inf_exs = sv25 if inlist(sv21,2,3,5,96)
	replace loan_inf_exs=. if loan_inf_exs<1000 & loan_inf_exs!=0
	replace loan_inf_exs=0 if inlist(sv14,2,3,5,96) & loan_inf_exs==.
	g loan_for_tot = loan_for_new + loan_for_exs 
	la var loan_for_tot "Total formal loan amount"
	g loan_inf_tot = loan_inf_new + loan_inf_exs
	la var loan_inf_tot "Total informal loan amount"
	g lfor = loan_for_tot
	replace lfor=0 if missing(lfor)
	g linf = loan_inf_tot
	replace linf=0 if missing(linf)
	g loan_total = lfor+linf
	replace loan_total = . if (loan_for_tot==. & loan_inf_tot==.)
	la var loan_total "Total loan amount (formal + informal)"
	drop lfor linf
	g debtratio_for = loan_for_tot/hh_inc_nom
	la var debtratio_for "Formal debt to income ratio"
	g debtratio_inf = loan_inf_tot/hh_inc_nom
	la var debtratio_inf "Informal debt to income ratio"
	g debtratio_tot = loan_total/hh_inc_nom
	la var debtratio_tot "Total debt to income ratio"

// Tax (from 202509-analysis)
	g taxpayer_vat = .
	replace taxpayer_vat = 0 if vw26==4
	replace taxpayer_vat = 1 if vw26!=4 & vw26!=.
	la var taxpayer_vat "Pays VAT"
	g taxpayer_inc = .
	replace taxpayer_inc = 0 if vw27==4
	replace taxpayer_inc = 1 if vw27!=4 & vw27!=.
	la var taxpayer_inc "Pays income tax"
	g vat_level = vw26 if taxpayer_vat == 1
	g ict_level = vw27 if taxpayer_inc == 1 
	la def taxscale 1 "Too high" 2 "Just right" 3 "Too low"
	la val vat_level ict_level taxscale

// Willingness to pay more tax (from 202509-analysis)
	g vw_taxinc_ineq = vw3 if vw3_ing=="INEQUALITY"
	g vw_taxinc_nutr = vw3 if vw3_ing=="MALNUTRITION"
	g vw_taxinc_pove = vw3 if vw3_ing=="POVERTY"
	g vw_taxinc_povc = vw3 if vw3_ing=="CHILD POVERTY"
	g vw_taxinc_povl = vw3 if vw3_ing=="ELDERLY POVERTY"
	foreach var of varlist vw_taxinc_* {
		replace `var' = 0 if `var'==2
	}


/*----------------------------------------------------------------------
  10. SHOCKS AND DISRUPTIONS
----------------------------------------------------------------------*/

// Water
	g wat_disrupt = (sh1==1) if sh1!=.
	la var wat_disrupt "Experienced water disruption"
	g no_wat_disrupt = (sh1==2) if sh1!=.
	la var no_wat_disrupt "No water disruption"
	g water_disrupt = (wat_all>0) if wat_all!=.
	la var water_disrupt "Any water disruption (from detail)"
	bys hhid: g water_disrupt_mth = sum(water_disrupt)
	la var water_disrupt_mth "Cumulative months of water disruption"

// Electricity (simple and detailed from 202511-analysis)
	g no_elec_disrupt = (sh4==24 | sh5==24)
	replace no_elec_disrupt = 0 if sh4!=24 & sh5!=24
	la var no_elec_disrupt "No electricity disruption (24hrs both days)"
	g elec_disrupt = (no_elec_disrupt==0)
	la var elec_disrupt "Experienced electricity disruption"
	g elec_disrupt_y = (sh4<24)
	la var elec_disrupt_y "Electricity disruption yesterday"
	g elec_disrupt_2y = (sh5<24)
	la var elec_disrupt_2y "Electricity disruption day before yesterday"
	g elec_disrupt_p1m = (elec_disrupt_y==1 | elec_disrupt_2y==1)
	la var elec_disrupt_p1m "Any electricity disruption past 2 days"

// Internet (simple and detailed from 202511-analysis)
	g homeint_dis = (sh12==1) if sh12!=.
	la var homeint_dis "Experienced home internet disruption"
	g nohomeint_dis = (sh12==2) if sh12!=.
	la var nohomeint_dis "No home internet disruption"
	g mobint_dis = (sh14==1) if sh14!=.
	la var mobint_dis "Experienced mobile internet disruption"
	g nomobint_dis = (sh14==2) if sh14!=.
	la var nomobint_dis "No mobile internet disruption"
	g inet_disrupt = sh12
	recode inet_disrupt (2 = 0) (3 = .)
	la var inet_disrupt "Internet disruption (recoded)"

// Utilities, school, health, life events
	g unab_pay_util = (wb5==1) if wb5!=.
	la var unab_pay_util "Unable to pay utilities"
	g able_pay_util = (wb5==2) if wb5!=.
	la var able_pay_util "Able to pay utilities"
	g miss_school = .
	replace miss_school =1 if sh16==1
	replace miss_school =0 if sh16==2
	replace miss_school =. if sh16==3
	la var miss_school "Child missed school this month"
	g no_miss_sch = .
	replace no_miss_sch =0 if sh16==1
	replace no_miss_sch =1 if sh16==2
	replace no_miss_sch =. if sh16==3
	la var no_miss_sch "No child missed school"
	g maj_illInj = (sh21_e==1 | sh21_d==1)
	la var maj_illInj "Major illness or injury in HH"
	g maj_birth = (sh21_a==1)
	la var maj_birth "Birth in HH this month"
	g need_health = (wb9==1) if wb9!=.
	la var need_health "HH member needed health services"
	g forgo_health = (wb10==1) if wb10!=.
	la var forgo_health "Forgone health services due to cost"
	g sick = (wb12==1) if wb12!=.
	la var sick "HH member was sick this month"
	g death = (sh21_f==1)
	la var death "Death in HH this month"
	g disaster_exp = (sh20==1) if sh20!=.
	la var disaster_exp "Experienced a disaster"

// Prices (from 202511-analysis)
	g p_rice = wb17/wb16
	replace p_rice = . if p_rice==0
	la var p_rice "Price of rice per kg"
	g p_chicken = wb19/wb18
	replace p_chicken = . if p_chicken==0
	la var p_chicken "Price of chicken per kg"
	g p_egg = wb21/wb20
	replace p_egg = . if p_egg==0
	la var p_egg "Price of egg per unit"
	g lnp_rice = ln(p_rice)
	g lnp_chicken = ln(p_chicken)
	g lnp_egg = ln(p_egg)


/*----------------------------------------------------------------------
  11. VIEWS ON ECONOMY, GOVERNANCE, AND POLICY
----------------------------------------------------------------------*/

// Financial wellbeing
	g worsefinwb_last = (inlist(wb1,1,2)) if wb1!=.
	la var worsefinwb_last "Financial situation worsened last month"
	g worsefinwb_next = (inlist(wb2,1,2)) if wb2!=.
	la var worsefinwb_next "Expects financial situation to worsen next month"
	g befinwb_last = (inlist(wb1,4,5)) if wb1!=.
	la var befinwb_last "Financial situation improved last month"
	g befinwb_next = (inlist(wb2,4,5)) if wb2!=.
	la var befinwb_next "Expects financial situation to improve next month"

// Financial deterioration (from 202509-analysis)
	xtset hhid mofd
	g past_pred = L.wb2
	la var past_pred "Last month's prediction of this month"
	g fin_deterior = .
	replace fin_deterior =1 if past_pred>wb1 & past_pred!=. & wb1!=.
	replace fin_deterior =0 if past_pred<=wb1 & past_pred!=. & wb1!=.
	replace fin_deterior =0 if wb1>2
	la var fin_deterior "Unexpected financial deterioration"
	g any_deterfin = (wb1<3) if wb1!=.
	la var any_deterfin "Any financial deterioration"

// Savings and assets
	g noborrow = (wb6==2) if wb6!=.
	la var noborrow "Did not borrow this month"
	g dissave = (wb7==1) if wb7!=.
	replace dissave = 0 if wb7==2 | wb7==3
	la var dissave "Drew down savings this month"
	g no_save = (wb7==3) if wb7!=.
	replace no_save = 0 if wb7==1 | wb7==2
	la var no_save "Has no savings at all"
	g sell_asset = (wb8==1) if wb8!=.
	la var sell_asset "Sold assets this month"

// Economy and governance views
	g badloc_econ = (inlist(wb14,3,4)) if wb14!=.
	la var badloc_econ "Local economic conditions perceived as bad"
	g goodloc_econ = (inlist(wb14,1,2)) if wb14!=.
	la var goodloc_econ "Local economic conditions perceived as good"
	g open_dialogue = (vw2==1) if vw2!=.
	la var open_dialogue "Believes there is open dialogue with government"
	g unopen_dialogue = (vw2==2) if vw2!=.
	la var unopen_dialogue "Believes there is no open dialogue with government"
	g rising_prices = (vw5==1) if vw5!=.
	la var rising_prices "Believes sembako prices rising too quickly"
	g goodtime_job = (vw9==1) if vw9!=.
	la var goodtime_job "Believes it is a good time to find a job"
	g badtime_job = (vw9==2) if vw9!=.
	la var badtime_job "Believes it is a bad time to find a job"
	g goodtime_bus = (vw10==1) if vw10!=.
	la var goodtime_bus "Believes it is a good time to start a business"
	g badtime_bus = (vw10==2) if vw10!=.
	la var badtime_bus "Believes it is a bad time to start a business"
	g optim_econ = (vw13==1) if vw13!=.
	la var optim_econ "Optimistic about economic situation"
	g pessim_econ = (vw13==2) if vw13!=.
	la var pessim_econ "Pessimistic about economic situation"
	g hap_dig_serv = (vw22==1) if vw22!=.
	la var hap_dig_serv "Satisfied with digital services"
	g unhap_dig_serv = (vw22==2) if vw22!=.
	la var unhap_dig_serv "Dissatisfied with digital services"
	g worried_educ = (vw8==1) if vw8!=.
	la var worried_educ "Worried about children's education"
	g satloceduc = (vw17==1) if vw17!=.
	la var satloceduc "Satisfied with local education quality"
	g dissatloceduc = (vw17==2) if vw17!=.
	la var dissatloceduc "Dissatisfied with local education quality"
	g worried_job = (vw18==1) if vw18!=.
	la var worried_job "Worried about losing job"
	g no_worried_job = (vw18==2) if vw18!=.
	la var no_worried_job "Not worried about losing job"
	g right_track = (vw19==1) if vw19!=.
	la var right_track "Country is on the right track"
	g not_right_track = (vw19==2) if vw19!=.
	la var not_right_track "Country is not on the right track"
	g election_fair = (vw4==1) if vw4!=.
	la var election_fair "Believes elections were fair"
	g election_unfair = (vw4==2) if vw4!=.
	la var election_unfair "Believes elections were unfair"
	g notenou_corrupt = (vw24==2) if vw24!=.
	la var notenou_corrupt "Not enough being done against corruption"
	g enough_corrupt = (vw24==1) if vw24!=.
	la var enough_corrupt "Enough being done against corruption"
	g air_polser = (vw36==1) if vw36!=.
	la var air_polser "Believes air pollution is a serious problem"

// Additional views (from 202509-analysis)
	g govcomm = (vw2==1) if vw2!=.
	la var govcomm "Agree that government is communicating well"
	g ecsituation = (vw14==1) if vw14!=.
	la var ecsituation "Agree economic situation is optimistic"
	g pubschqual = (vw17==1) if vw17!=.
	la var pubschqual "Satisfied with public school quality"
	g righttrack = (vw19==1) if vw19!=.
	la var righttrack "Agree pol, sci, economic policies on the right track"
	g corruption = (vw24==1) if vw24!=.
	la var corruption "Agree government good at fighting corruption"
	g efsubtarget = (vw34==1) if vw34!=.
	la var efsubtarget "Worried high income get more fuel and elec subsidies"
	g elecqual = (vw35==1) if vw35!=.
	la var elecqual "Agree electricity quality is serious problem"
	g airpollgov = (vw37==1) if vw37!=.
	la var airpollgov "Agree government doing good job on air pollution"
	g econmanage = (vw40==1) if vw40!=.
	la var econmanage "Agree government good at managing economy"
	g vw_foodprice = (vw5==1) if vw5!=.
	la var vw_foodprice "View on essential food price inflation (1=too fast)"
	g vw_buy_house = (vw41==1) if vw41!=.
	la var vw_buy_house "Views on buying a house"
	g food_deregulate = vw25
	recode food_deregulate (2=0)
	la var food_deregulate "Supports food import deregulation"

// Inflation perceptions
	tab sv28, g(infl_)
	rename infl_1 infl_fast
	rename infl_2 infl_norm
	rename infl_3 infl_slow
	la var infl_fast "Perceives inflation as too fast"
	la var infl_norm "Perceives inflation as normal"
	la var infl_slow "Perceives inflation as slow"

// School meals (from 202509-analysis)
	g schmeal_pro = (wb39==1) if wb39!=.
	la var schmeal_pro "Pro free school meal"
	g schmeal_nutr = (wb_schfeed1==1) if wb_schfeed1!=.
	la var schmeal_nutr "Agree school meal can reduce malnutrition"

// Satisfaction
	g d_hhsatisfaction = wb3
	la var d_hhsatisfaction "HH life satisfaction (binary: 4-5 = satisfied)"
	g d_selfsatisf = wb4
	la var d_selfsatisf "Individual life satisfaction (binary: 4-5 = satisfied)"
	recode d_hhsatisfaction (1 2 3 = 0) (4 5 = 1)
	recode d_selfsatisf (1 2 3 = 0) (4 5 = 1)

// Dissatisfaction index
	egen dissatis_index = rowtotal(notenou_corrupt self_poor ///
		not_right_track infl_fast wat_disrupt ///
		elec_disrupt homeint_dis mobint_dis forgo_health ///
		badtime_job dissatloceduc ///
		worried_job worried_educ pessim_econ badtime_bus ///
		food_insec rising_prices unopen_dialogue badloc_econ sell_asset unable_save ///
		no_save dissave worsefinwb_next worsefinwb_last unab_pay_util)
	la var dissatis_index "Composite dissatisfaction index (sum of negative indicators)"

// Other
	g any_think_mig = (think_mig_hh>0 & think_mig_hh!=.)
	la var any_think_mig "Any HH member considering migration"
	g any_unemp = (unemp>0 & unemp!=.)
	la var any_unemp "Any HH member unemployed"
	g hh5more = (hhsize>=5)
	la var hh5more "Household has 5 or more members"

// Trust (from 202509-analysis)
	local tvars trust1_a trust1_b trust1_c trust1_d ///
		trust1_e trust1_f trust1_g trust1_h ///
		trust1_i trust1_j trust1_k ///
		trust2_a trust2_b trust2_c trust2_d ///
		trust2_e trust2_f trust2_g trust2_h ///
		trust2_i trust2_j trust2_k ///
		trust3_a trust3_b trust3_c trust3_d ///
		trust3_e trust3_f trust3_g trust3_h ///
		trust3_i trust3_j trust3_k

	foreach var of local tvars {
		cap g y_`var' = .
		cap replace y_`var'=1 if `var'==1
		cap replace y_`var'=0 if `var'==2
	}


/*----------------------------------------------------------------------
  12. SAVE HOUSEHOLD-LEVEL FILE
----------------------------------------------------------------------*/

// generate quintile/decile
    egen quint = xtile(pc_inc_real_spadef), w(popw) n(5) by(mofd)
    egen decile = xtile(pc_inc_real_spadef), w(popw) n(10) by(mofd)

// drop interviewed in after last period (MODIFY LATER)
    drop if mofd>`mofdloc'
    
// save household core data
    format mofd %tm
	save "$source/Anon_HH_L2Indo_Analysisfile_R`rnd'.dta", replace

// Save income temp (for 3-incomes-to-ind.do)
	preserve
	keep hhid mofd pc_inc_real_spadef quint decile 
	duplicates tag hhid mofd, g(dupid)
	save "$temp/incomes_temp.dta", replace
	restore

// Save working file for experiment merges
	save "$temp/hh-l2indo.dta", replace


// /*======================================================================
//   PART D: HH-LEVEL ESTIMATIONS
// ======================================================================*/
//
// /*----------------------------------------------------------------------
//   13. TAXPAYER CHARACTERISTICS (from 202509-analysis)
// ----------------------------------------------------------------------*/
//
// 	foreach Y of varlist govcomm schmeal_pro ecsituation pubschqual righttrack corruption efsubtarget elecqual airpollgov econmanage {
// 		if "`Y'"=="govcomm" {
// 			xtlogit `Y' taxpayer_inc ln_pcinc_hf i.mofd, fe or
// 			outreg2 using "$temp/taxpayerchar", dta ctitle("`Y'") replace     
// 		}
// 		else {
// 			xtlogit `Y' taxpayer_inc ln_pcinc_hf i.mofd, fe or
// 			outreg2 using "$temp/taxpayerchar", dta ctitle("`Y'") 
// 		}
// 	}
//
// 	preserve 
// 		use "$temp/taxpayerchar_dta.dta", clear
// 		export excel using "$temp/taxpayerchar.xls", firstrow(variables) sheet("views", replace)    
// 	restore


// /*----------------------------------------------------------------------
//   14. SAVINGS ELASTICITY (from 202509-analysis)
// ----------------------------------------------------------------------*/
//
// // Panel elasticity by decile — all period
// 	matrix respALL = J(10,5,.)
// 	matrix colnames respALL = decile b_coef l_ci u_ci r2	
// 	forval i=1/10 {
// 		qui reghdfe ln_save ln_income new_member if save_share<=1 & base_decil==`i', absorb(round hhid) cluster(hhid)
// 		local r2 = e(r2_a)
// 		matrix respALL [`i',1] = `i'
// 		matrix respALL [`i',2] = r(table)[1,1]
// 		matrix respALL [`i',3] = r(table)[5,1]		
// 		matrix respALL [`i',4] = r(table)[6,1]				
// 		matrix respALL [`i',5] = `r2'
// 	}
// 	matrix list respALL
//
// // 2024 (Mar - Aug)
// 	matrix resp24 = J(10,5,.)
// 	matrix colnames resp24 = decile b_coef l_ci u_ci r2	
// 	forval i=1/10 {
// 		qui reghdfe ln_save ln_income new_member if inrange(round,1,6) & save_share<=1 & base_decil==`i', absorb(round hhid) cluster(hhid)
// 		local r2 = e(r2_a)
// 		matrix resp24 [`i',1] = `i'
// 		matrix resp24 [`i',2] = r(table)[1,1]
// 		matrix resp24 [`i',3] = r(table)[5,1]		
// 		matrix resp24 [`i',4] = r(table)[6,1]				
// 		matrix resp24 [`i',5] = `r2'
// 	}
//
// // 2025 (Mar - Aug)
// 	matrix resp25 = J(10,5,.)
// 	matrix colnames resp25 = decile b_coef l_ci u_ci r2		
// 	forval i=1/10 {
// 		qui reghdfe ln_save ln_income new_member if inrange(round,13,18) & save_share<=1 & base_decil==`i', absorb(round hhid) cluster(hhid)
// 		local r2 = e(r2_a)
// 		matrix resp25 [`i',1] = `i'
// 		matrix resp25 [`i',2] = r(table)[1,1]
// 		matrix resp25 [`i',3] = r(table)[5,1]		
// 		matrix resp25 [`i',4] = r(table)[6,1]				
// 		matrix resp25 [`i',5] = `r2'
// 	}
// 	matrix list resp24
// 	matrix list resp25	
//
// // Income-savings elasticity by round
// 	matrix rest = J(18,5,.)
// 	matrix colnames rest = round b_coef l_ci u_ci r2
// 	forval t=1/18 {
// 		qui reghdfe ln_save ln_income hhsize new_member if round==`t' & save_share<=1, absorb(district) cluster(hhid)
// 		local r2 = e(r2_a)
// 		matrix rest [`t',1] = `t'
// 		matrix rest [`t',2] = r(table)[1,1]
// 		matrix rest [`t',3] = r(table)[5,1]
// 		matrix rest [`t',4] = r(table)[6,1]	
// 		matrix rest [`t',5] = `r2'	
// 	}
// 	matrix list rest


// /*----------------------------------------------------------------------
//   15. MODULE 14: GAS PRICE REFORM (from 202509-analysis)
// ----------------------------------------------------------------------*/
//
// 	use "$source/anon_l2indo_M14_gasoline.dta", clear
// 	merge 1:1 hhid round using "$temp/hh-l2indo.dta", keepusing(mofd popw ln_pcinc_hf quint taxpayer_inc)
// 	drop if _merge!=3
// 	drop _merge 
// 	save "$temp/202509-M15-gas.dta", replace 
//
// 	use "$temp/202509-M15-gas.dta", clear
// 	forval i=2/5 {
// 		g y_elasticity`i' = .
// 		replace y_elasticity`i' = 1 if inlist(elasticity_supp`i',1,2)
// 		replace y_elasticity`i' = 0 if inlist(elasticity_supp`i',3,4,5)
// 	}
//
// 	forval i=2/5 {
// 		local j = `i'-1
// 		xtlogit y_elasticity`i' i.treat1_rand ln_pcinc_hf prior_belief1 prior_belief2, or
// 		est sto model`j'
// 		if `i'==2 {
// 			outreg2 using "$temp/expfuelsub", dta ctitle("y_elasticity`i'") eform replace 	
// 		}
// 		else {
// 			outreg2 using "$temp/expfuelsub", dta ctitle("y_elasticity`i'") eform  			
// 		}
// 	}
//
// 	preserve 
// 		use "$temp/expfuelsub_dta.dta", clear
// 		export excel using "$temp/expfuelsub.xls", firstrow(variables) sheet("fuelexperiment", replace)    
// 	restore
//
//
// /*----------------------------------------------------------------------
//   16. MODULE 15: COPING STRATEGIES (from 202509-analysis)
// ----------------------------------------------------------------------*/
//
// 	use "$source/anon_l2indo_M15_coping.dta", clear
// 	merge 1:1 hhid round using "$temp/hh-l2indo.dta", keepusing(mofd popw ln_pcinc_hf quint taxpayer_inc)
// 	drop if _merge!=3
// 	drop _merge 
// 	save "$temp/202509-M15-coping.dta", replace 
//
// 	g randomA = randomization1A
// 	g randomB = randomization1B
// 	g randomC = randomization1C
// 	forval i=2/6 {
// 		replace randomA = randomization`i'A
// 		replace randomB = randomization`i'B	
// 		replace randomC = randomization`i'C			
// 	}
//
//
// 	di as result "Household-level file and analyses complete."
// 	log close
