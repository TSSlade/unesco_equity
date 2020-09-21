capture postutil clear
loc verbose = 0
loc debug = cond(`verbose'==1, "noisily", "quietly")
tempfile lorenzes            // This is a placeholder for our results
tempname postLorenz            // Ensures no namespace clashes

loc vars_of_interest = "str20(dataset language) cohort grade round pct_00 pct_05 pct_10 pct_15 pct_20 pct_25 pct_30 pct_35 pct_40 pct_45 pct_50 pct_55 pct_60 pct_65 pct_70 pct_75 pct_80 pct_85 pct_90 pct_95 pct_100"

postfile `postLorenz' `vars_of_interest' using `lorenzes'
cd "$HOME/unesco_equity"
local primr = "$HOME/projects\unesco_chapter\primr_unesco.dta"
local tusome = "$HOME/projects\unesco_chapter\tusome_unesco.dta"
local malawi = "$HOME/unesco_equity/malawi_unesco.dta"
local DRC = "$HOME/unesco_equity\DRC_unesco.dta"
//local languages = "English Kiswahili"
loc languages = "English"
//loc languages = "French"
* local langvars = "eng_orf kis_orf"
local langvars = "eng_orf"
//local langvars = "fre_orf"
// local datasets = "primr tusome"
// local datasets = "DRC"
// local cohortvars = "1 2 3"
// local grades = "2 4 6"
local datasets = "malawi"

// Loop through datasets
// ...then languages
// ...then rounds
// ...then grades
// ...then cohorts (if applicable)

// Datasets
//use `DRC', clear

foreach dataset of loc datasets {
    use ``dataset'', clear                // Nested local macro to pull data from URL above
	capture confirm variable cohort
	if !_rc {
            egen subpop = group(cohort treat_phase grade), label
               }
            else {
               egen subpop = group(treat_phase grade), label
               }
	local langs_ct: word count `languages'
	di `langs_ct'
	di `grades'
    gen resc_eng_orf = .
    gen resc_kis_orf = .

    levelsof treat_phase, loc(treat_phases)
	levelsof grade, loc(grades)

	di "`treat_phases'"
	capture confirm variable cohort
	if !_rc {
		levelsof cohort, loc(cohortvars)
		egen subpop = group(cohort treat_phase grade), label
		}
		else{
			egen subpop = group(treat_phase grade), label
		}
				
    // Languages
    foreach lang of num 1/`langs_ct' {
        loc LANGLABEL `: word `lang' of `languages''
		di "`LANGLABEL'"
        loc SHORTLANGLABEL = strlower(substr("`LANGLABEL'", 1, 3))
        di "`SHORTLANGLABEL'"
        if `verbose' pause
        loc LANGVAR `: word `lang' of `langvars''
        * loc BASEVAR = substr("`lang'", 6, 12)

        foreach s of loc subpops {
            qui summ(`BASEVAR') if subpop==`s'
            loc max = `r(max)'
            loc min = `r(min)'
            loc range = `max' - `min'
            if "`LANGVAR'"=="eng_orf" {
                replace resc_`lang' = ((`LANGVAR' - `min')/`range') * 210 if subpop==`s'
            }
            else if "`LANGVAR'"=="kis_orf" {
                replace resc_`lang' = ((`LANGVAR' - `min')/`range') * 168 if subpop==`s'
            }
            }

        // Rounds
        foreach round of loc treat_phases {
            // Grades
			di "inside treat phases"
            foreach grade of loc grades {
			    di "grade:`grade'"
                // if "`dataset'"=="primr" {
				capture confirm variable cohort
				if !_rc {
                // Cohort if applicable
					di "Cohort exists"
                    foreach cohort of loc cohortvars {
					    count if grade==`grade' & treat_phase==`round' & !missing(`LANGVAR')
						if r(N)>0 {
							qui lorenz estimate `LANGVAR' if grade==`grade' & cohort==`cohort' & treat_phase==`round'
							return list
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
							qui lorenz `LANGVAR' if grade==`grade' & cohort==`cohort', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Rescaled Grade `grade' Coh`cohort' `LANGLABEL'" "by Round of Assessment") text(1 25 "Grade `grade' Coh`cohort' `LANGLABEL'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
							qui graph save bins/resc_`LANGLABEL'_gr`grade'_coh`cohort'_lorenz_`dataset', replace
							qui graph export bins/resc_`LANGLABEL'_gr`grade'_coh`cohort'_lorenz_`dataset'.png, replace width(800) height(500)
					}
					else{
				    di "No observations with nonmissing language variable."
				}
						
				}
                }
                else{
					summarize `LANGVAR' if grade==`grade' & treat_phase==`round'
					
					count if grade==`grade' & treat_phase==`round' & !missing(`LANGVAR')
					if r(N)>0 {
                    qui lorenz estimate `LANGVAR' if grade==`grade' & treat_phase==`round'
                        return list
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
                        qui lorenz `LANGVAR' if grade==`grade', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Rescaled Grade `grade' `LANGLABEL'" "by Round of Assessment") text(1 25 "Grade `grade' `LANGLABEL'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
                        qui graph save bins/resc_`LANGLABEL'_gr`grade'_lorenz_`dataset', replace
                        qui graph export bins/resc_`LANGLABEL'_gr`grade'_lorenz_`dataset'.png, replace width(800) height(500)
                }
				else{
				    di "No observations with nonmissing language variable."
				}
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
recode dataset_id (. = 3) if dataset=="malawi"

label define lbl_dataset 1 "primr" 2 "tusome" 3 "malawi"
label val dataset_id lbl_dataset

gen language_id = .
recode language_id (. = 1) if language=="English"
recode language_id (. = 21) if language=="Kiswahili"
recode language_id (. = 3) if language=="French"
label define lbl_language 1 "English" 21 "Kiswahili" 3 "French"
label val language_id lbl_language

unab percentages: pct*
foreach p of loc percentages {
    replace `p' = 100 * `p'
}

local c_time: di %td_CY-N-D date("$S_DATE", "DMY") "_$S_TIME"
global c_datetime=trim(subinstr("`c_time'",":","-",.))
save "$HOME/unesco_equity\bins\lorenz_data_both.dta", replace
export excel "lorenz_data_$c_datetime.xlsx", firstrow(var) sheet("raw", modify)
pause "What do you see?"
di "Made it here..."
