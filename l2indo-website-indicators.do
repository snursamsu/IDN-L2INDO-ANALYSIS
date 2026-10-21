*------------------------------------------------------------------------------*
*                                                                              *
* Indicators for L2INDO website                                                *
*                                                                              *
*------------------------------------------------------------------------------*

* Directory
*----------

gl dat "C:\Users\wb594719\OneDrive - WBG\Listening to Indonesia\L2Indo Team Folder\Team Data"


********************************************************************************
* 1) Economic
********************************************************************************    
use "$dat\Anon_HH_L2Indo_Analysisfile.dta", clear

**# PUBLISH THIS - REPLACE PREVIOUS GRAPH
    * Self reported/subjective poverty (use wb32)
    *--------------------------------------------
    recode wb32 (1 2 = 1) (3 = 2) (4 5 = 3), gen(eclass)
    la def eclass 1 "Poor" 2 "Lower MC" 3 "Upper MC"    
    la val eclass
    g selfpoor = (eclass==1)
    table (mofd) () [aw=popw], stat(mean selfpoor)
    
**# PUBLISH THIS
    * Pressing challenges (only in March)
    *------------------------------------
    la var wb15A "Challenges: Jobs and incomes"
    la var wb15B "Challenges: Prices and inflation"
    la var wb15C "Challenges: Poverty and/or equality"
    la var wb15D "Challenges: Trade with other countries"
    la var wb15E "Challenges: Services/utilities"
    la var wb15F "Challenges: Governance and corruption"
    la var wb15G "Challenges: Education"
    la var wb15H "Challenges: Health"
    la var wb15I "Challenges: Infrastructure"
    la var wb15J "Challenges: Climate change/natural disasters"
    la var wb15V "Challenges: Other"
    
    table () (mofd) [aw=popw] if inlist(mofd,771,783), stat(mean wb15A-wb15J)
    
**# PUBLISH THIS
    * Short term optimism on financial wellbeing
    *-------------------------------------------
    g finbetter_n1m = inlist(wb2,4,5)
    table (mofd) () [aw=popw], stat(mean finbetter_n1m)
    table (mofd) (eclass) [aw=popw],stat(mean finbetter_n1m)
    
**# PUBLISH THIS
    * Views on local economic conditions
    *-----------------------------------
    g goodloc_econ = .
        replace goodloc_econ = 0 if wb14 ==3
        replace goodloc_econ = 0 if wb14 ==4
        replace goodloc_econ = 1 if wb14 ==1
        replace goodloc_econ = 1 if wb14 ==2
    la var goodloc_econ "Agree that local economic condition is getting better"			
    table (mofd) () [aw=popw], stat(mean goodloc_econ)
    table (mofd) (eclass) [aw=popw], stat(mean goodloc_econ)
    
**# PUBLISH THIS
    * Self perceived inflation
    *-------------------------
    g infl_perception = sv28
	table (mofd) (infl_perception) [aw=popw], stat(prop, across(infl_perception))     
    
    
********************************************************************************
* 1) Employment (for now combine with economic)
********************************************************************************
use "$dat\Anon_IND_L2Indo_Analysisfile.dta", clear

    * working age group
    *------------------
    g agegroup = .
        replace agegroup = 1 if inrange(age,15,24)
        replace agegroup = 2 if inrange(age,25,55)
        
    la def agegroup 1 "15-24" 2 "25-55"
    la val agegroup agegroup
    la var agegroup "working age group"

    * searching for jobs
    *-------------------
    g jobsearch = 0
        replace jobsearch = 1 if ac13==1 & ac14==1
    
    la var jobsearch "Seeking jobs"
    
    * employment status p1m
    *----------------------
    sort hhid fmid mofd
    by hhid fmid: g employed_p1m = (ind_work[_n-1]==1)
        replace employed_p1m = . if ind_work[_n-1]==.    
    
    * employment status current
    *--------------------------
    g employed = ind_work
    
