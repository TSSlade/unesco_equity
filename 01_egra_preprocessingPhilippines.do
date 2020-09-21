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

global phil_src = "D:\Users\ccampton\Documents\unesco_equity\data\f.PUF_3.Philippines2014-2015-4-Regions_grade1-2_EGRA-SSME_Cebuano-Hiligaynon-Ilokano-Maguindanaoan\PUF_3.Philippines2014-2015-4-Regions_grade1-2_EGRA-SSME_Cebuano-Hiligaynon-Ilokano-Maguindanaoan.dta"
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

use "$phil_src", clear
svyset

// Ensure the variables which define our future subpopulations are well-labeled
clonevar treat_phase = year
clonevar wt_final = wt_stage3
label define lbl_treat_phase 2014 "Baseline" 2015 "Endline"
label val treat_phase lbl_treat_phase
label define lbl_female 0 "Male" 1 "Female"
label val female lbl_female
label define lbl_grade 1 "Gr1" 2 "Gr2"
label val grade lbl_grade

// Ensure consistent/transparent naming of the performance measures we're using
gen ceb_orf = .
replace ceb_orf = ph_orf if language==1
gen ilo_orf = .
replace ilo_orf = ph_orf if language==2
gen hil_orf = .
replace hil_orf = ph_orf if language==3
gen mag_orf = .
replace mag_orf = ph_orf if language==4
loc langs "Cebuano Ilokano Hiligaynon Maguindanaoan"

// Benchmark
/* Per KNEC in Kenya, for ORF:
          English          Kiswahili
        Low     High   Low    High
Grade 1  20      35    10      30
Grade 3  40      80    30      55
*/

loc low = 10
loc high = 30

gen ceb_bmark = 0
gen ilo_bmark = 0
gen hil_bmark = 0
gen mag_bmark = 0

// Applying Low
 recode ceb_bmark (0 = 1) if ((grade==1 & ceb_orf >= `low') & (grade==1 & ceb_orf < `high'))
 recode ilo_bmark (0 = 1) if ((grade==1 & ilo_orf >= `low') & (grade==1 & ilo_orf < `high'))
 recode hil_bmark (0 = 1) if ((grade==1 & hil_orf >= `low') & (grade==1 & hil_orf < `high'))
 recode mag_bmark (0 = 1) if ((grade==1 & mag_orf >= `low') & (grade==1 & mag_orf < `high'))

// Applying High
recode ceb_bmark (0 = 2) if (grade==1 & ceb_orf >= `high')
recode ilo_bmark (0 = 2) if (grade==1 & ilo_orf >= `high')
recode hil_bmark (0 = 2) if (grade==1 & hil_orf >= `high')
recode mag_bmark (0 = 2) if (grade==1 & mag_orf >= `high')

//label define lbl_ebmark 0 "[eng_orf < `eng1_low']" 1 "[eng_orf >=`eng1_low' <`eng1_high']" 2 "[eng_orf >`eng1_high']"
//label val eng_bmark lbl_ebmark
label define lbl_ceb_bmark 0 "[ceb_orf < `low'] " 1 "[ceb_orf >=`low' <`high']" 2 "[ceb_orf >`high']"
label val ceb_bmark lbl_ceb_bmark
label define lbl_ilo_bmark 0 "[ilo_orf < `low'] " 1 "[ilo_orf >=`low' <`high']" 2 "[ilo_orf >`high']"
label val ilo_bmark lbl_ilo_bmark
label define lbl_hil_bmark 0 "[hil_orf < `low'] " 1 "[hil_orf >=`low' <`high']" 2 "[hil_orf >`high']"
label val hil_bmark lbl_hil_bmark
label define lbl_mag_bmark 0 "[mag_orf < `low'] " 1 "[mag_orf >=`low' <`high']" 2 "[mag_orf >`high']"
label val mag_bmark lbl_mag_bmark

// Consider destringing any variables you would use for the grouping
// destring treat_phase grade female eng_bmark fre_bmark school_code, replace
destring treat_phase grade female ceb_bmark ilo_bmark hil_bmark mag_bmark school_code, replace

save "phil_unesco.dta", replace
use "phil_unesco.dta", clear
svyset

// Super-granular analyses by subpopulation with additional parameters
// Student-level data


quietly: apply_analysis ceb_orf ilo_orf hil_orf mag_orf, data("phil") core(treat_phase grade) res("phil_core") svy(1) wt(wt_final) zeros(1) varlabel("Cebuano Ilokano Hiligaynon Maguindanaoan") ver(0) deb(0)
quietly: apply_analysis ceb_orf ilo_orf hil_orf mag_orf, data("phil")  core(treat_phase grade female) res("phil_bysex") svy(1) wt(wt_final) zeros(1) varlabel("Cebuano Ilokano Hiligaynon Maguindanaoan") ver(0) deb(0)
quietly: apply_analysis ceb_orf ilo_orf hil_orf mag_orf, data("phil")  core(treat_phase grade ceb_bmark) res("phil_cebbmarks") svy(1) wt(wt_final) zeros(1) varlabel("Cebuano Ilokano Hiligaynon Maguindanaoan") ver(0) deb(0)
quietly: apply_analysis ceb_orf ilo_orf hil_orf mag_orf, data("phil")  core(treat_phase grade ilo_bmark) res("phil_ilobmarks") svy(1) wt(wt_final) zeros(1) varlabel("Cebuano Ilokano Hiligaynon Maguindanaoan") ver(0) deb(0)
quietly: apply_analysis ceb_orf ilo_orf hil_orf mag_orf, data("phil")  core(treat_phase grade hil_bmark) res("phil_hilbmarks") svy(1) wt(wt_final) zeros(1) varlabel("Cebuano Ilokano Hiligaynon Maguindanaoan") ver(0) deb(0)
quietly: apply_analysis ceb_orf ilo_orf hil_orf mag_orf, data("phil")  core(treat_phase grade mag_bmark) res("phil_magbmarks") svy(1) wt(wt_final) zeros(1) varlabel("Cebuano Ilokano Hiligaynon Maguindanaoan") ver(0) deb(0)
quietly: apply_analysis ceb_orf ilo_orf hil_orf mag_orf, data("phil")  core(treat_phase grade school_code) res("phil_byschool") svy(1) wt(wt_final) zeros(1) varlabel("Cebuano Ilokano Hiligaynon Maguindanaoan") ver(0) deb(0)


loc dataset_types "core bysex engbmarks byschool"

foreach dt of loc dataset_types {
    use "phil_`dt'.dta", clear
	//append using "DRC_`dt'.dta"
	export excel "bins/inequality_results_$c_datetime.xlsx", sh(`dt') firstrow(var) sheetmod
}
