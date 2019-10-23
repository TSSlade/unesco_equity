program define apply_analysis
    * syntax [varlist] [if] , over(varname) langlabel(string) resultsfile(string) [verbose(default=0) detail *]
    syntax [varlist] [if] , DATAset(string) CORE(varlist) RESultsfile(string) [ SVY(integer 1) EXTended(varlist) VARlabel(string) BENchmarks(varlist)  VERbose(integer 0) DEBug(integer 0)]

    // Assumptions
    // 'female' variable is coded 1 = female, 0 = male
    // 'benchmarks' varlist are dummy variables where 1 = in-group, 0 = out-group
    // 'urbanity' variable is a dummy variable where 1 = urban, 0 = rural
    // 'sestatus' varlist are dummy variables where 1 = in-group, 0 = out-group

    // Debugging the command inputs
    if `verbose' ==1 {
        di `"`0'"'
    }

    // optionally:
    loc apply_svy = cond(`svy' == 1, "svy:", " ") // Optionally applying survey weights
    loc svy_suff = cond("`apply_svy'" != " ", substr("`apply_svy'",1,3), " ")
    loc extended_sps = cond("`extended'"!="", 1, 0)

    // Define core subpopulations and extended subpopulations
    tempvar core_pops ext_pops iszero ingroup
    egen core_pops = group(`core'), label
    levelsof core_pops, loc(core_pops_id)
    loc core_pops_ct: word count `core_pops_id'
    if `extended_sps' {
        egen ext_pops = group(`core' `extended'), label trunc(10)
        levelsof ext_pops, loc(ext_pops_id)
        loc ext_pops_ct: word count `ext_pops_id'
    }

    // Reporting on the results of the subpopulations
    if `verbose' {
        di as error "These were the variables provided to define core subpopulations of interest:"
        di as result "`core'"
        di as error "These are the resultant core subpopulations:"
        foreach sp of loc core_pops_ct {
            * di as result "`: word `sp' of `core_pops_id': `: word `sp' of `core_pops_lbls'"
            di as result "`: word `sp' of `core_pops_id''"
        }
        if `extended_sps' {
            di as error "These were the variables provided to define extended subpopulations of interest:"
            di as result "`extended'"
            di as error "These are the resultant extended subpopulations:"
            foreach ep of loc ext_pops_ct {
                * di as result "`: word `ep' of `ext_pops_ids': `: word `ep' of `ext_pops_lbls'"
                di as result "`: word `ep' of `ext_pops_ids'"
            }
        }
    }

    // Declare postfile / results-holding infrastructure
    tempfile results            // This is a placeholder for our results
    tempname postRes            // Ensures no namespace clashes
    local target `resultsfile'  // User-supplied: this is where we want the results to be written to file

    // The variables we want for each of our observations (where each obs is a subpopulation)
    // Core variables: expect 31 of them
    local coreVars "str20(dataset performance_measure measure_label) weighted str60 subpop_label subpop_id float(mean mean_95cil mean_95cih se sd cv pct_zero p90 p10 ratio_p90p10 p75 p25 ratio_p75p25 gini ge0 se_ge0 ge0_95cil ge0_95cih ge1 se_ge1 ge1_95cil ge1_95cih ge2 se_ge2 ge2_95cil ge2_95cih)"
    local varsOfInterest `"`coreVars'"'

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
        `apply_svy' mean `v', over(core_pops) // mean, over() works well with multiple subgroups
        mat mean_results = r(table)
        foreach mr of loc core_pops_id {
            loc mean_sp`mr' = mean_results[1, `mr']
            loc se_sp`mr' = mean_results[2, `mr']
            loc mean_95cil_sp`mr' = mean_results[5, `mr']
            loc mean_95cih_sp`mr' = mean_results[6, `mr']
        }

        // Standard deviation
        estat sd
        mat sd_results = r(sd)
        foreach sd of loc core_pops_id {
            loc sd_sp`sd' = sd_results[1, `sd']
        }

        // Coefficient of variation
        if `svy' {
            estat cv
            mat cv_results = r(cv)
            foreach cv of loc core_pops_id {
                loc cv_sp`cv' = cv_results[1,`cv']
            }
        }
        else {
            di as result "Not survey-weighted: calculating coefficient of variation manually"
            foreach cv of loc core_pops_id {
                loc cv_sp`cv' = (sd_sp`cv' / mean_sp`cv') * 100
            }
        }

        // Percentiles for Ratio comparisons
        replace ingroup = 0
        foreach id of loc core_pops_id {
            summ `v' if core_pops==`id', detail
            loc p10_sp`id' = r(p10)
            loc p90_sp`id' = r(p90)
            loc p25_sp`id' = r(p25)
            loc p75_sp`id' = r(p75)
            loc ratio_p90p10_sp`id' = `p90_sp`id'' / `p10_sp`id''
            loc ratio_p75p25_sp`id' = `p75_sp`id'' / `p25_sp`id''

            // To get our survey-weighted gini coefficients
            if `svy' {
                pshare `v', gini svy(if core_pops==`id')
                mat gini_result = e(G)
                loc gini_sp`id' = gini_result[1,1]
            }
            else {
                pshare `v' if core_pops==`id', gini
                mat gini_result = e(G)
                loc gini_sp`id' = gini_result[1,1]
            }

            // To get our generalized entropy estimates
            replace ingroup = 1 if core_pops==`id'
                svygei `v', subpop(ingroup)         // svygei's subpop takes only in/out
                loc ge0_sp`id' = e(ge0)
                loc ge1_sp`id' = e(ge1)
                loc ge2_sp`id' = e(ge2)
                loc se_ge0_sp`id' = e(se_ge0)
                loc se_ge1_sp`id' = e(se_ge1)
                loc se_ge2_sp`id' = e(se_ge2)

                mat entropy_results = r(table)
                loc 95ci_width_ge0_sp`id' = entropy_results[5,2]
                loc 95ci_width_ge1_sp`id' = entropy_results[5,3]
                loc 95ci_width_ge2_sp`id' = entropy_results[5,4]
                loc ge0_95cil_sp`id' = `ge0_sp`id'' - `95ci_width_ge0_sp`id''
                loc ge1_95cil_sp`id' = `ge1_sp`id'' - `95ci_width_ge1_sp`id''
                loc ge2_95cil_sp`id' = `ge2_sp`id'' - `95ci_width_ge2_sp`id''
                loc ge0_95cih_sp`id' = `ge0_sp`id'' + `95ci_width_ge0_sp`id''
                loc ge1_95cih_sp`id' = `ge1_sp`id'' + `95ci_width_ge1_sp`id''
                loc ge2_95cih_sp`id' = `ge2_sp`id'' + `95ci_width_ge2_sp`id''
            * replace ingroup = 0

            // To get our zero-score reporting
            replace iszero = 1 if `v'==0
            recode iszero (. = 0)

            `apply_svy' mean iszero if ingroup
            mat results_matrix = r(table)
            loc pct_zero_sp`id' = results_matrix[1,1]

            // Resetting ingroup
            replace ingroup = 0
        }

        // Sending data to our postfile
        * local resultRow "("`dataset'") ("`curr_var'") (`j') ("`sp_label'") (gini[`j',1]) (`p90') (`p10') (`ratio_p90p10') (`p75') (`p25') (`ratio_p75p25') (`ge_0') (`ge_1') (`ge_2') (`pct_zero')"
        foreach id of loc core_pops_id {
            loc subpop_label: label core_pops `id'
            di as result "Exporting results for subpopulation `id': `subpop_label'"

            // Store these core results to be concatenated into the final post after adding in any optional ones
            loc coreResults " ("`dataset'") ("`performance_measure'") ("`measure_label'") (`svy') ("`subpop_label'") (`id') (`mean_sp`id'') (`mean_95cil_sp`id'') (`mean_95cih_sp`id'') (`se_sp`id'') (`sd_sp`id'') (`cv_sp`id'') (`pct_zero_sp`id'') (`p90_sp`id'') (`p10_sp`id'') (`ratio_p90p10_sp`id'') (`p75_sp`id'') (`p25_sp`id'') (`ratio_p75p25_sp`id'') (`gini_sp`id'') (`ge0_sp`id'') (`se_ge0_sp`id'') (`ge0_95cil_sp`id'') (`ge0_95cih_sp`id'') (`ge1_sp`id'') (`se_ge1_sp`id'') (`ge1_95cil_sp`id'') (`ge1_95cih_sp`id'') (`ge2_sp`id'') (`se_ge2_sp`id'') (`ge2_95cil_sp`id'') (`ge2_95cih_sp`id'') "
            capture assert `: word count coreVars' == `: word count coreResults'
                if !_rc==0 {
                di as error "The program returned a different number of result placeholders and results."
                di as result "These were the placeholders: `coreVars'"
                di as result "These were the results: `coreResults'"
                exit 9
            }

            local resultRow `" `coreResults' "'
            capture post `postRes' `resultRow'
            if !_rc==0 {
                di as error `"These are the results we attempted to post:"'
                di as result `"CoreVars: `coreVars'"'
                di as result `"CoreResults: `coreResults'"'
                exit _rc
            }
        }
    replace iszero = .
    loc pv `++pv'
    }

postclose `postRes'
preserve
use `results', clear
noisily di "Find results in `:pwd' at `target'"
save `target'.dta, replace
restore
drop core_pops iszero ingroup
capture drop ext_pops
end