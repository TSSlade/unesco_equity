/*
    Usage Notes
===================
1) Required packages:
    - pshare
    - svygei
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
global p_dir="C:/Dropbox/BerkeleyMIDS/projects/unesco_chapter"
local c_time: di %td_CY-N-D date("$S_DATE", "DMY") "_$S_TIME"
global c_datetime=trim(subinstr("`c_time'",":","-",.))

global tusome_src="data/PUF_KenyaTusome_Stu_BaseMid_170311.dta" // Replace with the path to your dataset
global primr_src="data/PUF_3.Kenya PRIMR2012-2013-Endline_grade1 2_EGRA EGMA ENG HT T TAC COR COM CIN_Eng Kis.dta" // Replace with the path to your dataset
global uwezo_dir="data/uwezo/"

// Change to current dir, begin logging
cd $p_dir
log using "logs/egra_preprocessing_$c_datetime.txt", text name(main_log)

do apply_analysis.do

capture postutil clear      // Wiping out any open postfiles we may have

/************************************************
**************** Tusome Section *****************
************************************************/

// Granular analyses

use "$tusome_src", clear
svyset

// Ensure the variables which define our future subpopulations are well-labeled
label define lbl_treat_phase 1 "Baseline" 2 "Midline" 3 "Endline"
label val treat_phase lbl_treat_phase
label define lbl_female 0 "Male" 1 "Female"
label val female lbl_female
label define lbl_grade 1 "Gr1" 2 "Gr2" 3 "Gr3"
label val grade lbl_grade

// Ensure consistent/transparent naming of the performance measures we're using
clonevar eng_orf = e_orf_a
clonevar kis_orf = k_orf
loc langs "English Kiswahili"

// Benchmark
/* Per KNEC in Kenya, for ORF:
          English          Kiswahili
        Low     High   Low    High
Grade 1  20      35    10      30
Grade 3  40      80    30      55
*/

loc eng1_low = 20
loc eng1_high = 35
loc kis1_low = 10
loc kis1_high = 30

gen eng_bmark = 0
gen kis_bmark = 0

// Applying Low
recode eng_bmark (0 = 1) if ((grade==1 & eng_orf >= `eng1_low') & (grade==1 & eng_orf < `eng1_high'))
recode kis_bmark (0 = 1) if ((grade==1 & kis_orf >= `kis1_low') & (grade==1 & kis_orf < `kis1_high'))

// Applying High
recode eng_bmark (0 = 2) if (grade==1 & eng_orf >= `eng1_high')
recode kis_bmark (0 = 2) if (grade==1 & kis_orf >= `kis1_high')

label define lbl_ebmark 0 "[eng_orf < `eng1_low']" 1 "[eng_orf >=`eng1_low' <`eng1_high']" 2 "[eng_orf >`eng1_high']"
label val eng_bmark lbl_ebmark
label define lbl_kbmark 0 "[kis_orf < `kis1_low'] " 1 "[kis_orf >=`kis1_low' <`kis1_high']" 2 "[kis_orf >`kis1_high']"
label val kis_bmark lbl_kbmark

save "tusome_unesco.dta", replace
use "tusome_unesco.dta", clear
svyset

// Super-granular analyses by subpopulation with additional parameters
// Student-level data

quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade) res("tusome_core") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade female) res("tusome_bysex") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade eng_bmark) res("tusome_engbmarks") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade kis_bmark) res("tusome_kisbmarks") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade school_code) res("tusome_byschool") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)

/***********************************************
**************** PRIMR Section *****************
***********************************************/
use "$primr_src", clear
svyset

// Ensure the variables which define our future subpopulations are well-labeled
label define lbl_treat_phase 1 "Baseline" 2 "Midline" 6 "Endline"
label val treat_phase lbl_treat_phase
label define lbl_female 0 "Male" 1 "Female"
label val female lbl_female
label define lbl_grade 1 "Gr1" 2 "Gr2" 3 "Gr3"
label val grade lbl_grade
label define lbl_cohort 1 "Coh1" 2 "Coh2" 3 "Coh3"
label val cohort lbl_cohort


// Start defining subpopulations we'll need
clonevar eng_orf = eq_orf
clonevar kis_orf = k_eq_orf
loc langs "English Kiswahili"

save "primr_unesco.dta", replace

// This is ANACHRONISTICALLY applying Tusome-era benchmarks to PRIMR.
// These did not exist during PRIMR.

loc eng1_low = 20
loc eng1_high = 35
loc kis1_low = 10
loc kis1_high = 30

gen eng_bmark = 0
gen kis_bmark = 0

// Applying Low
recode eng_bmark (0 = 1) if ((grade==1 & eng_orf >= `eng1_low') & (grade==1 & eng_orf < `eng1_high'))
recode kis_bmark (0 = 1) if ((grade==1 & kis_orf >= `kis1_low') & (grade==1 & kis_orf < `kis1_high'))

// Applying High
recode eng_bmark (0 = 2) if (grade==1 & eng_orf >= `eng1_high')
recode kis_bmark (0 = 2) if (grade==1 & kis_orf >= `kis1_high')

label define lbl_ebmark 0 "[eng_orf < `eng1_low']" 1 "[eng_orf >=`eng1_low' <`eng1_high']" 2 "[eng_orf >`eng1_high']"
label val eng_bmark lbl_ebmark
label define lbl_kbmark 0 "[kis_orf < `kis1_low'] " 1 "[kis_orf >=`kis1_low' <`kis1_high']" 2 "[kis_orf >`kis1_high']"
label val kis_bmark lbl_kbmark

// Student-level data
quietly: apply_analysis eng_orf kis_orf, data("primr") core(treat_phase cohort treatment grade) res("primr_core") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
quietly: apply_analysis eng_orf kis_orf, data("primr") core(treat_phase cohort treatment grade female) res("primr_bysex") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
quietly: apply_analysis eng_orf kis_orf, data("primr") core(treat_phase cohort treatment grade eng_bmark) res("primr_engbmarks") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
quietly: apply_analysis eng_orf kis_orf, data("primr") core(treat_phase cohort treatment grade kis_bmark) res("primr_kisbmarks") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)
// School-level data
quietly: apply_analysis eng_orf kis_orf, data("primr") core(treat_phase cohort treatment grade school_code) res("primr_byschool") svy(1) wt(wt_final) varlabel("English Kiswahili") ver(0) deb(0)

loc dataset_types "core bysex engbmarks kisbmarks byschool"

foreach dt of loc dataset_types {
    use "tusome_`dt'.dta", clear
    append using "primr_`dt'.dta"
    export excel "bins/inequality_results_$c_datetime.xlsx", sh(`dt') firstrow(var) sheetmod
}

use "tusome_inequalities.dta", clear
append using "primr_inequalities.dta"

export excel "bins/inequality_results.xlsx", sh("$c_datetime") firstrow(var) sheetmod