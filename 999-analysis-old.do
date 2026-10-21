*-----------------------------------------------------------------
* Pressing challenges (only in April for 2024,2025; Aug in  2026)
*-----------------------------------------------------------------
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

*--------
* FIES
*--------
    table (mofd) () [aw=popw], stat(mean fies_mild fies_moderate fies_severe)
    
*---------------------------
* Financial deterioration
*---------------------------

    * unexpected (fin_deterior)
    *----------------------------
    table (mofd) (eclass2) [aw=popw], stat(mean fin_deterior)          
    
    * total (any_deterfin)
    * substract total from unexpected to get expected
    *-------------------------------------------------
    table (mofd) (eclass2) [aw=popw], stat(mean any_deterfin)
    
*-------------------
* CV of income
*-------------------

    * cv
    *-----
//     * Mar - Aug 24
//     table (quint) [aw=popw] if inrange(mofd,770,775), stat(mean cv_income)    
//     * Mar - Aug 25
//     table (quint) [aw=popw] if inrange(mofd,782,787), stat(mean cv_income)
    * Mar - Jun 24
    table (quint) [aw=popw] if inrange(mofd,770,773), stat(mean cv_income)    
    * Mar - Jun 25
    table (quint) [aw=popw] if inrange(mofd,782,785), stat(mean cv_income)    
    * Mar - Jun 26
    table (quint) [aw=popw] if inrange(mofd,794,797), stat(mean cv_income)
    
    * cv of each income
    *-------------------
    foreach vars of varlist rinc_* {
        replace `vars' = 0 if missing(`vars')
        bys hhid: egen sd_`vars' = sd(`vars') 
        bys hhid: egen mean_`vars' = mean(`vars')
        g cv_`vars' = (sd_`vars'/mean_`vars')*100
        }
    table () () [aw=popw],stat(mean cv_rinc_*) stat(median cv_rinc_*)