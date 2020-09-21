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

global malawi_src = "D:\Users\ccampton\Documents\unesco_equity\data\c.PUF_3.Malawi2016-2017-2018-MERIT_grade1-2-3_EGRA-SSME_Chichewa\PUF_3.Malawi2016-2017-2018-MERIT_grade1-2-3_EGRA-SSME_Chichewa.dta"
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

use "$malawi_src", clear
svyset

// Ensure the variables which define our future subpopulations are well-labeled
clonevar treat_phase = year
label define lbl_treat_phase 2016 "Baseline" 2017 "Midline" 2018 "Endline"
label val treat_phase lbl_treat_phase
label define lbl_female 0 "Male" 1 "Female"
label val female lbl_female
label define lbl_grade 1 "Gr1" 2 "Gr2" 3 "Gr3"
label val grade lbl_grade

// Ensure consistent/transparent naming of the performance measures we're using
clonevar eng_orf = orf
// clonevar chew_orf = c_orf
loc langs "English"

// Benchmark
/* Per KNEC in Kenya, for ORF:
          English          Kiswahili
        Low     High   Low    High
Grade 1  20      35    10      30
Grade 3  40      80    30      55
*/

loc eng1_low = 20
loc eng1_high = 35
//loc chew1_low = 10
//loc chew1_high = 30

gen eng_bmark = 0
//gen chew_bmark = 0

// Applying Low
recode eng_bmark (0 = 1) if ((grade==1 & eng_orf >= `eng1_low') & (grade==1 & eng_orf < `eng1_high'))
//recode chew_bmark (0 = 1) if ((grade==1 & chew_orf >= `chew1_low') & (grade==1 & chew_orf < `chew1_high'))

// Applying High
recode eng_bmark (0 = 2) if (grade==1 & eng_orf >= `eng1_high')
//recode chew_bmark (0 = 2) if (grade==1 & chew_orf >= `chew1_high')

label define lbl_ebmark 0 "[eng_orf < `eng1_low']" 1 "[eng_orf >=`eng1_low' <`eng1_high']" 2 "[eng_orf >`eng1_high']"
label val eng_bmark lbl_ebmark
//label define lbl_mbmark 0 "[chew_orf < `chew1_low'] " 1 "[chew_orf >=`chew1_low' <`chew1_high']" 2 "[chew_orf >`chew1_high']"
//label val chew_bmark lbl_mbmark

// Consider destringing any variables you would use for the grouping
//destring treat_phase grade female eng_bmark chew_bmark school_code, replace
destring treat_phase grade female eng_bmark school_code, replace

save "malawi_unesco.dta", replace
use "malawi_unesco.dta", clear
svyset

// Super-granular analyses by subpopulation with additional parameters
// Student-level data

quietly: apply_analysis eng_orf, data("malawi") core(treat_phase grade) res("malawi_core") svy(1) wt(wt_final) zeros(1) varlabel("English") ver(0) deb(0)
quietly: apply_analysis eng_orf, data("malawi") core(treat_phase grade female) res("malawi_bysex") svy(1) wt(wt_final) zeros(1) varlabel("English") ver(0) deb(0)
quietly: apply_analysis eng_orf, data("malawi") core(treat_phase grade eng_bmark) res("malawi_engbmarks") svy(1) wt(wt_final) zeros(1) varlabel("English") ver(0) deb(0)
// quietly: apply_analysis eng_orf kis_orf, data("malawi") core(treat_phase grade kis_bmark) res("malawi_malbmarks") svy(1) wt(wt_final) zeros(1) varlabel("English") ver(0) deb(0)
quietly: apply_analysis eng_orf, data("malawi") core(treat_phase grade school_code) res("malawi_byschool") svy(1) wt(wt_final) zeros(1) varlabel("English") ver(0) deb(0)


loc dataset_types "core bysex engbmarks byschool"

foreach dt of loc dataset_types {
    use "malawi_`dt'.dta", clear
    export excel "bins/inequality_results_$c_datetime.xlsx", sh(`dt') firstrow(var) sheetmod
}
