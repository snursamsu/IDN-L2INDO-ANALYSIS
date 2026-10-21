/*==============================================================================
  L2Indo — Thematic Analysis (descriptives + simple regressions)

  Topics
    1. Welfare monitoring: income, saving, borrowing, downturn & expectations
    2. Perception on government policies, prices, food insecurity
    3. Jobs & employment: job security, vulnerability, hardship
    4. Housing module (M20)
    5. Subsidies: Fuel (M14), LPG (M17)
    (Electricity M18 and financial inclusion/fraud parked at the bottom)

  GROUPINGS (created in section 0, used throughout)
    class3   : subjective class from wb32  1 Poor (wb32 1-2)
                                           2 Lower MC (wb32 3)
                                           3 Upper MC (wb32 4-5, incl. Rich)
    welfgrp  : income group from quint    1 Bottom 40 (Q1-2)
                                           2 Middle 40 (Q3-4)
                                           3 Top 20 (Q5)
    quint_cf / welfgrp_cf : same, carrying forward each HH's last observed
               quintile to rounds without income data (used for modules)

  RUN ORDER : 0-weights -> 1-individual -> 2-household -> 3-incomes -> THIS FILE
  OUTPUT    : every table is exported to one Excel file, one sheet per table
              -> "$out/L2Indo_topics.xlsx"
==============================================================================*/

    clear all
    set more off
    cap log close

    local suser = upper(c(username))
	* Sam
	if ("`suser'" == "WB594719") {
        global root "C:\Users\wb594719\OneDrive - WBG\Listening to Indonesia"
        global base "$root\Data\Baseline"
        global base2 "$root\Data\Baseline II Confidential\Data\dta"
        global samp "$root\L2Indo Launch Materials\Sample"
        global gdat "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents"
        global in "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Cleaned data"
        global out "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Output"
        global source "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\Main data"
        global temp "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Temp"
        global dlog "C:\Users\wb594719\OneDrive - WBG\Documents\GitHub\IDN-L2INDO\Log"
	}

    global xls "$out/L2Indo_topics.xlsx"
    global hh  "$source/Anon_HH_L2Indo_Analysisfile_R31.dta"

    * log
    log using "$dlog/5-analysis-topics.smcl", replace

    * periods (mofd: 770 = Mar24, 782 = Mar25, 794 = Mar26)
    local first 770     // Mar 2024
    local last  800     // Sep 2026
    local y24   "inrange(mofd,770,776)"     // Mar-Sep 2024
    local y25   "inrange(mofd,782,788)"     // Mar-Sep 2025
    local y26   "inrange(mofd,794,800)"     // Mar-Sep 2026
    * CV windows: Mar-Jun only, because 2026 income stops in June
    local cv24  "inrange(mofd,770,773)"
    local cv25  "inrange(mofd,782,785)"
    local cv26  "inrange(mofd,794,797)"

    * grouping variables used in the by-group tables below
    local groups class3 welfgrp

    * household data
    use "$hh", clear
    xtset hhid mofd

*==============================================================================
* 0. ADDITIONAL DATA SETUP (safe to re-run: drops before creating)
*==============================================================================
    drop region apply_formal apply_informal

*-----------------------------------------
* Region grouping (BPS province codes)
*-----------------------------------------
    g region = .
    replace region = 1 if inlist(province_id,11,12,13,14,15,16,17,18,19) | province_id==21  // Sumatera (incl. Babel 19, Kepri 21)
    replace region = 2 if inlist(province_id,31,32,33,34,35,36,51)                          // Java-Bali
    replace region = 3 if inlist(province_id,52,53)                                         // Nusa Tenggara (NTB, NTT)
    replace region = 4 if inlist(province_id,61,62,63,64,65)                                // Kalimantan (incl. Kaltara 65)
    replace region = 5 if inlist(province_id,71,72,73,74,75,76)                             // Sulawesi
    replace region = 6 if inlist(province_id,81,82,91,92,94,95,96,97)                       // Maluku-Papua

    cap la drop region
    la def region 1 "Sumatera" 2 "Java-Bali" 3 "Nusa Tenggara" 4 "Kalimantan" 5 "Sulawesi" 6 "Maluku-Papua"
    la val region region
    la var region "Region (BPS province grouping)"

*-----------------------------------------------------------------
* Applied for formal credit (sv14 = source of credit applied for)
*-----------------------------------------------------------------
    g apply_formal = .
    replace apply_formal = 0 if sv12==2                         // did not apply
    replace apply_formal = 1 if sv12==1 & inlist(sv14,1,4)      // formal source
    replace apply_formal = 0 if sv12==1 & inlist(sv14,2,3,5,96) // informal source
    la var apply_formal "Applied for formal credit (0 = no application or informal)"

    g apply_informal = (sv12==1 & inlist(sv14,2,3,5,96)) if sv12!=.
    la var apply_informal "Applied for informal credit"

*-----------------------------------------------------------------
* Subjective class: Poor / Lower MC / Upper MC  (wb32)
*   wb32: 1 very poor 2 poor 3 lower middle 4 upper middle 5 rich
*   Rich is folded into Upper MC (too few obs on its own)
*-----------------------------------------------------------------
    g class3 = .
    replace class3 = 1 if inlist(wb32,1,2)
    replace class3 = 2 if wb32==3
    replace class3 = 3 if inlist(wb32,4,5)
    cap la drop class3
    la def class3 1 "Poor" 2 "Lower MC" 3 "Upper MC"
    la val class3 class3
    la var class3 "Subjective economic class (Poor / Lower MC / Upper MC)"

