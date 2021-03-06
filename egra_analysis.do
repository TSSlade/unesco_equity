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

use $p_dir/tusome_core.dta, clear

// Split labels back into variables for easier cross-tabulation
gen grade = substr(subpop_label, -1, .)
destring grade, replace
label define lbl_grade 1 "Gr1" 2 "Gr2"
label val grade lbl_grade

gen round = substr(subpop_label, 1, strpos(subpop_label, "_")-1)
egen lang_groups = group(round measure_label)

gen comparison = .
recode comparison (. = 1) if grade==1 & measure_label=="English"
recode comparison (. = 2) if grade==1 & measure_label=="Kiswahili"
recode comparison (. = 3) if grade==2 & measure_label=="English"
recode comparison (. = 4) if grade==2 & measure_label=="Kiswahili"
label define lbl_comparison 1 "Gr1_English_Baseline-Midline" 2 "Gr1_Kiswahili_Baseline-Midline" 3 "Gr2_English_Baseline-Midline" 4 "Gr2_Kiswahili_Baseline-Midline", modify
label val comparison lbl_comparison

groups comparison round ge2 between_ge2 within_ge2

// Task 1: Inequality Decomposition of means
list measure_label subpop_label between_ge2 within_ge2


// Task 2: 
// 
// 
// 

// Lorenz curves

local primr = "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\primr_unesco.dta"
local tusome = "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\tusome_unesco.dta"

* egen subpops = group(treat_phase cohort treatment grade), label
local languages = "English Kiswahili"
local langvars = "eng_orf kis_orf"
local datasets = "primr tusome"

foreach d of loc datasets {
    use ``d'', clear
    foreach i of num 1/2 {
        loc LANG `: word `i' of `languages''
        loc LANGVAR `: word `i' of `langvars''
        foreach j of num 1/2 {
        lorenz `LANGVAR' if grade==`j', svy over(treat_phase) ///
            graph(overlay aspectratio(1) xlabels(,grid) ///
                    legend(cols(1)) ciopts(recast(rline) lp(dash)) ///
                    title("Lorenz curve for Grade `j' `LANG'" "by Round of Assessment") ///
                    text(1 25 "Grade `j' `LANG'", orient(horizontal) justification(left) box) ///
                    xtitle("Percentage of Population") ///
                    ytitle("Cumulative Proportion of ORF"))
            graph save bins/`LANG'_gr`j'_lorenz_`d', replace
            graph export bins/`LANG'_gr`j'_lorenz_`d'.png, replace width(800) height(500)
        }
    }
}