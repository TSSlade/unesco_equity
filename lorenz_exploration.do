capture postutil clear      
tempfile lorenzes            // This is a placeholder for our results
tempname postLorenz            // Ensures no namespace clashes

loc vars_of_interest = "str20(dataset language) grade cohort round pct_00 pct_05 pct_10 pct_15 pct_20 pct_25 pct_30 pct_35 pct_40 pct_45 pct_50 pct_55 pct_60 pct_65 pct_70 pct_75 pct_80 pct_85 pct_90 pct_95 pct_100"

postfile `postLorenz' `vars_of_interest' using `lorenzes'

local primr = "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\primr_unesco.dta"
* local tusome = "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\tusome_unesco.dta"
local languages = "English Kiswahili"
local langvars = "eng_orf kis_orf"
* local datasets = "primr tusome"
local datasets = "primr"
local cohortvars = "1 2 3"
levelsof treat_phase, loc(treat_phases)
foreach d of loc datasets {
    use ``d'', clear
    foreach i of num 1/2 {
        loc LANG `: word `i' of `languages''
        loc LANGVAR `: word `i' of `langvars''
        foreach c of loc cohortvars {
            foreach j of num 1/2 {
                foreach t of loc treat_phases {
                    qui lorenz estimate `LANGVAR' if grade==`j' & cohort==`c' & treat_phase==`t'
                    return list
                    * pause
                    mat rmat = r(table)
                    foreach p of num 1/21 {
                        scalar `d'_`LANG'_coh`c'_gr`j'_rd`t'_at`p' = rmat[1, `p']
                        di as error `d'_`LANG'_coh`c'_gr`j'_rd`t'_at`p'
                    }
                    * lorenz `LANGVAR' if grade==`j' & cohort==`c', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `j' Coh`c' `LANG'" "by Round of Assessment") text(1 25 "Grade `j' Coh`c' `LANG'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
                    * lorenz graph, overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `j' Coh`c' `LANG'" "by Round of Assessment") text(1 25 "Grade `j' Coh`c' `LANG'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF")
                    set trace on
                    loc raw_results = `" ("`d'") ("`LANG'") (`j') (`c') (`t') (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at1) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at2) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at3) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at4) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at5) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at6) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at7) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at8) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at9) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at10) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at11) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at12) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at13) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at14) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at15) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at16) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at17) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at18) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at19) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at20) (`d'_`LANG'_coh`c'_gr`j'_rd`t'_at21) "'
                    loc result_row = `" `raw_results' "'
                    noisily post `postLorenz' `result_row'
                    set trace off
                    lorenz `LANGVAR' if grade==`j' & cohort==`c', svy over(treat_phase) graph(overlay aspectratio(1) xlabels(,grid) legend(cols(1)) ciopts(recast(rline) lp(dash)) title("Lorenz curve for Grade `j' Coh`c' `LANG'" "by Round of Assessment") text(1 25 "Grade `j' Coh`c' `LANG'", orient(horizontal) justification(left) box) xtitle("Percentage of Population") ytitle("Cumulative Proportion of ORF"))
                    graph save bins/`LANG'_gr`j'_coh`c'_lorenz_`d', replace
                    qui graph export bins/`LANG'_gr`j'_coh`c'_lorenz_`d'.png, replace width(800) height(500)
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
save "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\bins\lorenz_data_primr.dta", replace
pause "What do you see?"
di "Made it here..."


gen dataset_id = 1
label define lbl_dataset 1 "primr"
label val language_id lbl_language

gen language_id = .
recode language_id (. = 1) if language=="English"
recode language_id (. = 21) if language=="Kiswahili"
label define lbl_language 1 "English" 21 "Kiswahili"
label val dataset_id lbl_dataset
