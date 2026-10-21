/*==============================================================================
  L2Indo Baseline II — Cleaning for base welfare data
  
  CONTEXT:
  Dofile for creating base welfare data for panel survey weighting purpose.
  Consisting of income, household, demographic info, and spatial deflation
  
  AUTHOR: Samuel Nursamsu
  
  VERSION: March 30, 2026
==============================================================================*/

//Set locals
	local rnd 25
	local date 20261003
	local cpi 2
	local mofdloc 794 /// March 2026

/*----------------------------------------------------------------------
  SECTION 1: Set work directory
----------------------------------------------------------------------*/    

* Globals
    local suser = upper(c(username))

* Sam 
if ("`suser'" == "WB594719") {
	global root "C:\Users\wb594719\OneDrive - WBG\Listening to Indonesia"
	global base "$root\Data\Baseline"
    global base2 "$root\Data\Baseline II Confidential\Data\dta"
	global samp "$root\L2Indo Launch Materials\Sample"
    global gdat "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents"
	global in "$root\Data\Clean"
	global out "$root\L2Indo Team Folder\Analysis"    
    }
    
/*----------------------------------------------------------------------
  SECTION 2: Set up data
----------------------------------------------------------------------*/        

* individual demographics data
*-----------------------------
    use "$base2/Module1IndivInfo.dta", clear
    * get non registered individual in KK (family ID card)
    g non_reg = m1c12
    recode non_reg (3=1) (1=0)
    destring hhid, replace
    * age    
    g age = m1c5a
        destring age, replace
    g child0_5 = inrange(age,0,4)
    g child0_18 = inrange(age,0,17)
    * disability
    g disability = 0
    replace disability = 1 if !inlist(1,m1c16a,m1c16b,m1c16c,m1c16d,m1c16e,m1c16f)
    * household size 
    g hhsize = 1
    * collapse to household data
    collapse (sum) non_reg child0_5 child0_18 disability hhsize, by(hhid)
    
    * temp save
    *----------
    tempfile hh_welf
    save `hh_welf'
    
* area & income/welfare data
*---------------------------
    use "$base2/MAIN DATA - MODUL 1. INFORMASI UMUM RUMAH TANGGA.dta", clear
    * set local for income
    local incomelist m1e69a_i m1e69b_i m1e69c_i m1e69d_i m1e69e_i m1e69f_i m1e69g_i m1e69h_i m1e69i_i m1e69j_i m1e69k_i m1e69l_i m1e69v_i
    * set hhid and keep important variables
    g hhid = m1b9_rev
    keep hhid m1b1 m1b2 m1b5 `incomelist' 
    * area rename set
    rename m1b1 province
        replace province = proper(province)
    rename m1b2 district
        replace district = proper(district)
    g urban = 1 if m1b5=="PERKOTAAN"
        replace urban = 0 if m1b5=="PERDESAAN"
        drop m1b5
        
    * get area name
    *--------------
    drop if district ==""
    ren district shapeName
    * Fix spacing issue for BATAM and DUMAI
    replace shapeName = "Batam" if shapeName == "B A T A M"
    replace shapeName = "Dumai" if shapeName == "D U M A I"
    * Fix Palu to match the KabNames format
    replace shapeName = "Kota Palu" if shapeName == "Palu"
    * set for fuzzy merge
    preserve
        use "$base2/KabNames.dta", clear
        gen id_u = _n
        tempfile kabnames
        save `kabnames'
    restore
    g id_m = _n
    * fuzzy merge
    reclink2 shapeName using `kabnames', idm(id_m) idu(id_u) gen(mscore) many          // get area code
    rename shapeName district
    drop UshapeName id_m mscore id_u name_simple_bps _merge
    * some cleanings and rearrangement
    rename prov province_id
    rename kab district_id    
    order hhid province province_id district district_id bps_code urban, first
    
    * income data
    *------------
    * replace missing income to 0
    foreach v of local incomelist {
        replace `v' = 0 if `v'==.
    } 
    * generate total income
    egen tot_inc = rowtotal(`incomelist')
    drop `incomelist'
    
    * temp save
    *----------
    tempfile hh_inc
    save `hh_inc'

    
* get spatial deflator and make deflated income
*----------------------------------------------
/*----------------------------------------------
    2025 spatial deflator uses 2024 region code, 
    expansion in papua
------------------------------------------------*/
    * crosswalk to 2024
    *------------------
    preserve
        use "$gdat/Crosswalk/crosswalk-kabupaten-2024.dta", clear
        keep if year == 2024
        * keep only variables needed for merge
        keep bps_code_all bps_code prov kab
        ren bps_code bps_code_2024
        ren prov prov_2024
        ren kab kab_2024
        * verify no duplicates
        isid bps_code_all
        * temp save
        tempfile crosswalk_2024
        save `crosswalk_2024'
    restore
    
    * get spatial deflator 2025
    *--------------------------
    g bps_code_all = province_id*100+district_id
    * merge to get 2024 area code
    merge m:1 bps_code_all using `crosswalk_2024', keepusing(bps_code_2024 prov_2024 kab_2024)
        drop if _merge==2
        drop _merge
    * merge with spatial deflator
    ren prov_2024 prov
    ren kab_2024 rege 
    merge m:1 prov rege using "$gdat/Spatial Deflator/spdef-reg-2025.dta", keepusing(pdef)
        drop if _merge==2
        drop _merge
    ren prov prov_2024
    ren rege kab_2024
    
    /*-------------------------------------------------------------------
      There's a duplicate somehow for Banjarmasin, between 6303 and 6371.
      Assume 6303 (city) is the right one
    --------------------------------------------------------------------*/    
    * drop duplicates 
    *----------------
    bys hhid: g nhh=_N
    levelsof bps_code_all if nhh>1
    drop if bps_code_all==6371 & nhh>1
    drop nhh
    
* merge with demographics
*------------------------
    merge 1:1 hhid using `hh_welf'              // no unmatched
        drop _merge

* generate deflated income
*-------------------------
    g def_inc = tot_inc/pdef
    g pc_def_inc = def_inc/hhsize
    g ln_pc_def_inc = ln(1+pc_def_inc)
    xtile decile = pc_def_inc, nq(10)
        
* save welfare data 
*------------------
    g year = 2025
    save "$base2/base_welfare@1.dta", replace



    