*-----------------------------------------------------------------
* Income group: Bottom 40 / Middle 40 / Top 20  (from quint)
*-----------------------------------------------------------------
    g welfgrp = .
    replace welfgrp = 1 if inlist(quint,1,2)
    replace welfgrp = 2 if inlist(quint,3,4)
    replace welfgrp = 3 if quint==5
    cap la drop welfgrp
    la def welfgrp 1 "Bottom 40" 2 "Middle 40" 3 "Top 20"
    la val welfgrp welfgrp
    la var welfgrp "Income group (B40 / M40 / T20)"

    * carry forward last observed quintile (for rounds without income yet)
    g quint_cf = quint
    bys hhid (mofd): replace quint_cf = quint_cf[_n-1] if quint_cf==. & _n>1
    la var quint_cf "Income quintile (last available, carried forward)"
    g welfgrp_cf = .
    replace welfgrp_cf = 1 if inlist(quint_cf,1,2)
    replace welfgrp_cf = 2 if inlist(quint_cf,3,4)
    replace welfgrp_cf = 3 if quint_cf==5
    la val welfgrp_cf welfgrp
    la var welfgrp_cf "Income group (B40 / M40 / T20), carried forward"

    * quick checks
    tab wb32 class3, m
    tab quint welfgrp, m
    tab mofd if quint==. & quint_cf!=.      // rounds filled by carry-forward

    save "$hh", replace

*==============================================================================
* 1. WELFARE MONITORING: INCOME, SAVING, BORROWING, DOWNTURN & EXPECTATIONS
*==============================================================================

    use "$hh", clear
    xtset hhid mofd

*---------------------------------------------
* 1a. Financial wellbeing: past vs expected
*---------------------------------------------
    * worse last 30 days vs expect better next 30 days
    table (mofd) () [aw=popw], stat(mean worsefinwb_last befinwb_last worsefinwb_next befinwb_next) nformat(%5.3f)
    collect export "$xls", sheet("1a_finwb_month") modify

    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean befinwb_next) nformat(%5.3f)
        collect export "$xls", sheet("1a_expect_`g'") modify
        table (mofd) (`g') [aw=popw], stat(mean worsefinwb_last) nformat(%5.3f)
        collect export "$xls", sheet("1a_worse_`g'") modify
    }

*---------------------------------------------
* 1b. Expectation gap (expected vs realised)
*---------------------------------------------
    * past_pred = last month's expectation (L.wb2), wb1 = realised
    g exp_gap = wb1 - past_pred
    la var exp_gap "Realised minus expected fin. wellbeing (neg = worse than expected)"
    g better_than_exp = (exp_gap>0)  if exp_gap!=.
    g as_exp          = (exp_gap==0) if exp_gap!=.
    g worse_than_exp  = (exp_gap<0)  if exp_gap!=.
    la var better_than_exp "Realised better than expected"
    la var as_exp          "Realised as expected"
    la var worse_than_exp  "Realised worse than expected"

    table (mofd) () [aw=popw], stat(mean better_than_exp as_exp worse_than_exp) nformat(%5.3f)
    collect export "$xls", sheet("1b_expgap_month") modify

    * unexpected vs total deterioration (expected = total - unexpected)
    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean fin_deterior any_deterfin) nformat(%5.3f)
        collect export "$xls", sheet("1b_deterior_`g'") modify
        * pooled summary (one row per group, easy bar chart)
        table (`g') () [aw=popw], stat(mean fin_deterior any_deterfin worse_than_exp) nformat(%5.3f)
        collect export "$xls", sheet("1b_deterior_`g'_pool") modify
    }

