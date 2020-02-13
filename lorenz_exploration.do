capture postutil clear
loc verbose = 0
loc debug = cond(`verbose'==1, "noisily", "quietly")
tempfile lorenzes            // This is a placeholder for our results
tempname postLorenz            // Ensures no namespace clashes

loc vars_of_interest = "str20(dataset language) cohort grade round pct_00 pct_05 pct_10 pct_15 pct_20 pct_25 pct_30 pct_35 pct_40 pct_45 pct_50 pct_55 pct_60 pct_65 pct_70 pct_75 pct_80 pct_85 pct_90 pct_95 pct_100"

postfile `postLorenz' `vars_of_interest' using `lorenzes'

local primr = "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\primr_unesco.dta"
local tusome = "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\tusome_unesco.dta"
local languages = "English Kiswahili"
local langvars = "eng_orf kis_orf"
local datasets = "primr tusome"
local cohortvars = "1 2 3"


// Loop through datasets
// ...then languages
// ...then rounds
// ...then grades
// ...then cohorts (if applicable)

// Datasets
foreach dataset of loc datasets {
    use ``dataset'', clear                // Nested local macro to pull data from URL above
    levelsof treat_phase, loc(treat_phases)

    // Languages
    foreach lang of num 1/2 {
        loc LANGLABEL `: word `lang' of `languages''
        loc SHORTLANGLABEL = strlower(substr("`LANGLABEL'", 1, 3))
        di "`SHORTLANGLABEL'"
        if `verbose' pause
        loc LANGVAR `: word `lang' of `langvars''

        // Rounds
        foreach round of loc treat_phases {

            // Grades
            foreach grade of num 1/2 {

                if "`dataset'"=="primr" {
                // Cohort if applicable
                    foreach cohort of loc cohortvars {
                        qui lorenz estimate `LANGVAR' if grade==`grade' & cohort==`cohort' & treat_phase==`round'
                        return list
                        * pause
                        qui mat rmat = r(table)
                        foreach p of num 1/21 {
                            scalar `dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at`p' = rmat[1, `p']
                            `debug' di as result `dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at`p'
                        }
                        * lorenz `LANGVAR' if grade==`j' & cohort==`c', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `j' Coh`c' `LANG'" "by Round of Assessment") text(1 25 "Grade `j' Coh`c' `LANG'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
                        * lorenz graph, overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `j' Coh`c' `LANG'" "by Round of Assessment") text(1 25 "Grade `j' Coh`c' `LANG'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF")
                        if `verbose' set trace on
                        loc raw_results = `" ("`dataset'") ("`LANGLABEL'") (`cohort') (`grade') (`round') (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at1) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at2) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at3) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at4) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at5) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at6) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at7) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at8) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at9) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at10) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at11) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at12) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at13) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at14) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at15) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at16) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at17) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at18) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at19) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at20) (`dataset'_`SHORTLANGLABEL'_coh`cohort'_gr`grade'_rd`round'_at21) "'
                        loc result_row = `" `raw_results' "'
                        `debug' post `postLorenz' `result_row'
                        if `verbose' set trace off
                        qui lorenz `LANGVAR' if grade==`grade' & cohort==`cohort', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `grade' Coh`cohort' `LANGLABEL'" "by Round of Assessment") text(1 25 "Grade `grade' Coh`cohort' `LANGLABEL'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
                        qui graph save bins/`LANGLABEL'_gr`grade'_coh`cohort'_lorenz_`dataset', replace
                        qui graph export bins/`LANGLABEL'_gr`grade'_coh`cohort'_lorenz_`dataset'.png, replace width(800) height(500)
                    }
                }
                else if "`dataset'"=="tusome" {
                    qui lorenz estimate `LANGVAR' if grade==`grade' & treat_phase==`round'
                        return list
                        * pause
                        mat rmat = r(table)
                        foreach p of num 1/21 {
                            scalar `dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at`p' = rmat[1, `p']
                            `debug' di as result `dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at`p'
                        }
                        * lorenz `LANGVAR' if grade==`j' & cohort==`c', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `j' Coh`c' `LANG'" "by Round of Assessment") text(1 25 "Grade `j' Coh`c' `LANG'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
                        * lorenz graph, overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `j' Coh`c' `LANG'" "by Round of Assessment") text(1 25 "Grade `j' Coh`c' `LANG'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF")
                        if `verbose' set trace on
                        loc raw_results = `" ("`dataset'") ("`LANGLABEL'") (.) (`grade') (`round') (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at1) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at2) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at3) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at4) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at5) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at6) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at7) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at8) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at9) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at10) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at11) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at12) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at13) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at14) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at15) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at16) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at17) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at18) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at19) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at20) (`dataset'_`SHORTLANGLABEL'_gr`grade'_rd`round'_at21) "'
                        loc result_row = `" `raw_results' "'
                        `debug' post `postLorenz' `result_row'
                        if `verbose' set trace off
                        qui lorenz `LANGVAR' if grade==`grade', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `grade' `LANGLABEL'" "by Round of Assessment") text(1 25 "Grade `grade' `LANGLABEL'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
                        qui graph save bins/`LANGLABEL'_gr`grade'_lorenz_`dataset', replace
                        qui graph export bins/`LANGLABEL'_gr`grade'_lorenz_`dataset'.png, replace width(800) height(500)
                }
            }
        }
    }
}

postclose `postLorenz'
preserve
* save `lorenzes', replace
* preserve
use `lorenzes', clear

gen dataset_id = .
recode dataset_id (. = 1) if dataset=="primr"
recode dataset_id (. = 2) if dataset=="tusome"

label define lbl_dataset 1 "primr" 2 "tusome"
label val dataset_id lbl_dataset

gen language_id = .
recode language_id (. = 1) if language=="English"
recode language_id (. = 21) if language=="Kiswahili"
label define lbl_language 1 "English" 21 "Kiswahili"
label val language_id lbl_language

unab percentages: pct*
foreach p of loc percentages {
    replace `p' = 100 * `p'
}

save "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\bins\lorenz_data_both.dta", replace
export excel "lorenz_data_both.xlsx", firstrow(var) sheet("raw", mod)
pause "What do you see?"
di "Made it here..."
