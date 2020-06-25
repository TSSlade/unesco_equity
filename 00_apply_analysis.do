program define apply_analysis
    * syntax [varlist] [if] , over(varname) langlabel(string) resultsfile(string) [verbose(default=0) detail *]
    syntax [varlist] [if] , DATAset(string) CORE(varlist) RESultsfile(string) [ PARent_ge2(varname) SVY(integer 1) WTvar(varname) ZEROsinentropy(integer 1) EXTended(varlist) VARlabel(string) BENchmarks(varlist) VERbose(integer 0) DEBug(integer 0)]

    // Assumptions
    // 'female' variable is coded 1 = female, 0 = male
    // 'benchmarks' varlist are dummy variables where 1 = in-group, 0 = out-group
    // 'urbanity' variable is a dummy variable where 1 = urban, 0 = rural
    // 'sestatus' varlist are dummy variables where 1 = in-group, 0 = out-group
	pause on
    // Debugging the command inputs
    if `verbose' ==1 {
        di `"`0'"'
    }

    if `svy' == 1 & "`wtvar'" == "" {
        di as error "-svy- asserted but no variable supplied for -wtvar-"
        exit
    }

    loc verbosity = cond(`verbose'==1, "noisily", "quietly")

    // optionally:
    loc apply_svy = cond(`svy' == 1, "svy:", " ") // Optionally applying survey weights
    loc svy_suff = cond("`apply_svy'" != " ", substr("`apply_svy'",1,3), " ")
    loc extended_sps = cond("`extended'"!="", 1, 0)

    // Define core subpopulations and extended subpopulations
    tempvar core_pops ext_pops iszero ingroup parent_pops
    egen core_pops = group(`core'), label
    levelsof core_pops, loc(core_pops_id)
    loc core_pops_label: value label core_pops      // So we can extract the labels later during debugging
    loc core_pops_ct: word count `core_pops_id'
    if `extended_sps' {
        egen ext_pops = group(`core' `extended'), label trunc(10)
        levelsof ext_pops, loc(ext_pops_id)
        loc ext_pops_ct: word count `ext_pops_id'
    }
    * egen parent_pops = group(`parent_ge2'), label
    * levelsof parent_pops, loc(parent_pops_id)
    * loc parent_pops_label: value label parent_pops      // So we can extract the labels later during debugging
    * loc parent_pops_ct: word count `parent_pops_id'

    // Reporting on the results of the subpopulations
    `verbosity': di as error "These were the variables provided to define core subpopulations of interest:"
    `verbosity': di as error "`core'"
    `verbosity': di as error "These are the resultant core subpopulations:"
    foreach sp of num 1/`core_pops_ct' {
        * di as result "`: word `sp' of `core_pops_id': `: word `sp' of `core_pops_lbls'"
        `verbosity': di as error "Subpop `sp': `: label `core_pops_label' `sp''"
    }
    if `extended_sps' {
        `verbosity': di as error "These were the variables provided to define extended subpopulations of interest:"
        `verbosity': di as error "`extended'"
        `verbosity': di as error "These are the resultant extended subpopulations:"
        foreach ep of loc ext_pops_ct {
            * di as result "`: word `ep' of `ext_pops_ids': `: word `ep' of `ext_pops_lbls'"
            `verbosity': di as error "`: word `ep' of `ext_pops_ids'"
        }
    }


    // Declare postfile / results-holding infrastructure
    tempfile results            // This is a placeholder for our results
    tempname postRes            // Ensures no namespace clashes
    local target `resultsfile'  // User-supplied: this is where we want the results to be written to file

    // The variables we want for each of our observations (where each obs is a subpopulation)
    // Core variables: expect 31 of them
    local coreVars "str20(dataset performance_measure measure_label) weighted str60(subpop_label) subpop_id float(mean mean_95cil mean_95cih se sd cv pct_zero p90 p10 ratio_p90p10 p75 p25 ratio_p75p25 gini)"
    if `zerosinentropy' {
        local entropyVars "ge2_overall ge2_ingroup ge2_outgroup ge2_for_subpop between_ge2 within_ge2"
        di as error "Because we are retaining the zeros for our entropy calculations, our output vars will be [`entropyVars']"
    }
    else {
        local entropyVars "gem1 ge0 ge1 ge2 gem1_se ge0_se ge1_se ge2_se gem1_95cil gem1_95cih ge0_95cil ge0_95cih ge1_95cil ge1_95cih ge2_95cil ge2_95cih"
        di as error "Because we are NOT retaining the zeros for our entropy calculations, our output vars will be [`entropyVars']"
    }

    local subpopct: word count `core'
    local subpopVars = " "
    foreach c of var `core' {
        capture confirm str var `c'
        if !_rc {
            di as error "Var `c' is `: type `c''"
            local subpopVars "`subpopVars' str20(`c')"
            * pause "Verify..."
        }
        else {
            di as error "Var `c' is numeric"
            local subpopVars "`subpopVars' `c'"
        }
    }

    local varsOfInterest `" `coreVars' `subpopVars' `entropyVars' "'

    // This is where we actually define the postfile to hold our results
    postfile `postRes' `varsOfInterest' using `results'

    // Doing the analyses
    // Core analyses
    // Figuring out how many subpopulations we are looping over
    loc total_pops_ct = `core_pops_ct'
    if `extended_sps' {
        loc total_pops_ct += `ext_pops_ct'
    }

    loc pv = 1                      // We want to be able to track our iteration so we can pull in a user-friendly name for the language variable
    gen iszero = .
    gen ingroup = .                 // Several of the functions' over() options only work with a binary in/out variable

    // Looping over the performance measures we were given
    foreach v of loc varlist {
        loc performance_measure = "`: word `pv' of `varlist''"
        loc measure_label = "`: word `pv' of `varlabel''"
        di as error "||====================================||"
        di as result "Analyzing [`v']"

        // Recording whether weighted
        loc weighted = `svy'

        // Initial loop for the core pops
        // Mean, Standard Error, 95CIs for means
        capture `verbosity' {
            if `debug' noisily di as error "Calculating means for [`v']"
            `apply_svy' mean `v', over(core_pops) // mean, over() works well with multiple subgroups
            mat mean_results = r(table)
            mat mean_counts = e(_N)
            foreach id of loc core_pops_id {
                loc mean_sp`id' = mean_results[1, `id']
                loc se_sp`id' = mean_results[2, `id']
                loc mean_95cil_sp`id' = mean_results[5, `id']
                loc mean_95cih_sp`id' = mean_results[6, `id']
            }

            // Standard deviation
            if `debug' noisily di as error "Calculating SDs for [`v']"
            estat sd
            mat sd_results = r(sd)
            foreach id of loc core_pops_id {
                loc sd_sp`id' = sd_results[1, `id']
            }

            // Coefficient of variation
            if `debug' noisily di as error "Calculating CVs for [`v']"
            if `svy' {
                if `debug' noisily di as error "...via -estat cv- method"
                estat cv
                mat cv_results = r(cv)
                foreach id of loc core_pops_id {
                    loc cv_sp`id' = cv_results[1,`id']
                }
            }
            else {
                if `debug' noisily di as error "...via manual method"
                foreach id of loc core_pops_id {
                    loc cv_sp`id' = (`sd_sp`id'' / `mean_sp`id'') * 100
                }
            }
        }
        if _rc==2000 {
            di as error "Subgroup being analyzed has obs count of 0"
            di "{p}Working on [`v']{p_end}{p}Counts were{p_end}"
            mat list mean_counts
        }
        else if _rc != 0 {
            loc code = _rc
            di as error "An error arose while calculating{p}means{p_end}{p}std_errors{p_end}{p}std_devs{p_end}{p}coeff_vars{p_end}"
            pause di as inform "The program will exit with return code `code': care to investigate?"
            exit `code'
        }

        // Percentiles for Ratio comparisons
        replace ingroup = 0
        foreach id of loc core_pops_id {
            if `debug' noisily di as error "Looping over core_pops"
            if `debug' noisily count if core_pops==`id' & `v' != .
            loc spnonmiss = r(N)
            if `spnonmiss' == 0 {
                `verbosity': di as error "No valid [`v'] for subpop [`id']. Skipping ahead."
                continue
            }
            capture `verbosity' {
                if `debug' noisily di as error "Summarizing to get percentiles"
                summ `v' if core_pops==`id', detail         // Will throw an error code of zero (none) if subpop all missing
                mat summ_counts = e(N_sub)
                // We capture percentiles here - in the absence of weights - because none of the
                // options below will accept weights PROPERLY (as pweight rather than aweight) while
                // also retaining the zeros.
                loc p10_sp`id' = r(p10)
                loc p90_sp`id' = r(p90)
                loc p25_sp`id' = r(p25)
                loc p75_sp`id' = r(p75)
                loc ratio_p90p10_sp`id' = `p90_sp`id'' / `p10_sp`id''
                loc ratio_p75p25_sp`id' = `p75_sp`id'' / `p25_sp`id''

                // To get our survey-weighted gini coefficients
                if `svy' {
                    if `debug' noisily di as error "Calculating survey-weighted Gini for [`v'] for subpop [`id']"

                    // Capturing Gini using pshare because it retains zeros and accepts
                    // svy weights as pweights.
                    // Need to first check whether all of the observations for the subpop are 0.
                    // If they are, the pshare command will fail b/c there's no way to calculate
                    // the Gini of all zeros.
                    inspect `v' if core_pops==`id'
                    if r(N_0) != r(N) {
                        pshare `v', gini svy(if core_pops==`id')
                        mat gini_result = e(G)
                        mat gini_counts = e(N_sub)
                        loc gini_sp`id' = gini_result[1,1]
                    }
                    else {
                        loc gini_sp`id' = .
                    }
                }
                else {
                    if `debug' noisily di as error "Calculating Gini for [`v'] for subpop [`id'] without weights"

                    pshare `v' if core_pops==`id', gini
                    mat gini_result = e(G)
                    * mat gini_counts = e(N_sub) // Does not exist for unweighted pshare
                    loc gini_sp`id' = gini_result[1,1]
                }
            }
            if inlist(_rc, 2000) {
                loc code = _rc
                di as result "Summary counts for [`v'] and [`id']:"
                mat list summ_counts
                if `code' == 2000 di as error "{p}While working on percentile and Gini calculations for [`v'] and [`id'] encountered only zero values for the performance measure{p_end} (i.e., _rc = `code')"
                loc gini_sp`id' = .
            }
            if inlist(_rc, 461) {
                loc code = _rc
                if `code' == 461 di as error "{p}While working on percentile and Gini calculations for [`v'] and [`id'] encountered only missing values for the performance measure{p_end}"
                loc gini_sp`id' = .
            }


            else if _rc != 0 {
                loc code = _rc
                di as error "Another error arose while calculating{p}percentiles and Gini coefficients for [`v'] and [`id']{p_end}"
                pause di as inform "The program will exit with return code `code': care to investigate?"
                exit `code'
            }

            capture `verbosity' {
                if `debug' noisily di as error "Calculating generalized entropy estimates for [`v'] for subpop [`id']"
                if `debug' noisily di as error `""Zeros in Entropy" parameter was [`zerosinentropy']"'
                // To get our generalized entropy estimates
                replace ingroup = 1 if core_pops==`id'
                    * svygei `v', subpop(ingroup)         // svygei's subpop takes only in/out
                    if `zerosinentropy' {
                    // If we are retaining the zeros, this enables us to get generalized entropy
                    // class with parameter 2 [GE(2)]. However, it requires us to apply weights
                    // inaccurately (as aweights, not pweights) and therefore standard errors
                    // and confidence intervals should not be trusted. Nor should Gini coefficients,
                    // which the package could also provide.
                        di as error "Deriving GEs using ineqdec0 and in/outgroup approach b/c we need to retain zero scores"
                            * ineqdec0 `v' [aweight=`wtvar'], bygroup(ingroup)
                            if `svy' {
                                ineqdec0 `v' [aweight=`wtvar'], bygroup(core_pops)
                            }
                            else {
                                ineqdec0 `v', bygroup(core_pops)
                            }
                            loc ge2_overall = r(ge2)
                            loc ge2_sp`id'_ingroup = . // r(ge2_1)
                            loc ge2_sp`id'_outgroup = . // r(ge2_0)
                            loc ge2_for_subpop_sp`id' = r(ge2_`id')
                            loc between_ge2_sp`id' = r(between_ge2)
                            loc within_ge2_sp`id' = r(within_ge2)
                    di "Inside the yes-zeros loop: zerosinentropy = [`zerosinentropy']"
                    }
                    else {
                    // If we are NOT retaining the zeros, this enables us to get generalized entropy
                    // class with parameters -1, 0, 1, and 2 while ALSO applying weights properly.
                    // So here we can report standard errors, confidence intervals, etc.
                        di as error "Deriving GEs using svygei b/c we can discard zero scores and we want 95CIs"
                        svygei `v', sub(ingroup)
                        mat gem_result = r(table)
                        loc gem1_sp`id' = e(gem1)
                        loc ge0_sp`id' = e(ge0)
                        loc ge1_sp`id' = e(ge1)
                        loc ge2_sp`id' = e(ge2)
                        loc gem1_se_sp`id' = e(se_gem1)
                        loc ge0_se_sp`id' = e(se_ge0)
                        loc ge1_se_sp`id' = e(se_ge1)
                        loc ge2_se_sp`id' = e(se_ge2)
                        loc gem1_95ci_span_sp`id' = gem_result[5,1]
                        loc gem1_95cil_sp`id' = (`gem1_sp`id'' + `gem1_95ci_span_sp`id'')
                        loc gem1_95cih_sp`id' = (`gem1_sp`id'' - `gem1_95ci_span_sp`id'')
                        loc ge0_95ci_span_sp`id' = gem_result[5,2]
                        loc ge0_95cil_sp`id' = (`ge0_sp`id'' + `ge0_95ci_span_sp`id'')
                        loc ge0_95cih_sp`id' = (`ge0_sp`id'' - `ge0_95ci_span_sp`id'')
                        loc ge1_95ci_span_sp`id' = gem_result[5,3]
                        loc ge1_95cil_sp`id' = (`ge1_sp`id'' + `ge1_95ci_span_sp`id'')
                        loc ge1_95cih_sp`id' = (`ge1_sp`id'' - `ge1_95ci_span_sp`id'')
                        loc ge2_95ci_span_sp`id' = gem_result[5,4]
                        loc ge2_95cil_sp`id' = (`ge2_sp`id'' + `ge2_95ci_span_sp`id'')
                        loc ge2_95cih_sp`id' = (`ge2_sp`id'' - `ge2_95ci_span_sp`id'')
                    }
            }
            if _rc==2000 {
                di as error "{p}While working on [`v'] and [`id']{p_end} encountered subgroup where the scores cannot support the calculation requested{p}GEI counts were{p_end}"
            }
            else if _rc != 0 {
                loc code = _rc
                di as error "Another error arose while calculating{p}Generalized entropy indices for [`v'] and [`id']{p_end}"
                pause di as inform "The program will exit with return code `code': care to investigate first?"
                exit `code'
            }

            capture `verbosity' {
                if `debug' noisily di as error "Calculating pct_zero for [`v'] for subpop [`id']"
                // To get our zero-score reporting
                replace iszero = 1 if `v'==0
                recode iszero (. = 0)

                `apply_svy' mean iszero if ingroup
                mat results_matrix = r(table)
                loc pct_zero_sp`id' = results_matrix[1,1]

                // Resetting ingroup
                replace ingroup = 0
            }
            if _rc==2000 {
                di as error "{p}While calculating pct_zeros [`v'] encountered where the scores cannot support the calculation requested{p_end}"
                mat list mean_counts
            }
            else if _rc != 0 {
                di as error "Another error arose while calculating"
                di as error "{p}means{p_end}{p}std_errors{p_end}{p}std_devs{p_end}{p}coeff_vars{p_end}"
            }

            loc subpopResults_`id' = ""
            foreach s of num 1/`subpopct' {
                loc varToPopulate "`: word `s' of `core''"
                levelsof `varToPopulate' if core_pops==`id', loc(toWrite)
                loc subpopResult_`s'_sp`id' = `toWrite'
                capture confirm str var `varToPopulate'
                if !_rc  {
                    loc subpopResults_`id' = `"`subpopResults_`id'' ("`subpopResult_`s'_sp`id''") "'
                }
                else {
                    loc subpopResults_`id' = `"`subpopResults_`id'' (`subpopResult_`s'_sp`id'') "'
                }
            }
        }

        // Sending data to our postfile
        * local resultRow "("`dataset'") ("`curr_var'") (`j') ("`sp_label'") (gini[`j',1]) (`p90') (`p10') (`ratio_p90p10') (`p75') (`p25') (`ratio_p75p25') (`ge_0') (`ge_1') (`ge_2') (`pct_zero')"
        foreach id of loc core_pops_id {
            loc subpop_label  = subinstr("`: label core_pops `id''"," ", "_", .)
            if `debug' noisily noisily di as result `"Exporting results for subpopulation `id': `subpop_label'"'

            // Store these core results to be concatenated into the final post after adding in any optional ones
            loc coreResults " ("`dataset'") ("`performance_measure'") ("`measure_label'") (`svy') ("`subpop_label'") (`id') (`mean_sp`id'') (`mean_95cil_sp`id'') (`mean_95cih_sp`id'') (`se_sp`id'') (`sd_sp`id'') (`cv_sp`id'') (`pct_zero_sp`id'') (`p90_sp`id'') (`p10_sp`id'') (`ratio_p90p10_sp`id'') (`p75_sp`id'') (`p25_sp`id'') (`ratio_p75p25_sp`id'') (`gini_sp`id'') "
            if `zerosinentropy' {
                loc entropyResults "(`ge2_overall') (`ge2_sp`id'_ingroup') (`ge2_sp`id'_outgroup') (`ge2_for_subpop_sp`id'') (`between_ge2_sp`id'') (`within_ge2_sp`id'') "
            }
            else {
                loc entropyResults " (`gem1_sp_`id'') (`ge0_sp_`id'') (`ge1_sp_`id'') (`ge2_overall') (`ge2_sp_`id'_ingroup') (`ge2_sp_`id'_outgroup') (`gem1_se_sp_`id'') (`ge0_se_sp_`id'') (`ge1_se_sp_`id'') (`ge2_se_sp_`id'') (`gem1_95cil_sp_`id'') (`gem1_95cih_sp_`id'') (`ge0_95cil_sp_`id'') (`ge0_95cih_sp_`id'') (`ge1_95cil_sp_`id'') (`ge1_95cih_sp_`id'') (`ge2_95cil_sp_`id'') (`ge2_95cih_sp_`id'') "
            }

            loc resultsOfInterest = `" `coreResults' `subpopResults_`id'' `entropyResults'"'
            loc output_tbshoot = subinstr(`"`varsOfInterest'"', "str20", "", .)
            loc output_tbshoot = subinstr(`"`output_tbshoot'"', "str60", "", .)
            loc output_tbshoot = subinstr(`"`output_tbshoot'"', "(", "", .)
            loc output_tbshoot = subinstr(`"`output_tbshoot'"', ")", "", .)
            loc output_ct: word count `output_tbshoot'

            capture assert `: word count varsOfInterest' == `: word count resultsOfInterest'
                if !_rc==0 {
                loc code = _rc
                di as error "The program returned a different number of result placeholders and results."
                di as result "These were the placeholders: `varsOfInterest'"
                di as result "These were the results: `resultsOfInterest'"
                pause "The program will exit with return code `code': care to investigate first?"
                exit `code'
            }
			di as error "Printing results row"
			di as error `" `resultsOfInterest' "'
			local row_ct: word count `resultsOfInterest'
			di as error `row_ct'
			//pause
            local resultRow `" `resultsOfInterest' "'
			
            capture noisily post `postRes' `resultRow'
            if !_rc==0 {
                loc code = _rc
                di as error `"These are the results we attempted to post:"'

                foreach o of num 1/`output_ct' {
                    di as error `" `o') `: word `o' of `output_tbshoot'' :: `: word `o' of `resultsOfInterest'' "'
                }

                pause di as inform "The program will exit with return code `code': care to investigate first?"
                exit `code'
            }
        }
        replace iszero = .
        loc pv `++pv'
    }

* set trace on
foreach c of var `core' {
    capture confirm str var `c'
    if _rc != 0 {
        label save `: value label `c'' using 99_labels_`c', replace
    }
}

postclose `postRes'
preserve
use `results', clear

* foreach c of var `core' {
*     label val `c' lbl_`c'_copy
* }
foreach c of var `core' {
    capture confirm str var `c'
    if _rc != 0 {
        do labels_`c'.do
        label val `c' lbl_`c'
    }
}
* set trace off
`verbosity' di "Find results in `:pwd' at `target'"
save `target'.dta, replace
* pause "Check appropriately labeled..."
restore 
drop core_pops iszero ingroup
label drop core_pops
capture drop ext_pops
end