*---------------------------------------------
* 1c. Income levels and volatility
*---------------------------------------------
    * median real per capita income by quintile and by income group
    table (mofd) (quint) [aw=popw], stat(median pc_inc_real_spadef) nformat(%12.0fc)
    collect export "$xls", sheet("1c_inc_quint") modify
    table (mofd) (welfgrp) [aw=popw], stat(median pc_inc_real_spadef) nformat(%12.0fc)
    collect export "$xls", sheet("1c_inc_welfgrp") modify

    * subjective class vs actual income (are self-classified groups aligned?)
    table (class3) () [aw=popw], stat(median pc_inc_real_spadef) nformat(%12.0fc)
    collect export "$xls", sheet("1c_inc_class3") modify
    table (class3) (welfgrp) [aw=popw], stat(percent, across(welfgrp)) nformat(%5.1f)
    collect export "$xls", sheet("1c_class3_x_welfgrp") modify

    * income source participation
    table (mofd) () [aw=popw], stat(mean wage_dum self_emp_dum ag_inc_dum sa_inc_dum pension_dum) nformat(%5.3f)
    collect export "$xls", sheet("1c_inc_source") modify
    foreach g of local groups {
        table (`g') () [aw=popw] if `y26', stat(mean wage_dum self_emp_dum ag_inc_dum sa_inc_dum pension_dum) nformat(%5.3f)
        collect export "$xls", sheet("1c_incsrc_`g'_2026") modify
    }

    * CV of income, comparable Mar-Jun windows
    foreach y in 24 25 26 {
        table (welfgrp) () [aw=popw] if `cv`y'', stat(mean cv_income) nformat(%5.1f)
        collect export "$xls", sheet("1c_cv_welfgrp_20`y'") modify
        table (class3) () [aw=popw] if `cv`y'', stat(mean cv_income) nformat(%5.1f)
        collect export "$xls", sheet("1c_cv_class3_20`y'") modify
    }

*---------------------------------------------
* 1d. Saving and buffers
*---------------------------------------------
    table (mofd) () [aw=popw], stat(mean able_save dissave no_save couldpay) nformat(%5.3f)
    collect export "$xls", sheet("1d_save_month") modify

    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean able_save) nformat(%5.3f)
        collect export "$xls", sheet("1d_save_`g'") modify
        table (mofd) (`g') [aw=popw], stat(mean no_save) nformat(%5.3f)
        collect export "$xls", sheet("1d_nosave_`g'") modify
        table (mofd) (`g') [aw=popw], stat(mean couldpay) nformat(%5.3f)
        collect export "$xls", sheet("1d_couldpay_`g'") modify
    }

    * share of income saved (savers only, trim top 1%)
    _pctile save_share [aw=popw], p(99)
    local p99 = r(r1)
    table (welfgrp) () [aw=popw] if save_share>0 & save_share<=`p99', stat(mean save_share) stat(median save_share) nformat(%5.3f)
    collect export "$xls", sheet("1d_saveshare") modify

*---------------------------------------------
* 1e. Borrowing and debt burden
*---------------------------------------------
    table (mofd) () [aw=popw], stat(mean borrow credit_mnth apply_formal apply_informal credit_exist) nformat(%5.3f)
    collect export "$xls", sheet("1e_borrow_month") modify

    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean borrow) nformat(%5.3f)
        collect export "$xls", sheet("1e_borrow_`g'") modify
        table (mofd) (`g') [aw=popw], stat(mean credit_exist) nformat(%5.3f)
        collect export "$xls", sheet("1e_loan_`g'") modify
        * formal vs informal applications, pooled
        table (`g') () [aw=popw], stat(mean credit_mnth apply_formal apply_informal) nformat(%5.3f)
        collect export "$xls", sheet("1e_apply_`g'") modify
    }

    table (welfgrp) () [aw=popw], stat(median debtratio_for debtratio_inf debtratio_tot) nformat(%5.2f)
    collect export "$xls", sheet("1e_debtratio") modify

*---------------------------------------------
* 1f. Coping with downturn (by deterioration status)
*---------------------------------------------
    * what do HH do when finances worsen? (unexpected vs expected vs none)
    g deter_type = 0 if any_deterfin==0
    replace deter_type = 1 if any_deterfin==1 & fin_deterior==0
    replace deter_type = 2 if fin_deterior==1
    cap la drop deter
    la def deter 0 "No deterioration" 1 "Expected deterioration" 2 "Unexpected deterioration"
    la val deter_type deter
    la var deter_type "Type of financial deterioration"

    table (deter_type) () [aw=popw], stat(mean borrow dissave sell_asset forgo_health food_insec) nformat(%5.3f)
    collect export "$xls", sheet("1f_coping_deter") modify

    * same, split by income group (does B40 cope differently?)
    table (deter_type) (welfgrp) [aw=popw], stat(mean borrow dissave sell_asset forgo_health food_insec) nformat(%5.3f)
    collect export "$xls", sheet("1f_coping_welfgrp") modify

*---------------------------------------------
* 1g. Regressions
*---------------------------------------------
    * (i) what predicts unexpected deterioration? HH FE
    xtreg fin_deterior couldpay able_save credit_exist ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_welfare", excel ctitle("Unexpected deterior.") keep(couldpay able_save credit_exist ln_pcinc_hf) replace

    * (ii) do shocks dampen expectations? HH FE
    xtreg befinwb_next fin_deterior badloc_econ infl_fast worried_job ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_welfare", excel ctitle("Expect better") keep(fin_deterior badloc_econ infl_fast worried_job ln_pcinc_hf)

    * (iii) does a buffer (emergency cash) reduce borrowing after a shock?
    xtreg borrow i.any_deterfin##i.couldpay ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_welfare", excel ctitle("Borrow")

    * (iv) are B40 hit harder by unexpected deterioration? (pooled, group gap net of time)
    reg fin_deterior i.welfgrp i.mofd [pw=popw], vce(cluster hhid)
    outreg2 using "$out/reg_welfare", excel ctitle("Deterior. by group") keep(2.welfgrp 3.welfgrp)


*==============================================================================
* 2. PERCEPTION ON GOVERNMENT POLICIES, PRICES, FOOD INSECURITY
*==============================================================================

*---------------------------------------------
* 2a. Economy & government over time
*---------------------------------------------
    table (mofd) () [aw=popw], stat(mean goodloc_econ optim_econ econmanage right_track open_dialogue enough_corrupt) nformat(%5.3f)
    collect export "$xls", sheet("2a_govview_month") modify

    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean right_track) nformat(%5.3f)
        collect export "$xls", sheet("2a_righttrack_`g'") modify
        table (mofd) (`g') [aw=popw], stat(mean econmanage) nformat(%5.3f)
        collect export "$xls", sheet("2a_econmanage_`g'") modify
    }

*---------------------------------------------
* 2b. Price perception
*---------------------------------------------
    table (mofd) () [aw=popw], stat(mean infl_fast infl_norm infl_slow rising_prices) nformat(%5.3f)
    collect export "$xls", sheet("2b_infl_perc") modify

    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean infl_fast) nformat(%5.3f)
        collect export "$xls", sheet("2b_inflfast_`g'") modify
    }

*---------------------------------------------
* 2c. Food insecurity (FIES)
*---------------------------------------------
    table (mofd) () [aw=popw], stat(mean fies_mild fies_moderate fies_severe) nformat(%5.3f)
    collect export "$xls", sheet("2c_fies_month") modify

    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean fies_moderate) nformat(%5.3f)
        collect export "$xls", sheet("2c_fiesmod_`g'") modify
    }

    * FIES by price perception
    table (infl_fast) () [aw=popw], stat(mean fies_mild fies_moderate fies_severe) nformat(%5.3f)
    collect export "$xls", sheet("2c_fies_infl") modify

    * FIES by region
    table (region) () [aw=popw], stat(mean fies_mild fies_moderate fies_severe) nformat(%5.3f)
    collect export "$xls", sheet("2c_fies_region") modify

*---------------------------------------------
* 2d. Regressions: what drives approval of economic policy?
*---------------------------------------------
    xtreg right_track infl_fast food_insec fin_deterior worried_job goodloc_econ ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_perception", excel ctitle("Right track (FE)") keep(infl_fast food_insec fin_deterior worried_job goodloc_econ ln_pcinc_hf) replace

    xtreg econmanage infl_fast food_insec fin_deterior worried_job goodloc_econ ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_perception", excel ctitle("Econ manage (FE)") keep(infl_fast food_insec fin_deterior worried_job goodloc_econ ln_pcinc_hf)

    * food insecurity score and perceived inflation
    xtreg totfoodinsec infl_fast fin_deterior borrow ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_perception", excel ctitle("FIES score (FE)") keep(infl_fast fin_deterior borrow ln_pcinc_hf)


