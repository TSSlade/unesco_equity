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
log using "logs/egra_analysis_$c_datetime.txt", text name(main_log)

do apply_analysis.do

capture postutil clear      // Wiping out any open postfiles we may have

/************************************************
**************** Tusome Section *****************
************************************************/

// Granular analyses

use "$tusome_src", clear
svyset

// Start defining subpopulations we'll need
egen sub_pops = group(treat_phase grade)
label define lbl_sub_pops 1 "Gr 1 Baseline" 2 "Gr 2 Baseline" 3 "Gr 1 Midline" 4 "Gr 2 Midline", replace      // Let's make some labels
label val sub_pops lbl_sub_pops             // ...and apply them
local subpop_names "base_gr1 base_gr2 mid_gr1 mid_gr2"

clonevar eng_orf = e_orf_a
clonevar kis_orf = k_orf
loc langs "English Kiswahili"
* loc target_file "tusome_inequalities"

// Sanity check
groups sub_pops grade treat_phase

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

gen eng_bmark_low = 0
gen eng_bmark_high = 0
gen kis_bmark_low = 0
gen kis_bmark_high = 0

// Applying Low
recode eng_bmark_low (0 = 1) if ((grade==1 & eng_orf >= `eng1_low') & (grade==1 & eng_orf < `eng1_high'))
recode kis_bmark_low (0 = 1) if ((grade==1 & kis_orf >= `kis1_low') & (grade==1 & kis_orf < `kis1_high'))

// Applying High
recode eng_bmark_high (0 = 1) if (grade==1 & eng_orf >= `eng1_high')
recode kis_bmark_high (0 = 1) if (grade==1 & kis_orf >= `kis1_high')

label define lbl_ebmark_low 0 "<`eng1_low'" 1 ">=`eng1_low' <`eng1_high'"
label define lbl_ebmark_high 0 "" 1 ">`eng1_high'"
label define lbl_kbmark_low 0 "<`kis1_low'" 1 ">=`kis1_low' < `kis1_high'"
label define lbl_kbmark_high 0 "" 1 ">`kis1_high'"

label val eng_bmark_low lbl_ebmark_low
label val eng_bmark_high lbl_ebmark_high
label val kis_bmark_low lbl_kbmark_low
label val kis_bmark_high lbl_kbmark_high

// To do between- and within-school calculations
egen schl_eng_orf = mean(eng_orf), by(sub_pops school_code)
egen schl_kis_orf = mean(kis_orf), by(sub_pops school_code)

save "tusome_unesco.dta", replace
use "tusome_unesco.dta", replace
svyset

// Super-granular analyses by subpopulation with additional parameters
// Student-level data

quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade) res("tusome_core") svy(1) varlabel("English Kiswahili") ver(1)
quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade female) res("tusome_bysex") svy(1) varlabel("English Kiswahili") ver(1)
quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade eng_bmark*) res("tusome_engbmarks") svy(1) varlabel("English Kiswahili") ver(1)
quietly: apply_analysis eng_orf kis_orf, data("tusome") core(treat_phase grade kis_bmark*) res("tusome_kisbmarks") svy(1) varlabel("English Kiswahili") ver(1)

/***********************************************
**************** PRIMR Section *****************
***********************************************/
use "$primr_src", clear
svyset

// Start defining subpopulations we'll need
egen sub_pops = group(treat_phase cohort treatment grade)

label define lbl_sub_pops 1 "base_c1_con_gr_1"  2 "base_c1_con_gr_2" 3 "base_c2_con_gr_1"  4 "base_c2_con_gr_2" 5 "base_c3_con_gr_1"  6 "base_c3_con_gr_2" 7 "mid_c1_trt_gr_1" 8 "mid_c1_trt_gr_2" 9 "mid_c2_con_gr_1"   10 "mid_c2_con_gr_2" 11 "mid_c3_con_gr_1"  12 "mid_c3_con_gr_2" 13 "end_c1_trt_gr_1" 14 "end_c1_trt_gr_2" 15 "end_c2_trt_gr_1" 16 "end_c2_trt_gr_2" 17 "end_c3_con_gr_1" 18 "end_c3_con_gr_2" , replace      // Let's make some labels
label val sub_pops lbl_sub_pops             // ...and apply them
local subpop_names `" "base_c1_con_gr_1" "base_c1_con_gr_2" "base_c2_con_gr_1" "base_c2_con_gr_2" "base_c3_con_gr_1" "base_c3_con_gr_2" "mid_c1_trt_gr_1" "mid_c1_trt_gr_2" "mid_c2_con_gr_1" "mid_c2_con_gr_2" "mid_c3_con_gr_1" "mid_c3_con_gr_2" "end_c1_trt_gr_1" "end_c1_trt_gr_2" "end_c2_trt_gr_1" "end_c2_trt_gr_2" "end_c3_con_gr_1" "end_c3_con_gr_2" "'

clonevar eng_orf = eq_orf
clonevar kis_orf = k_eq_orf
loc langs "English Kiswahili"
loc target_file "primr_inequalities"

save "primr_unesco.dta", replace

groups sub_pops treat_phase cohort treatment grade, missing

// This is ANACHRONISTICALLY applying Tusome-era benchmarks to PRIMR.
// These did not exist during PRIMR.

loc eng1_low = 20
loc eng1_high = 35
loc kis1_low = 10
loc kis1_high = 30

gen eng_bmark_low = 0
gen eng_bmark_high = 0
gen kis_bmark_low = 0
gen kis_bmark_high = 0

// Applying Low
recode eng_bmark_low (0 = 1) if ((grade==1 & eng_orf >= `eng1_low') & (grade==1 & eng_orf <= `eng1_high'))
recode kis_bmark_low (0 = 1) if ((grade==1 & kis_orf >= `kis1_low') & (grade==1 & kis_orf <= `kis1_high'))

// Applying High
recode eng_bmark_high (0 = 1) if (grade==1 & eng_orf >= `eng1_high')
recode kis_bmark_high (0 = 1) if (grade==1 & kis_orf >= `kis1_high')

// To do between- and within-school calculations
egen schl_eng_orf = mean(eng_orf), by(sub_pops school_code)
egen schl_kis_orf = mean(kis_orf), by(sub_pops school_code)


// Student-level data
quietly: apply_analysis eng_orf kis_orf, data("primr") sub(sub_pops) res(`target_file') spl(`subpop_names') var(`langs') ben(eng_bmark_low eng_bmark_high kis_bmark_low kis_bmark_high) fem(female) urb(urban) ver(0)
// School-level data
quietly: apply_analysis schl_eng_orf schl_kis_orf, data("primr_schools") sub(sub_pops) res("primr_inequalities_schools") spl(`subpop_names') var(`langs') ben(eng_bmark_low eng_bmark_high kis_bmark_low kis_bmark_high) fem(female) urb(urban) ver(0)


use "tusome_inequalities.dta", clear
append using "primr_inequalities.dta"

export excel "bins/inequality_results.xlsx", sh("$c_datetime") firstrow(var) sheetmod