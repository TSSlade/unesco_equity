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
loc target_file "tusome_inequalities"

save "tusome_unesco.dta", replace

// Sanity check
groups sub_pops grade treat_phase

quietly apply_analysis eng_orf kis_orf, data("tusome") sub(sub_pops) var(`langs') res(`target_file') splabel(`subpop_names')

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

quietly apply_analysis eng_orf kis_orf, data("primr") sub(sub_pops) var(`langs') res(`target_file') splabel(`subpop_names')

use "tusome_inequalities.dta", clear
append using "primr_inequalities.dta"

export excel "bins/inequality_results.xlsx", sh("$c_datetime") firstrow(var) sheetmod