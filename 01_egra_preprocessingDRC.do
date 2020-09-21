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

global DRC_src = "D:\Users\ccampton\Documents\unesco_equity\data\d.PUF_DRC_Baseline_Endline Grade 2-4-6 French Sample A\PUF_3.DRC2010_2014-Baseline_Endline_grade2-4-6_EGRA-EGMA_French_SampleA.dta"
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

use "$DRC_src", clear
svyset

// Ensure the variables which define our future subpopulations are well-labeled
label define lbl_treat_phase 1 "Baseline" 6 "Endline"
label val treat_phase lbl_treat_phase
label define lbl_female 0 "Male" 1 "Female"
label val female lbl_female
// label define lbl_grade 1 "Gr1" 2 "Gr2" 3 "Gr3"
label define lbl_grade 2 "Gr2" 4 "Gr4" 6 "Gr6"
label val grade lbl_grade

// Ensure consistent/transparent naming of the performance measures we're using
clonevar fre_orf = orf
loc langs "French"

// Benchmark
/* Per KNEC in Kenya, for ORF:
          English          Kiswahili
        Low     High   Low    High
Grade 1  20      35    10      30
Grade 3  40      80    30      55
*/

loc eng1_low = 20
loc eng1_high = 35
loc fre1_low = 10
loc fre1_high = 30

gen eng_bmark = 0
gen fre_bmark = 0

// Applying Low
//recode eng_bmark (0 = 1) if ((grade==1 & eng_orf >= `eng1_low') & (grade==1 & eng_orf < `eng1_high'))
 recode fre_bmark (0 = 1) if ((grade==1 & fre_orf >= `fre1_low') & (grade==1 & fre_orf < `fre1_high'))

// Applying High
//recode eng_bmark (0 = 2) if (grade==1 & eng_orf >= `eng1_high')
recode fre_bmark (0 = 2) if (grade==1 & fre_orf >= `fre1_high')

//label define lbl_ebmark 0 "[eng_orf < `eng1_low']" 1 "[eng_orf >=`eng1_low' <`eng1_high']" 2 "[eng_orf >`eng1_high']"
//label val eng_bmark lbl_ebmark
label define lbl_frmark 0 "[fre_orf < `fre1_low'] " 1 "[fre_orf >=`fre1_low' <`fre1_high']" 2 "[fre_orf >`fre1_high']"
label val fre_bmark lbl_frmark

// Consider destringing any variables you would use for the grouping
// destring treat_phase grade female eng_bmark fre_bmark school_code, replace
destring treat_phase grade female eng_bmark school_id, replace

save "DRC_unesco.dta", replace
use "DRC_unesco.dta", clear
svyset

// Super-granular analyses by subpopulation with additional parameters
// Student-level data

quietly: apply_analysis fre_orf, data("DRC") core(treat_phase grade) res("DRC_core") svy(1) wt(wt_final) zeros(1) varlabel("French") ver(0) deb(0)
quietly: apply_analysis fre_orf, data("DRC") core(treat_phase grade female) res("DRC_bysex") svy(1) wt(wt_final) zeros(1) varlabel("French") ver(0) deb(0)
quietly: apply_analysis fre_orf, data("DRC") core(treat_phase grade fre_bmark) res("DRC_frebmarks") svy(1) wt(wt_final) zeros(1) varlabel("French") ver(0) deb(0)
//quietly: apply_analysis fre_orf, data("DRC") core(treat_phase grade school_id) res("DRC_byschool") svy(1) wt(wt_final) zeros(1) varlabel("French") ver(0) deb(0)


//loc dataset_types "core bysex engbmarks byschool"
loc dataset_types "core bysex engbmarks"

foreach dt of loc dataset_types {
    use "DRC_`dt'.dta", clear
	//append using "DRC_`dt'.dta"
	export excel "bins/inequality_results_$c_datetime.xlsx", sh(`dt') firstrow(var) sheetmod
}