*==============================================================================
* 3. JOBS & EMPLOYMENT: SECURITY, VULNERABILITY, HARDSHIP
*==============================================================================

*---------------------------------------------
* 3a. HH-level job perceptions
*---------------------------------------------
    table (mofd) () [aw=popw], stat(mean worried_job goodtime_job goodtime_bus) nformat(%5.3f)
    collect export "$xls", sheet("3a_jobview_month") modify

    foreach g of local groups {
        table (mofd) (`g') [aw=popw], stat(mean worried_job) nformat(%5.3f)
        collect export "$xls", sheet("3a_jobworry_`g'") modify
        table (mofd) (`g') [aw=popw], stat(mean goodtime_job) nformat(%5.3f)
        collect export "$xls", sheet("3a_goodtimejob_`g'") modify
    }

    * job worry vs vulnerability
    table (worried_job) () [aw=popw], stat(mean cv_income fin_deterior able_save couldpay) nformat(%5.3f)
    collect export "$xls", sheet("3a_jobworry_vuln") modify

    * does job worry hurt buffers more in B40?
    table (worried_job) (welfgrp) [aw=popw], stat(mean fin_deterior couldpay) nformat(%5.3f)
    collect export "$xls", sheet("3a_jobworry_vuln_wg") modify

*---------------------------------------------
* 3b. Individual-level employment (15-62)
*---------------------------------------------
preserve
    use "$source/Anon_IND_L2Indo_Analysisfile_R31.dta", clear
    format mofd %tm

    * bring HH groupings to individuals
    cap drop class3 welfgrp
    merge m:1 hhid mofd using "$hh", keepusing(class3 welfgrp) keep(1 3) nogen

    table (mofd) () [aw=indw], stat(mean ind_work unemp) nformat(%5.3f)
    collect export "$xls", sheet("3b_emp_month") modify

    table (mofd) (female) [aw=indw], stat(mean ind_work unemp) nformat(%5.3f)
    collect export "$xls", sheet("3b_emp_gender") modify

    * job transitions: employed last month -> status this month
    xtset uniqueid mofd
    g work_lag = L.ind_work
    la var work_lag "Worked last month"
    g job_loss = (work_lag==1 & ind_work==0) if work_lag==1 & ind_work!=.
    g job_find = (work_lag==0 & ind_work==1) if work_lag==0 & ind_work!=.
    la var job_loss "Lost job (worked last month, not this month)"
    la var job_find "Found job (not working last month, working now)"
    table (mofd) () [aw=indw], stat(mean job_loss job_find) nformat(%5.3f)
    collect export "$xls", sheet("3b_jobflows") modify

    foreach g of local groups {
        * employment / unemployment by group over time
        table (mofd) (`g') [aw=indw], stat(mean ind_work) nformat(%5.3f)
        collect export "$xls", sheet("3b_emp_`g'") modify
        * job flows, pooled by year (monthly cells too small by group)
        g yr = year(dofm(mofd))
        table (yr) (`g') [aw=indw], stat(mean job_loss job_find) nformat(%5.3f)
        collect export "$xls", sheet("3b_jobflows_`g'") modify
        drop yr
        * gender gap by group
        table (`g') (female) [aw=indw] if `y26', stat(mean ind_work) nformat(%5.3f)
        collect export "$xls", sheet("3b_empgender_`g'") modify
    }

    * who is more likely to lose a job? (pooled, AME)
    logit job_loss female i.welfgrp i.mofd [pw=indw], vce(cluster hhid)
    margins, dydx(female welfgrp) post
    outreg2 using "$out/reg_jobs", excel ctitle("Job loss (AME)") replace

    * who finds work again?
    logit job_find female i.welfgrp i.mofd [pw=indw], vce(cluster hhid)
    margins, dydx(female welfgrp) post
    outreg2 using "$out/reg_jobs", excel ctitle("Job find (AME)")
restore

*---------------------------------------------
* 3c. Does job worry predict lower saving / more borrowing? (HH FE)
*---------------------------------------------
    xtreg able_save worried_job ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_jobs", excel ctitle("Able to save") keep(worried_job ln_pcinc_hf)
    xtreg borrow worried_job ln_pcinc_hf i.mofd, fe vce(cluster hhid)
    outreg2 using "$out/reg_jobs", excel ctitle("Borrow") keep(worried_job ln_pcinc_hf)


*==============================================================================
* 4. HOUSING (M20)
*==============================================================================
    use "$source/anon_l2indo_M20_housing.dta", clear
    merge 1:1 hhid round using "$hh", keepusing(mofd popw quint quint_cf class3 welfgrp welfgrp_cf ln_pcinc_hf province_id region)
    keep if _merge==3
    drop _merge

*---------------------------------------------
* 4a. Housing needs, plans, barriers
*---------------------------------------------
    * main housing need (house3), plans (house4)
    foreach v in house3 house4 house6 {
        table (`v') (quint) [aw=popw], stat(percent, across(`v'))
        collect export "$xls", sheet("4a_`v'_quint") modify
    }

    * barriers (house5)
    * barrier distribution by quintile (column % sums to 100 within quintile)
    table (house5) (quint) [aw=popw], stat(percent, across(house5)) nformat(%5.1f)
    collect export "$xls", sheet("4a_barrier_quint") modify

//     * same, urban vs rural
//     table (house5) (urban) [aw=popw], stat(percent, across(house5)) nformat(%5.1f)
//     collect export "$xls", sheet("4a_barrier_urban") modify

    * grouped: financial barrier (savings/DP, costs, financing) vs other
    g barrier_fin = inlist(house5,1,2,4) if house5!=.
    la var barrier_fin "Main barrier is financial (savings/DP, cost, financing)"
    table (quint) () [aw=popw], stat(mean barrier_fin) nformat(%5.3f)
    collect export "$xls", sheet("4a_barrier_fin") modify
    
    * THREE most important factors (house8): multiselect
    table () (quint) [aw=popw], stat(mean house8*) nformat(%5.3f)
    collect export "$xls", sheet("4a_factors") modify

    * program awareness (house7: BSPS, FLPP, Rusunawa, ...)
    table () (quint) [aw=popw], stat(mean house7A house7B house7C house7D house7Y) nformat(%5.3f)
    collect export "$xls", sheet("4a_awareness") modify

*---------------------------------------------
* 4b. Experiment 1: renovation grant vs public housing
*---------------------------------------------
    * randomized arms (strings -> 0/1)
    g exp1_grant50 = (house_exp1a=="Rp50 Juta") if house_exp1a!=""
    la var exp1_grant50 "Exp1: renovation grant Rp50 juta (vs Rp20 juta)"
    la def grant 0 "Rp20 juta" 1 "Rp50 juta"
    la val exp1_grant50 grant

    g exp1_apart = strpos(house_exp1b,"apartemen")>0 if house_exp1b!=""
    la var exp1_apart "Exp1: apartment near city center (vs landed house far)"
    la def htype 0 "Landed, far" 1 "Apartment, central"
    la val exp1_apart htype

    g exp1_rent800 = (house_exp1c=="Rp800.000") if house_exp1c!=""
    la var exp1_rent800 "Exp1: rent Rp800k (vs Rp300k)"
    la def rent 0 "Rp300k" 1 "Rp800k"
    la val exp1_rent800 rent

    * check balance: each cell ~1/8 of sample
    table (exp1_grant50 exp1_apart) (exp1_rent800), stat(freq)
    
    * outcome
    g choose_reno   = (house_exp1==1) if house_exp1!=.
    g choose_public = (house_exp1==2) if house_exp1!=.
    g choose_none   = (house_exp1==3) if house_exp1!=.
    la var choose_reno   "Exp1: chooses renovation subsidy"
    la var choose_public "Exp1: chooses public housing"
    la var choose_none   "Exp1: chooses neither"

    * shares by each arm (for bar charts)
    foreach a in exp1_grant50 exp1_apart exp1_rent800 {
        table (`a') () [aw=popw], stat(mean choose_reno choose_public choose_none) nformat(%5.3f)
        collect export "$xls", sheet("4b_`a'") modify
    }

    * full 2x2x2 cells
    table (exp1_apart exp1_rent800) (exp1_grant50) [aw=popw], stat(mean choose_public) nformat(%5.3f)
    collect export "$xls", sheet("4b_exp1_cells") modify

    * effects (LPM, robust)
    reg choose_public exp1_grant50 exp1_apart exp1_rent800 [pw=popw], robust
    outreg2 using "$out/reg_housing", excel ctitle("Exp1: public housing") replace
    reg choose_public exp1_grant50 exp1_apart exp1_rent800 ln_pcinc_hf [pw=popw], robust
    outreg2 using "$out/reg_housing", excel ctitle("Exp1: + income")

    * heterogeneity: does a bigger grant matter more for B40?
    g b40 = (quint<=2) if quint!=.
    reg choose_public i.exp1_grant50##i.b40 exp1_apart exp1_rent800 [pw=popw], robust
    outreg2 using "$out/reg_housing", excel ctitle("Exp1 x B40")
    
    * check significance 
    reg choose_public exp1_grant50 exp1_apart exp1_rent800, ro
    outreg2 using "$out/reg_housing", excel ctitle("Exp 1: sign")    

*---------------------------------------------
* 4c. Experiment 2: credit subsidy (existing house) vs new public housing
*---------------------------------------------
    * randomized arms (strings -> 0/1)
    g exp2_mort1m = (house_exp2a=="Rp1.000.000") if house_exp2a!=""
    la var exp2_mort1m "Exp2: subsidized mortgage Rp1jt/month (vs Rp500k)"
    la def mort 0 "Rp500k" 1 "Rp1jt"
    la val exp2_mort1m mort

    g exp2_goodamen = strpos(lower(house_exp2b),"lengkap")>0 if house_exp2b!=""
    la var exp2_goodamen "Exp2: public housing with complete amenities (vs basic)"
    la def amen 0 "Basic amenities" 1 "Complete amenities"
    la val exp2_goodamen amen

    g exp2_rent800 = (house_exp2c=="Rp800.000") if house_exp2c!=""
    la var exp2_rent800 "Exp2: public housing rent Rp800k (vs Rp400k)"
    la def rent2 0 "Rp400k" 1 "Rp800k"
    la val exp2_rent800 rent2

    * check balance: each cell ~1/8 of sample
    table (exp2_mort1m exp2_goodamen) (exp2_rent800), stat(freq)

    * outcome
    g choose_credit  = (house_exp2==1) if house_exp2!=.
    g choose_newpub  = (house_exp2==2) if house_exp2!=.
    g choose_none2   = (house_exp2==3) if house_exp2!=.
    la var choose_credit "Exp2: chooses credit subsidy for existing house"
    la var choose_newpub "Exp2: chooses new public housing"
    la var choose_none2  "Exp2: chooses neither"

    * shares by each arm (for bar charts)
    foreach a in exp2_mort1m exp2_goodamen exp2_rent800 {
        table (`a') () [aw=popw], stat(mean choose_credit choose_newpub choose_none2) nformat(%5.3f)
        collect export "$xls", sheet("4c_`a'") modify
    }

    * full 2x2x2 cells
    table (exp2_goodamen exp2_rent800) (exp2_mort1m) [aw=popw], stat(mean choose_newpub) nformat(%5.3f)
    collect export "$xls", sheet("4c_exp2_cells") modify

    * effects (LPM, robust)
    reg choose_newpub exp2_mort1m exp2_goodamen exp2_rent800 [pw=popw], robust
    outreg2 using "$out/reg_housing", excel ctitle("Exp2: new public housing")
    reg choose_newpub exp2_mort1m exp2_goodamen exp2_rent800 ln_pcinc_hf [pw=popw], robust
    outreg2 using "$out/reg_housing", excel ctitle("Exp2: + income")

    * heterogeneity: are B40 more sensitive to rent? (b40 created in 4b)
    reg choose_newpub i.exp2_rent800##i.b40 exp2_mort1m exp2_goodamen [pw=popw], robust
    outreg2 using "$out/reg_housing", excel ctitle("Exp2 x B40")

    * check significance
    reg choose_newpub exp2_mort1m exp2_goodamen exp2_rent800, robust    
    outreg2 using "$out/reg_housing", excel ctitle("Exp 2: sign")
    
*==============================================================================
* 5. SUBSIDIES: FUEL (M14), LPG (M17), ELECTRICITY (M18)
*==============================================================================
* Key questions per subsidy: (1) who uses it  (2) targeting by quintile
*                            (3) access/ease  (4) support for reform

*---------------------------------------------
* 5a. Fuel (M14 gasoline)
*---------------------------------------------
    use "$source/anon_l2indo_M14_gasoline.dta", clear
    merge 1:1 hhid round using "$hh", keepusing(mofd popw quint quint_cf class3 welfgrp welfgrp_cf ln_pcinc_hf province_id region)
    keep if _merge==3
    drop _merge

    * fuel type used now vs 6 months ago
    table (gasoline_type1) (quint) [aw=popw], stat(percent, across(gasoline_type1))
    collect export "$xls", sheet("5a_fueltype_now") modify
    table (gasoline_type1) (gasoline_type2) [aw=popw], stat(percent)
    collect export "$xls", sheet("5a_fueltype_switch") modify

    * access now (4-scale) and vs 6 months ago (5-scale)
    g fuel_hard    = inlist(gasoline_acc1,3,4) if inrange(gasoline_acc1,1,4)
    g fuel_harder  = inlist(gasoline_acc2,4,5) if inrange(gasoline_acc2,1,5)
    la var fuel_hard   "Difficult to get fuel now"
    la var fuel_harder "Harder to get fuel than 6 months ago"
    table (quint) () [aw=popw], stat(mean fuel_hard fuel_harder) nformat(%5.3f)
    collect export "$xls", sheet("5a_fuelaccess") modify

    * subsidy capture: share of Pertalite users by quintile (incidence)
    g pertalite = (gasoline_type1==1) if inrange(gasoline_type1,1,4)
    table (quint) () [aw=popw] if pertalite==1, stat(freq) stat(percent)
    collect export "$xls", sheet("5a_pertalite_incid") modify

*---------------------------------------------
* 5b. LPG (M17)
*---------------------------------------------
    use "$source/anon_l2indo_M17_lpg.dta", clear
    merge 1:1 hhid round using "$hh", keepusing(mofd popw quint quint_cf class3 welfgrp welfgrp_cf ln_pcinc_hf province_id region)
    keep if _merge==3
    drop _merge

    local q quint_cf     // last observed quintile (M17 round may have no income yet)
    g b40 = (`q'<=2) if `q'!=.
    la var b40 "Bottom 40% (income quintile 1-2)"

*---------------------------------------------
* 5b-1. Who buys 3kg LPG (use + incidence)
*---------------------------------------------
    g lpg_buy = (lpg_use1==1) if inlist(lpg_use1,1,2)
    la var lpg_buy "Bought 3kg LPG in last 30 days"

    * coverage: share of each quintile buying 3kg
    table (`q') () [aw=popw], stat(mean lpg_buy) nformat(%5.3f)
    collect export "$xls", sheet("5b_lpg_use_quint") modify

    * incidence: distribution of 3kg buyers across quintiles (sums to 100)
    table (`q') () [aw=popw] if lpg_buy==1, stat(percent) nformat(%5.1f)
    collect export "$xls", sheet("5b_lpg_incid") modify

*---------------------------------------------
* 5b-2. Purchase experience (buyers only)
*---------------------------------------------
    * ease: 1 very easy ... 4 very difficult
    g lpg_hard = inlist(lpg_use2,3,4) if inrange(lpg_use2,1,4)
    la var lpg_hard "Buying 3kg LPG is difficult"

    * KTP check: 1 own KTP, 2 someone else's KTP, 3 not asked
    g ktp_own   = (lpg_use3==1) if inrange(lpg_use3,1,3)
    g ktp_other = (lpg_use3==2) if inrange(lpg_use3,1,3)
    g ktp_none  = (lpg_use3==3) if inrange(lpg_use3,1,3)
    la var ktp_own   "Showed own KTP"
    la var ktp_other "Showed someone else's KTP"
    la var ktp_none  "KTP not asked"

    * outlet: 1 official pangkalan, 2 warung/reseller
    g buy_warung = (lpg_use4==2) if inlist(lpg_use4,1,2)
    la var buy_warung "Bought at non-official reseller/warung"

    table (`q') () [aw=popw] if lpg_buy==1, stat(mean lpg_hard ktp_own ktp_other ktp_none buy_warung) nformat(%5.3f)
    collect export "$xls", sheet("5b_lpg_buyexp_quint") modify

    * is KTP checked less at warung? (enforcement gap)
    table (lpg_use4) () [aw=popw] if lpg_buy==1, stat(mean ktp_own ktp_other ktp_none lpg_hard) nformat(%5.3f)
    collect export "$xls", sheet("5b_lpg_outlet_ktp") modify

*---------------------------------------------
* 5b-3. Price paid (refill), pangkalan vs warung
*---------------------------------------------
    * lpg_use5 is select_multiple (A new, B refill); amounts in _new / _refill
    g p_refill = lpg_use5_refill
    replace p_refill = . if p_refill<10000 | p_refill>50000     // trim implausible
    la var p_refill "Price paid for last 3kg refill (Rp)"

    table (lpg_use4) (b40) [aw=popw] if lpg_buy==1, stat(median p_refill) stat(mean p_refill) nformat(%9.0fc)
    collect export "$xls", sheet("5b_lpg_price_outlet") modify

    table (region) () [aw=popw] if lpg_buy==1, stat(median p_refill) nformat(%9.0fc)
    collect export "$xls", sheet("5b_lpg_price_region") modify

    * warung premium, controlling for region
    reg p_refill buy_warung i.region [pw=popw] if lpg_buy==1, robust
    outreg2 using "$out/reg_lpg", excel ctitle("Refill price (Rp)") keep(buy_warung) replace

*---------------------------------------------
* 5b-4. Perceived fairness and leakage
*---------------------------------------------
    * lpg_use6: 1 strongly agree ... 5 strongly disagree
    g lpg_fair = inlist(lpg_use6,1,2) if inrange(lpg_use6,1,5)
    la var lpg_fair "Agree KTP requirement is fair / reaches the needy"
    * lpg_use7: 1 often 2 sometimes 3 rarely 4 never 5 DK
    g see_leak = inlist(lpg_use7,1,2) if inrange(lpg_use7,1,4)
    la var see_leak "Often/sometimes sees non-eligible buying 3kg"

    table (`q') () [aw=popw], stat(mean lpg_fair see_leak) nformat(%5.3f)
    collect export "$xls", sheet("5b_lpg_fair_quint") modify

    * do people who see leakage think the system is less fair?
    table (see_leak) () [aw=popw], stat(mean lpg_fair) nformat(%5.3f)
    collect export "$xls", sheet("5b_lpg_fair_leak") modify

*---------------------------------------------
* 5b-5. Coping if 3kg LPG becomes harder to get
*---------------------------------------------
    * lpg_cope1: 1 a lot 2 somewhat 3 a little 4 not at all
    g lpg_impact = (lpg_cope1==1) if inrange(lpg_cope1,1,4)
    la var lpg_impact "Daily life affected 'a lot' if 3kg harder to get"

    * lpg_cope2: select_multiple string (A-G)
    * CHECK: if your export has dummies instead (e.g. lpg_cope2_A), use those
    g cope_cookless = strpos(lpg_cope2,"A")>0 if lpg_cope2!=""
    g cope_switch   = strpos(lpg_cope2,"B")>0 if lpg_cope2!=""
    g cope_efficient= strpos(lpg_cope2,"C")>0 if lpg_cope2!=""
    g cope_cutother = strpos(lpg_cope2,"D")>0 if lpg_cope2!=""
    g cope_borrow   = strpos(lpg_cope2,"E")>0 if lpg_cope2!=""
    g cope_buyfood  = strpos(lpg_cope2,"F")>0 if lpg_cope2!=""
    g cope_nouse    = strpos(lpg_cope2,"G")>0 if lpg_cope2!=""
    la var cope_cookless  "Cook less / smaller portions"
    la var cope_switch    "Switch fuel (kerosene, firewood, electric)"
    la var cope_efficient "Use LPG more efficiently"
    la var cope_cutother  "Cut other spending to pay for gas"
    la var cope_borrow    "Borrow / help from relatives"
    la var cope_buyfood   "Buy cooked food outside"
    la var cope_nouse     "Does not use 3kg LPG"

    table (`q') () [aw=popw] if cope_nouse==0, stat(mean lpg_impact cope_cookless cope_switch cope_efficient cope_cutother cope_borrow cope_buyfood) nformat(%5.3f)
    collect export "$xls", sheet("5b_lpg_coping_quint") modify

    * where should savings go (lpg_cope3)
    table (lpg_cope3) (b40) [aw=popw], stat(percent, across(lpg_cope3)) nformat(%5.1f)
    collect export "$xls", sheet("5b_lpg_savings_use") modify

**# FIX!
// *---------------------------------------------
// * 5b-6. Reform experiment (lpg_use8_1 - lpg_use8_5)
// *       each respondent randomly sees 3 of 5 scenarios
// *       1 cash + immediate price   2 cash + gradual price   3 stricter KTP + ban warung
// *       4 digital ID + quota       5 two-tier price (non-eligible pay 12kg-equivalent)
// *---------------------------------------------
// preserve
//     keep hhid popw `q' b40 lpg_buy see_leak lpg_fair lpg_use8_1-lpg_use8_5
//     cap drop lpg_use8_rand                   // randomizer string, not a scenario
//     reshape long lpg_use8_, i(hhid) j(scenario)
//     drop if !inrange(lpg_use8_,1,5)          // not shown / missing
//
//     g support = inlist(lpg_use8_,1,2)
//     g oppose  = inlist(lpg_use8_,4,5)
//     la var support "Supports policy"
//     la var oppose  "Opposes policy"
//     la def lpgscen 1 "Cash + immediate price" 2 "Cash + gradual price" ///
//                    3 "Stricter KTP + ban warung" 4 "Digital ID + quota" ///
//                    5 "Two-tier price"
//     la val scenario lpgscen
//
//     * check randomization: each scenario ~60% of respondents
//     tab scenario
//
//     table (scenario) () [aw=popw], stat(mean support oppose) stat(freq) nformat(%5.3f)
//     collect export "$xls", sheet("5b_lpg_reform") modify
//
//     table (scenario) (b40) [aw=popw], stat(mean support) nformat(%5.3f)
//     collect export "$xls", sheet("5b_lpg_reform_b40") modify
//
//     * support relative to scenario 1 (immediate), SE clustered by HH
//     * report unweighted as main (randomized), weighted as check
//     reg support ib1.scenario, vce(cluster hhid)
//     outreg2 using "$out/reg_lpg", excel ctitle("Support (unweighted)")
//     reg support ib1.scenario [pw=popw], vce(cluster hhid)
//     outreg2 using "$out/reg_lpg", excel ctitle("Support (weighted)")
//
//     * do B40 / LPG buyers react differently?
//     reg support ib1.scenario##i.b40, vce(cluster hhid)
//     outreg2 using "$out/reg_lpg", excel ctitle("Support x B40")
//     reg support ib1.scenario##i.lpg_buy, vce(cluster hhid)
//     outreg2 using "$out/reg_lpg", excel ctitle("Support x 3kg buyer")
// restore

// *---------------------------------------------
// * 5c. Electricity (M18)
// *---------------------------------------------
//     use "$source/anon_l2indo_M18_electricity.dta", clear
//     merge 1:1 hhid round using "$source/Anon_HH_L2Indo_Analysisfile_R31.dta", keepusing(mofd popw quint eclass eclass1 eclass2 ln_pcinc_hf urban province_id region)
//     keep if _merge==3
//     drop _merge
//
//     * CHECK: rename to your codes
//     *   el_va    : connection capacity (450 / 900 / 1300 VA+)
//     *   el_subs  : receives subsidized tariff (1/0)
//     *   el_bill  : monthly electricity bill (Rp)
//     *   el_token : prepaid (token) vs postpaid
//     table (el_va) (quint) [aw=popw], stat(percent, across(el_va))
//     collect export "$xls", sheet("5c_elec_va_quint") modify
//
//     table (quint) () [aw=popw], stat(mean el_subs) stat(median el_bill) nformat(%9.2f)
//     collect export "$xls", sheet("5c_elec_subs") modify
//
//     * bill as share of income
//     merge 1:1 hhid mofd using "$temp/hh-l2indo.dta", keepusing(hh_inc_nom) keep(1 3) nogen
//     g el_share = el_bill/hh_inc_nom
//     la var el_share "Electricity bill as share of HH income"
//     table (quint) () [aw=popw], stat(median el_share) nformat(%5.3f)
//     collect export "$xls", sheet("5c_elec_burden") modify
//
//     * inclusion/exclusion errors (B40 should be subsidized)
//     g b40 = (quint<=2) if quint!=.
//     table (b40) (el_subs) [aw=popw], stat(percent, across(el_subs))
//     collect export "$xls", sheet("5c_elec_targeting") modify


// *==============================================================================
// * 6. FINANCIAL INCLUSION, FRAUD AND SCAMS
// *==============================================================================
//     use "$source/Anon_HH_L2Indo_Analysisfile_R31.dta", clear
//     xtset hhid mofd
//
// *---------------------------------------------
// * 6a. Inclusion
// *---------------------------------------------
//     g any_acct = (useacct==1 | mobmoney==1) if useacct!=. | mobmoney!=.
//     la var any_acct "Used bank account or mobile money"
//
//     table (mofd) () [aw=popw], stat(mean useacct mobmoney any_acct save_formal save_mobile) nformat(%5.3f)
//     collect export "$xls", sheet("6a_incl_month") modify
//
//     table (quint) () [aw=popw] if `y26', stat(mean useacct mobmoney any_acct apply_formal obtain_credit) nformat(%5.3f)
//     collect export "$xls", sheet("6a_incl_quint") modify
//
//     * formal vs informal borrowing by quintile
//     table (quint) () [aw=popw] if credit_mnth==1, stat(mean apply_formal) nformat(%5.3f)
//     collect export "$xls", sheet("6a_formalloan_quint") modify
//
// *---------------------------------------------
// * 6b. Fraud & scams
// *---------------------------------------------
//     * CHECK: rename to your codes in M08 (savings/finance)
//     *   fraud_any  : HH experienced fraud/scam attempt (1/0)
//     *   fraud_loss : lost money to fraud (1/0)
//     *   fraud_amt  : amount lost (Rp)
//     *   fraud_chan : channel (phone/SMS, WhatsApp, social media, online loan, ...)
//     table (mofd) () [aw=popw], stat(mean fraud_any fraud_loss) nformat(%5.3f)
//     collect export "$xls", sheet("6b_fraud_month") modify
//
//     table (quint) () [aw=popw], stat(mean fraud_any fraud_loss) nformat(%5.3f)
//     collect export "$xls", sheet("6b_fraud_quint") modify
//
//     * loss relative to income (victims only)
//     g fraud_share = fraud_amt/hh_inc_nom if fraud_loss==1
//     la var fraud_share "Fraud loss as share of monthly HH income"
//     table (quint) () [aw=popw], stat(median fraud_share) nformat(%5.2f)
//     collect export "$xls", sheet("6b_fraud_burden") modify
//
//     table (fraud_chan) (quint) [aw=popw], stat(percent, across(fraud_chan))
//     collect export "$xls", sheet("6b_fraud_channel") modify
//
//     * by financial instrument used (formal vs least formal)
//     table (useacct mobmoney) () [aw=popw], stat(mean fraud_any fraud_loss) nformat(%5.3f)
//     collect export "$xls", sheet("6b_fraud_instr") modify
//
// *---------------------------------------------
// * 6c. Regressions
// *---------------------------------------------
//     * who is exposed to fraud? (pooled logit, marginal effects)
//     logit fraud_loss useacct mobmoney i.quint urban i.mofd, vce(cluster hhid)
//     margins, dydx(useacct mobmoney) post
//     outreg2 using "$out/reg_finance", excel ctitle("Fraud loss (AME)") replace
//
//     * does fraud push HH into deterioration / borrowing next month?
//     g fraud_lag = L.fraud_loss
//     xtreg any_deterfin fraud_lag ln_pcinc_hf i.mofd, fe vce(cluster hhid)
//     outreg2 using "$out/reg_finance", excel ctitle("Deterior. t+1") keep(fraud_lag ln_pcinc_hf)
//     xtreg borrow fraud_lag ln_pcinc_hf i.mofd, fe vce(cluster hhid)
//     outreg2 using "$out/reg_finance", excel ctitle("Borrow t+1") keep(fraud_lag ln_pcinc_hf)
//
//     * does account access improve resilience (emergency cash)?
//     xtreg couldpay any_acct ln_pcinc_hf i.mofd, fe vce(cluster hhid)
//     outreg2 using "$out/reg_finance", excel ctitle("Could pay 300k") keep(any_acct ln_pcinc_hf)
//
//
//

    di as result "Topic analysis complete. Tables in $xls"
    log close
