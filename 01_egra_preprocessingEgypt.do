/*
    Usage Notes
===================
1) Required packages:
    - pshare
    - svygei
	- lorenz
	- ineqdec0
2) Parameters:
    - Depending on the number of subpopulations you provide, you may need to -set matsize-
        to a larger value than the default (400). I have been able to get away with
        -set matsize 1000-. This appears to primarily be the case for analyses that operate
        at the level of schools rather than at larger subpopulations
3) Variable contents:
    - For the sake of interpretability, be aware that having appropriately-labeled categorical
        variables will make recognizing the subpopulations much more straightforward. So if
        you have, e.g., a variable called -treat_phase- which takes values of 1 / 2 / 3 representing
        "Baseline" / "Midline" / "Endline", please ensure that those values are labeled before
        you feed those commands to the scripts below.
     */

program drop _all
clear
pause on
log close _all

// Define vars
global p_dir="D:\Users\ccampton\Documents\unesco_equity"
local c_time: di %td_CY-N-D date("$S_DATE", "DMY") "_$S_TIME"
global c_datetime=trim(subinstr("`c_time'",":","-",.))

global Egy_src = "D:\Users\ccampton\Documents\unesco_equity\data\g.PUF_3.Egypt2014-National_grade3_EGRA_Arabic\PUF_3.Egypt2014-National_grade3_EGRA_Arabic.dta"
global uwezo_dir="data/uwezo/"

// Change to current dir, begin logging
cd $p_dir
log using "logs/egra_preprocessing_$c_datetime.txt", text name(main_log)

do 00_apply_analysis.do

capture postutil clear      // Wiping out any open postfiles we may have

/************************************************
**************** Tusome Section *****************
************************************************/

// Granular analyses

use "$Egy_src", clear
svyset

// Ensure the variables which define our future subpopulations are well-labeled
//label define lbl_treat_phase 1 "Baseline" 6 "Endline" 
//label val treat_phase lbl_treat_phase
label define lbl_female 0 "Male" 1 "Female"
label val female lbl_female
// label define lbl_grade 1 "Gr1" 2 "Gr2" 3 "Gr3"
label define lbl_grade 2 "Gr2"
label val grade lbl_grade

// Ensure consistent/transparent naming of the performance measures we're using
clonevar ara_orf = orf
clonevar wt_final = wt_stage2
loc langs "Arabic"

// Benchmark
/* Per KNEC in Kenya, for ORF:
          English          Kiswahili
        Low     High   Low    High
Grade 1  20      35    10      30
Grade 3  40      80    30      55
*/

loc ara1_low = 20
loc ara1_high = 35

gen ara_bmark = 0

// Applying Low
recode ara_bmark (0 = 1) if ((grade==1 & ara_orf >= `ara1_low') & (grade==1 & ara_orf < `ara1_high'))
// Applying High
recode ara_bmark (0 = 2) if (grade==1 & ara_orf >= `ara1_high')
label define lbl_aramark 0 "[ara_orf < `ara1_low'] " 1 "[ara_orf >=`ara1_low' <`ara1_high']" 2 "[ara_orf >`ara1_high']"
label val ara_bmark lbl_aramark

// Consider destringing any variables you would use for the grouping
// destring treat_phase grade female eng_bmark fre_bmark school_code, replace
destring grade female ara_bmark school_code, replace

save "Egy_unesco.dta", replace
use "Egy_unesco.dta", clear
svyset

// Super-granular analyses by subpopulation with additional parameters
// Student-level data
// Treat phase non-existent
quietly: apply_analysis ara_orf, data("Egy") core(grade) res("Egy_core") svy(1) wt(wt_final) zeros(1) varlabel("Arabic") ver(0) deb(0)
quietly: apply_analysis ara_orf, data("Egy") core(grade female) res("Egy_bysex") svy(1) wt(wt_final) zeros(1) varlabel("Arabic") ver(0) deb(0)
quietly: apply_analysis ara_orf, data("Egy") core(grade ara_bmark) res("Egy_arabmarks") svy(1) wt(wt_final) zeros(1) varlabel("Arabic") ver(0) deb(0)
quietly: apply_analysis ara_orf, data("Egy") core(grade school_code) res("Egy_byschool") svy(1) wt(wt_final) zeros(1) varlabel("Arabic") ver(0) deb(0)


loc dataset_types "core bysex arabmarks byschool"

foreach dt of loc dataset_types {
    use "Egy_`dt'.dta", clear
	export excel "bins/inequality_results_$c_datetime.xlsx", sh(`dt') firstrow(var) sheetmod
}