**# PUBLISH THIS - ALSO WITH DISAGGREGATION BELOW
    * Jobseekers that found jobs
    *---------------------------
    table (mofd) () if employed_p1m==0 [aw=indw], stat(mean employed)
    table (mofd) (clean_class) if employed_p1m==0 [aw=indw], stat(mean employed)
    table (mofd) (agegroup) if employed_p1m==0 [aw=indw], stat(mean employed)
    
    * workers that are losing jobs (need to 1 - mean employed)
    *---------------------------------------------------------
    table (mofd) (clean_class) if employed_p1m==1 [aw=indw], stat(mean employed)
    table (mofd) (agegroup) if employed_p1m==1 [aw=indw], stat(mean employed)

**# PUBLISH THIS - ALSO WITH DISAGGREGATION BELOW    
    * searching for jobs
    *-------------------
    g jobsearch = 0
        replace jobsearch = 1 if ac13==1 & ac14==1
        
    table (mofd) () [aw=indw], stat(mean jobsearch)        
    table (mofd) (clean_class) [aw=indw], stat(mean jobsearch)
    table (mofd) (agegroup) [aw=indw], stat(mean jobsearch)
    
    * labor force
    *------------
    g labforce = .
        replace labforce = 1 if age>=15
        replace labforce = 0 if age>=15 & jobsearch!=1
        
********************************************************************************
* 2) Services
********************************************************************************
use "$dat\Anon_HH_L2Indo_Analysisfile.dta", clear
* lumping self-classified rich to the upper MC since the sample is too small
recode wb32 (1 =1) (2 = 2) (3 = 3) (4 5 = 4), gen(eclass2)
la def eclass2 1 "Extreme Poor" 2 "Poor" 3 "Lower MC" 4 "Upper MC"   
la val eclass2 eclass2

* Water disruption
*-----------------
    * water disruption
    g water_disrupt = wat_all
    replace water_disrupt = 1 if wat_all>0
    replace water_disrupt=. if wat_all==.

    * water disruption length (how many months)
    bys hhid: g water_disrupt_mth = sum(water_disrupt)
    * water disruption length (how many months in a year from sep 2024 - aug 2025)
    bys hhid: g water_disrupt_mth_aug = sum(water_disrupt) if inrange(round,7,18)

**# PUBLISH THIS (ROLLING FOR A YEAR)
    * water disruption length (how many months in the last year)
    table (eclass2) () [aw=popw] if water_disrupt_mth!=0 & inrange(round,9,20), stat(mean water_disrupt_mth)

    
