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

global DRC_src = "D:\Users\ccampton\Documents\unesco_equity\data\e.PUF_3.DRC2015-4Regions_grade3-5_EGRA-EGMA-SSME_French-Lingala-Tshiluba-Kiswahili\PUF_3.DRC2015-4Regions_grade3-5_EGRA-EGMA-SSME_French-Lingala-Tshiluba-Kiswahili.dta"
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
//label define lbl_treat_phase 1 "Baseline" 6 "Endline"
//label val treat_phase lbl_treat_phase
label define lbl_female 0 "Male" 1 "Female"
label val female lbl_female
label define lbl_grade 3 "Gr3" 5 "Gr5" 777 "Other"
label val grade lbl_grade
clonevar wt_final = wt_stage3


// Ensure consistent/transparent naming of the performance measures we're using
gen fre_orf = .
replace fre_orf = mt_orf if language==1
gen lin_orf = .
replace lin_orf = mt_orf if language==2
gen tsh_orf = .
replace tsh_orf = mt_orf if language==3
gen kis_orf = .
replace kis_orf = mt_orf if language==4
loc langs "French Lingala Tshiluba Kiswahili"

// Benchmark
/* Per KNEC in Kenya, for ORF:
          English          Kiswahili
        Low     High   Low    High
Grade 1  20      35    10      30
Grade 3  40      80    30      55
*/

loc low = 10
loc high = 30

gen fre_bmark = 0
gen lin_bmark = 0
gen tsh_bmark = 0
gen kis_bmark = 0

// Applying Low
 recode fre_bmark (0 = 1) if ((grade==1 & fre_orf >= `low') & (grade==1 & fre_orf < `high'))
 recode lin_bmark (0 = 1) if ((grade==1 & lin_orf >= `low') & (grade==1 & lin_orf < `high'))
 recode tsh_bmark (0 = 1) if ((grade==1 & tsh_orf >= `low') & (grade==1 & tsh_orf < `high'))
 recode kis_bmark (0 = 1) if ((grade==1 & kis_orf >= `low') & (grade==1 & kis_orf < `high'))

// Applying High
recode fre_bmark (0 = 2) if (grade==1 & fre_orf >= `high')
recode lin_bmark (0 = 2) if (grade==1 & lin_orf >= `high')
recode tsh_bmark (0 = 2) if (grade==1 & tsh_orf >= `high')
recode kis_bmark (0 = 2) if (grade==1 & kis_orf >= `high')

//label define lbl_ebmark 0 "[eng_orf < `eng1_low']" 1 "[eng_orf >=`eng1_low' <`eng1_high']" 2 "[eng_orf >`eng1_high']"
//label val eng_bmark lbl_ebmark
label define lbl_fremark 0 "[fre_orf < `low'] " 1 "[fre_orf >=`low' <`high']" 2 "[fre_orf >`high']"
label val fre_bmark lbl_fremark
label define lbl_linmark 0 "[lin_orf < `low'] " 1 "[lin_orf >=`low' <`high']" 2 "[lin_orf >`high']"
label val lin_bmark lbl_linmark
label define lbl_tshmark 0 "[tsh_orf < `low'] " 1 "[tsh_orf >=`low' <`high']" 2 "[tsh_orf >`high']"
label val tsh_bmark lbl_tshmark
label define lbl_kismark 0 "[kis_orf < `low'] " 1 "[kis_orf >=`low' <`high']" 2 "[kis_orf >`high']"
label val kis_bmark lbl_kismark

// Consider destringing any variables you would use for the grouping
// destring treat_phase grade female eng_bmark fre_bmark school_code, replace
destring grade female fre_bmark lin_bmark tsh_bmark kis_bmark school_code, replace
//destring treat_phase grade female fre_bmark lin_bmark tsh_bmark kis_bmark school_code, replace

save "DRCe_unesco.dta", replace
use "DRCe_unesco.dta", clear
svyset

// Super-granular analyses by subpopulation with additional parameters
// Student-level data
// Treat phase stratification removed. 
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade) res("DRC_core") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade female) res("DRC_bysex") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade fre_bmark) res("DRC_frebmarks") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade lin_bmark) res("DRC_linbmarks") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade tsh_bmark) res("DRC_tshbmarks") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade kis_bmark) res("DRC_kisbmarks") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade) res("DRC_frebmarks") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)
quietly: apply_analysis fre_orf lin_orf tsh_orf kis_orf, data("DRC") core(grade school_code) res("DRC_byschool") svy(1) wt(wt_final) zeros(1) varlabel("French Lingala Tshiluba Kiswahili") ver(0) deb(0)

loc dataset_types "core bysex frebmarks linbmarks tshbmarks kisbmarks byschool"

foreach dt of loc dataset_types {
    use "DRCe_`dt'.dta", clear
	//append using "DRC_`dt'.dta"
	export excel "bins/inequality_results_$c_datetime.xlsx", sh(`dt') firstrow(var) sheetmod
}
