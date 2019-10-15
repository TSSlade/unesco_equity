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
log using "egra_analysis_$c_datetime.txt", text name(main_log)

* use $tusome_src

* svyset

* // Start defining subpopulations we'll need
* egen sub_population = group(treat_phase grade)
* levelsof(sub_population), loc(sub_pop_ids)              // Store sub_population IDs for later use
* local n_sub_pops: word count `sub_pop_ids'              // Need the ct for loops

* label define lbl_sub_population 1 "Gr 1 Baseline" 2 "Gr 2 Baseline" 3 "Gr 1 Midline" 4 "Gr 2 Midline", replace      // Let's make some labels
* label val sub_population lbl_sub_population             // ...and apply them
* local subpop_names `" "Gr 1 Baseline" "Gr 2 Baseline" "Gr 1 Midline" "Gr 2 Midline" "'

* local cluster_levels "school student"
* local n_cluster_levels: word count `cluster_levels'
* local clustered_lang_vars "schl_eng_orf schl_kis_orf"
* local clustered_zero_vars "schl_zero_pct_eng schl_zero_pct_kis"

* // Sanity check
* groups grade treat_phase sub_population
* pause       // Just to make you think about it...

* // Start defining elements of our other loops
* local lang_vars "e_orf_a k_orf"                         // Variable names for our ORF
* local n_lang_vars : word count `lang_vars'              // Need a counter to convert varnames into human names
* local lang_names "eng kis"                              // Define the human names
* assert `n_lang_vars'==`:word count `lang_names''        // Make sure these list lengths match
* local zero_vars "eng_zero kis_zero"                     // Variable names for our zero-score dummies

* // Let's generate some school-clustered performance measures
* foreach i of num 1/`n_lang_vars' {                      // Looping over our languages
*     local lang_name `: word `i' of `lang_names''
*     local lang_var `: word `i' of `lang_vars''
*     egen schl_`lang_name'_orf = mean(`lang_var'), by(school_code sub_population)               // School-level ORF by language
*     gen `lang_name'_zero = 1 if `lang_var'==0                                                  // Zero-score dummy for each child
*     recode `lang_name'_zero (. = 0)                                                             // Making non-zeros non-missing for the dummy var
*     egen schl_zero_pct_`lang_name' = mean(`lang_name'_zero), by(school_code sub_population)     // School-level pct of zeros by lang
* }

include primr_config.do

capture postutil clear      // Wiping out any open postfiles we may have