* Electricity disruption
*-----------------------
    * Electricity disruptions experience in past 30 days (yesterday)
    g elec_disrupt_y = sh4<24

    * Electricity disruptions experience in past 30 days (day before yesterday)
    g elec_disrupt_2y = sh5<24

    * Average Electricity disruptions experience in past 30 days (either yesterday, day before yesterday, or both)
    g elec_disrupt_p1m = (elec_disrupt_y==1 | elec_disrupt_2y==1)

    * Electricity disruptions yesterday if it's 24 hours or more
    g elec_disrupt_1dplus = (sh4==0 & sh5<24)

    * Length of electricity disruption if it's 24 hours or more
    g elec_disrupt_1dplus_hr = (24-sh4)+(24-sh5) if elec_disrupt_1dplus==1

    * Length of electricity disruption if it's 48 hours or more
    g elec_disrupt_2dplus = elec_disrupt_1dplus_hr==48

    * Length of electricity disruptions yesterday
    g elec_disrupt_y_hr = 0 if sh4==24
    replace elec_disrupt_y_hr = 1 if (24-sh4)<=3 & sh4!=24
    replace elec_disrupt_y_hr = 2 if (24-sh4)>3 & (24-sh4)<=6 & sh4!=24
    replace elec_disrupt_y_hr = 3 if (24-sh4)>6 & (24-sh4)<=12 & sh4!=24
    replace elec_disrupt_y_hr = 4 if (24-sh4)>12 & (24-sh4)<=24 & sh4!=24

    * Length of electricity disruptions day before yesterday 
    g elec_disrupt_2y_hr = 0 if sh5==24
    replace elec_disrupt_2y_hr = 1 if (24-sh5)<=3 & sh5!=24
    replace elec_disrupt_2y_hr = 2 if (24-sh5)>3 & (24-sh5)<=6 & sh5!=24
    replace elec_disrupt_2y_hr = 3 if (24-sh5)>6 & (24-sh5)<=12 & sh5!=24
    replace elec_disrupt_2y_hr = 4 if (24-sh5)>12 & (24-sh5)<=24 & sh5!=24

    * Average length of electricity disruptions in past 30 days (maximum of either yesterday or day before yesterday, adding more than 24 & 48 hours)
    egen elec_disrupt_p1m_hr = rowmax(elec_disrupt_2y_hr elec_disrupt_y_hr)
    replace elec_disrupt_p1m_hr = 5 if elec_disrupt_1dplus==1
    replace elec_disrupt_p1m_hr = 6 if elec_disrupt_2dplus==1

    la def eldisr 0 "No disruption" 1 "1-3 hours" 2 "4-6 hours" 3 "6-12 hours" 4 "12-24 hours" 5 "More than a day" 6 "2 days or more"
    la val elec_disrupt_y_hr elec_disrupt_2y_hr elec_disrupt_p1m_hr eldisr

**# PUBLISH THIS
    * by self classified class
    table (elec_disrupt_p1m_hr) (eclass2) [aw=popw], stat(prop, across(elec_disrupt_p1m_hr))
    
    
* Internet disruption
*--------------------
    * internet disruption
    g inet_disrupt = sh12
    recode inet_disrupt (2 = 0) (3 = .)

**# PUBLISH THIS (ALSO DISAGGREGATE BY SELF CLASSIFIED CLASS)
    * Generate length of internet disruption
    g inet_disrupt_hr = 0 if sh12!=3
    replace inet_disrupt_hr = 1 if inlist(sh13,0,1)
    replace inet_disrupt_hr = 2 if inlist(sh13,2)
    replace inet_disrupt_hr = 3 if inlist(sh13,3)
    replace inet_disrupt_hr = 4 if inlist(sh13,4,5)
    replace inet_disrupt_hr = 5 if inrange(sh13,6,10)
    replace inet_disrupt_hr = 6 if inrange(sh13,11,20)
    replace inet_disrupt_hr = 7 if inrange(sh13,21,30)

    la def idis 0 "No disruption" 1 "1 day or less" 2 "2 days" 3 "3 days" 4 "4-5 days" 5 "6-10 days" 6 "11-20 days" 7 "21-30 days"
    la val inet_disrupt_hr idis    
    table (mofd) (inet_disrupt_hr) [aw=popw],stat(prop, across(inet_disrupt_hr))
    
    
********************************************************************************
* 3) Vulnerability
********************************************************************************    

**# PUBLISH THIS
* Unexpected financial deterioration
*-----------------------------------
    xtset hhid mofd
    xttrans wb1 
    
    g past_pred = L.wb2
    tab past_pred wb1 [aw=popw], ro nof
    
    * Unexpected
    g fin_deterior = .
    replace fin_deterior =1 if past_pred>wb1 & past_pred!=. & wb1!=.
    replace fin_deterior =0 if past_pred<=wb1 & past_pred!=. & wb1!=.
    replace fin_deterior =0 if wb1>2
    
    table mofd [aw=popw], stat(mean fin_deterior)
    table (mofd) (eclass2) [aw=popw], stat(mean fin_deterior)           // by self classified economic class
    
    
********************************************************************************
* 4) Food
********************************************************************************


********************************************************************************
* 5) Opinion
********************************************************************************
    * Trust in financial service
    * Perceived taxpayers
    * Perception on taxation 