// Loops to execute our analyses and write the results to disk
* set trace on
tempname results_on_fly
local destination "inequality_calculations.dta"
postfile `results_on_fly' str20 (dataset language subpop_name clustering) int (subpop_id) float (ratio_p90p10_fluency ratio_p75p25_fluency between_ge0_fluency within_g0_fluency between_ge1_fluency within_ge1_fluency between_ge2_fluency within_ge2_fluency geml_fluency ge0_fluency ge1_fluency ge2_fluency gini_fluency sen_welfare_fluency mean_subgroup_fluency mean_relative_fluency income_share_fluency sd_fluency coeffvar_fluency ratio_p90p10_zero ratio_p75p25_zero between_ge0_zero within_g0_zero between_ge1_zero within_ge1_zero between_ge2_zero within_ge2_zero geml_zero ge0_zero ge1_zero ge2_zero gini_zero sen_welfare_zero mean_subgroup_zero mean_relative_zero income_share_zero sd_zero coeffvar_zero) using "$p_dir/`destination'", replace
* set trace off
* set trace on
foreach i of num 1/`n_lang_vars' {                              // Looping over Eng, Kis
    foreach s of num 1/`n_sub_pops' {                           // Looping over grade, treatment phase
        foreach c of num 1/`n_cluster_levels' {                 // Looping over clustering at school level (or not)
            local clustering `: word `c' of `cluster_levels''   // Human-readable clustering status
            di "Cluster status: [`clustering']"
            * pause
            if `c'== 1 {
                local lang_var `: word `i' of `clustered_lang_vars''    // School-level clustering --> schl_eng_orf | schl_kis_orf
                local zero_var `: word `i' of `zero_vars''              // School-level clustering --> schl_zero_pct_eng | schl_zero_pct_kis
            }
            else {
                local lang_var `: word `i' of `lang_vars''              // No clustering --> e_orf_a | k_orf
                local zero_var `: word `i' of `zero_vars''              // No clustering --> e_orf_a | k_orf
            }
            // Getting inconsistent results when operating directly on ineqdeq0 using bygroup(sub_population), so doing it manually
            preserve
            keep if sub_population==`s'
            local subpop_name `: word `s' of `subpop_names''            // Human-readable (Gr 1 Baseline, etc.)
            local lang_name `: word `i' of `lang_names''                // HUman-readable (eng, kis)
            di as error "++++++++++++++++++++++++++++++++++++++"
            di as result "Now writing results for i=[`i'], lang_name=[`lang_name'], lang_var=[`lang_var']"
            di as error "++++++++++++++++++++++++++++++++++++++"
            // Calculating for positive performance
            * ineqdec0 `lang_var', bygroup(sub_population) welfare
            ineqdec0 `lang_var', bygroup(sub_population) welfare
            scalar define ratio_p90p10_fluency = `r(p90p10)'
            scalar define ratio_p75p25_fluency = `r(p75p25)'
            capture scalar define between_ge0_fluency = `r(between_ge0)'
            capture scalar define within_g0_fluency = `r(within_ge0)'
            capture scalar define between_ge1_fluency = `r(between_ge1)'
            capture scalar define within_ge1_fluency = `r(within_ge1)'
            scalar define between_ge2_fluency = `r(between_ge2)'
            scalar define within_ge2_fluency = `r(within_ge2)'

            capture scalar define geml_fluency = `r(geml_`s')'
            capture scalar define ge0_fluency = `r(ge_0`s')'
            capture scalar define ge1_fluency = `r(ge_1`s')'
            capture scalar define ge2_fluency = `r(ge_2`s')'
            scalar define gini_fluency = `r(gini_`s')'
            scalar define sen_welfare_fluency = `r(wgini_`s')'
            scalar define mean_subgroup_fluency = `r(mean_`s')'
            scalar define mean_relative_fluency = `r(lambda_`s')'
            scalar define income_share_fluency = `r(theta_`s')'
            scalar define sd_fluency = `r(sd)'
            scalar define coeffvar_fluency = sd_fluency / mean_subgroup_fluency

            di as error "++++++++++++++++++++++++++++++++++++++"
            di as result "Now writing results for i=[`i'], zero_var=[`zero_var']"
            di as error "++++++++++++++++++++++++++++++++++++++"
            // Calculating for zeros
            ineqdec0 `zero_var', bygroup(sub_population) welfare
            scalar define ratio_p90p10_zero = `r(p90p10)'
            scalar define ratio_p75p25_zero = `r(p75p25)'
            capture scalar define between_ge0_zero = `r(between_ge0)'
            capture scalar define within_g0_zero = `r(within_ge0)'
            capture scalar define between_ge1_zero = `r(between_ge1)'
            capture scalar define within_ge1_zero = `r(within_ge1)'
            scalar define between_ge2_zero = `r(between_ge2)'
            scalar define within_ge2_zero = `r(within_ge2)'

            capture scalar define geml_zero = `r(geml_`s')'
            capture scalar define ge0_zero = `r(ge_0`s')'
            capture scalar define ge1_zero = `r(ge_1`s')'
            capture scalar define ge2_zero = `r(ge_2`s')'
            scalar define gini_zero = `r(gini_`s')'
            scalar define sen_welfare_zero = `r(wgini_`s')'
            scalar define mean_subgroup_zero = `r(mean_`s')'
            scalar define mean_relative_zero = `r(lambda_`s')'
            scalar define income_share_zero = `r(theta_`s')'
            scalar define sd_zero = `r(sd)'
            scalar define coeffvar_zero = sd_zero / mean_subgroup_zero
            * loc to_post = `" "`dataset'" "`lang_name'" "`subpop_name'" `s' `ratio_p90p10' `ratio_p75p25' between_ge0 within_g0 between_ge1 within_ge1 between_ge2 within_ge2 geml ge0 ge1 ge2 gini sen_welfare mean_subgroup mean_relative income_share sd coeffvar"'
            loc to_post = `" dataset language subpop_name clustering subpop_id ratio_p90p10_fluency ratio_p75p25_fluency between_ge0_fluency within_g0_fluency between_ge1_fluency within_ge1_fluency between_ge2_fluency within_ge2_fluency geml_fluency ge0_fluency ge1_fluency ge2_fluency gini_fluency sen_welfare_fluency mean_subgroup_fluency mean_relative_fluency income_share_fluency sd_fluency coeffvar_fluency ratio_p90p10_zero ratio_p75p25_zero between_ge0_zero within_g0_zero between_ge1_zero within_ge1_zero between_ge2_zero within_ge2_zero geml_zero ge0_zero ge1_zero ge2_zero gini_zero sen_welfare_zero mean_subgroup_zero mean_relative_zero income_share_zero sd_zero coeffvar_zero "'
            * set trace on
            foreach tp of loc to_post {
                capture di "`tp': " `tp'
                if _rc != 0 {
                    di "Scalar `tp' not found: defining as missing"
                    scalar define `tp' = .
                }
                else {
                    di "`tp': " `tp'
                }
            }
            set trace on
            post `results_on_fly' ("`dataset'") ("`lang_name'") ("`subpop_name'") ("`clustering'") (`s')  (ratio_p90p10_fluency) (ratio_p75p25_fluency) (between_ge0_fluency) (within_g0_fluency) (between_ge1_fluency) (within_ge1_fluency) (between_ge2_fluency) (within_ge2_fluency) (geml_fluency) (ge0_fluency) (ge1_fluency) (ge2_fluency) (gini_fluency) (sen_welfare_fluency) (mean_subgroup_fluency) (mean_relative_fluency) (income_share_fluency) (sd_fluency) (coeffvar_fluency) (ratio_p90p10_zero) (ratio_p75p25_zero) (between_ge0_zero) (within_g0_zero) (between_ge1_zero) (within_ge1_zero) (between_ge2_zero) (within_ge2_zero) (geml_zero) (ge0_zero) (ge1_zero) (ge2_zero) (gini_zero) (sen_welfare_zero) (mean_subgroup_zero) (mean_relative_zero) (income_share_zero) (sd_zero) (coeffvar_zero)
            set trace off
        restore
        }
    }
}


postclose `results_on_fly'
