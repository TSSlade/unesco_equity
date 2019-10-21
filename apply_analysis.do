program define apply_analysis
    * syntax [varlist] [if] , over(varname) langlabel(string) resultsfile(string) [verbose(default=0) detail *]
    syntax [varlist] [if] , DATAset(string) SUBpop_id(varname) RESultsfile(string) [ SVY(integer 1) SPlabel(string) VARlabel(string) BENchmarks(varlist) URBanity(varname) FEMale(varname) SEStatus(varlist) VERbose(integer 0) DEBug(integer 0)]

    // Assumptions
    // 'female' variable is coded 1 = female, 0 = male
    // 'benchmarks' varlist are dummy variables where 1 = in-group, 0 = out-group
    // 'urbanity' variable is a dummy variable where 1 = urban, 0 = rural
    // 'sestatus' varlist are dummy variables where 1 = in-group, 0 = out-group

    // Debugging the command inputs
    if `verbose' ==1 {
        di `"`0'"'
    }
    capture assert (`:word count `varlist''==`:word count `varlabel'') | `:word count `varlabel''==0   // Verify we have the same number of labels as input vars
    if _rc==9 {
        di "{p}You have not provided a variable label{p_end}{p}for each variable you wish to analyze.{p_end}"
        exit 9
    }

    // Categories we care about:
    loc label_measures = cond("`perf_label'" != "", 1, 0)  // performance measures (varlist) [, and their labels (PERF_label)]
    loc label_subpops = cond("`splabel'" != "", 1, 0)  // subpopulation ids (subpop_ID) [, and their labels (SPlabel)]
    // the file to hold the results (RESultsfile)

    // optionally:
    loc apply_svy = cond(`svy' == 1, "svy:", " ") // Optionally applying survey weights
    loc svy_suff = cond("`apply_svy'" != " ", substr("`apply_svy'",1,3), " ")
    loc by_fem = cond("`female'" != "", 1, 0)  // breakdown by sex (FEMale)
    loc by_bmark = cond("`benchmarks'" != "", 1, 0)  // breakdown by above/below benchmarks (BENchmarks) (possibly more than one)
    loc by_urban = cond("`urbanity'" != "", 1, 0)  // breakdown by urban / rural (URBanity)
    loc by_ses = cond("`SEStatus'" != "", 1, 0)  // breakdown by SES: SEStatus(varname), sestatus_CUT(string)

    // Report back intent:
    * noisily {
    *     di "{p}Given this input, the following analyses will be run:{p_end}"
    * }

    // Declare postfile / results-holding infrastructure
    tempfile results            // This is a placeholder for our results
    tempname postRes            // Ensures no namespace clashes
    local target `resultsfile'  // User-supplied: this is where we want the results to be written to file

    // The variables we want for each of our observations (where each obs is a subpopulation)
    // Core variables: expect 15 of them
    local coreVars "str20(dataset performance_measure) sub_pop_id str20(sub_pop_label measure_label) float(gini_wt subpop_mean std_err sd subpop_coeffvar subpop_pct_zero p90 p10 ratio_p90p10 p75 p25 ratio_p75p25 ge_0 ge_1 ge_2)"

    * // Optional labeling of core variables: expect 2 of them, just blank if note supplied
    * if `label_measures' local measureLabelVars "measure_label"
    * else loc measureLabelVars ""
    * if `label_subpops' local subpopLabelVars "sub_pop_label"
    * else loc subpopLabelVars ""

    // Optional additional breakdowns
    // femaleVars: expect 0 or 8 of them
    if `by_fem' local femaleVars "females_mean females_stderr females_pval females_95cilow females_95cihigh females_cv females_stddev females_pct_zero males_mean males_stderr males_pval males_95cilow males_95cihigh males_cv males_stddev males_pct_zero"
    else loc femaleVars ""

    // urbanVars: expect 0 or 8 of them
    if `by_urban' local urbanVars "urban_mean urban_stderr urban_pval urban_95cilow urban_95cihigh urban_cv urban_stddev urban_pct_zero rural_mean rural_stderr rural_pval rural_95cilow rural_95cihigh rural_cv rural_stddev rural_pct_zero"
    else loc urbanVars ""

    // benchmarkVars: expect 0 to N of them
    if `by_bmark' {
        local benchmarkVars = ""
        local benchmark_ct `: word count `benchmarks''
        foreach b of num 1/`benchmark_ct' {
            local benchmarkVars = "`benchmarkVars' `: word `b' of `benchmarks''_pct"
        }
    }
    else loc benchmarkVars ""

    // sesVars: expect 0 to N of them, in multiples of 4
    if `by_ses' {
        local sesVars ""
        local ses_grp_ct `: word count `sestatus''
        foreach s of num 1/`ses_grp_ct' {
            local ses_currvar `: word `s' of `sestatus''
            local sesVars = "`sesVars' `ses_currvar'_mean `ses_currvar'_stderr `ses_currvar'_cv `ses_currvar'_stddev `ses_currvar'_zero"
        }
    }
    else loc sesVars ""

* local varsOfInterest "str20(dataset language) sub_pop_id str40 sub_pop_label svy_gini p90 p10 ratio_p90p10 p75 p25 ratio_p75p25 ge_0 ge_1 ge_2 float pct_zero"
    // Concatenating our various selections into one master list of variables of interest
    if `verbose' {
        di as error "These are the requested coreVars:"
        di as result "`coreVars'"
        di as error "These are the requested measureLabelVars:"
        di as result "`measureLabelVars'"
        di as error "These are the requested subpopLabelVars:"
        di as result "`subpopLabelVars'"
        di as error "These are the requested femaleVars:"
        di as result "`femaleVars'"
        di as error "These are the requested urbanVars:"
        di as result "`urbanVars'"
        di as error "These are the requested benchmarkVars:"
        di as result "`benchmarkVars'"
        di as error "These are the requested sesVars:"
        di as result "`sesVars'"
    }

    local varsOfInterest `" `coreVars' `measureLabelVars' `subpopLabelVars' `femaleVars' `benchmarkVars' `urbanVars' `sesVars' "'

    // This is where we actually define the postfile to hold our results
    postfile `postRes' `varsOfInterest' using `results'

    // Doing the analyses
    // Core analyses
    // Figuring out how many subpopulations we are looping over
    levelsof `subpop_id', loc(subpop_count)
    * if `verbose' ==1 {                  // Helpful for debugging
    *     di "subpop_id variable: `subpop_id'"
    *     di "`subpop_count' subpop_ids"
    *     di "Destination: `target'"
    *     di "Languages: `varlabel'"
    * }
    loc i = 1                       // We want to be able to track our iteration so we can pull in a user-friendly name for the language variable

    // Looping over the performance measures we were given
    foreach v of loc varlist {
        di as error "======||" "||======"
        di as error "======" as result "Analyzing [`v']" as error "======"
        if `label_measures' local curr_var `: word `i' of `varlabel''   // User-friendly name for language variable
        else local curr_var "<none_given>"

        // Getting our survey-weighted Gini coefficient by subpopulation
        pshare `v', over(`subpop_id') gini `svy_suff'
        mat gini = e(G)                             // Saving Gini coefficient matrix so we can iterate over it
        foreach j of num 1/`subpop_count' {             // Iterating through our subpopulations
            di as error "======||" "||======"
            di as error "======" as result "[`v'], subpop [`j']" as error "======"
            if `verbose' di "Current Gini value: " gini[`j',1]

            // The -centile- and -svygei- commands don't give per-subpopulation results w/o dummy variables for being in/out of the subpopulations
            // Looping over the subpopulations and dropping all 'out' observations gets us the same effect
            * di as result "Preserving here!!"
            preserve
            keep if `subpop_id'==`j'
            // Since the sublabel parameter was optional, we need to capture the case where nothing is provided
            if `label_subpops' loc sp_label `: word `j' of `splabel''
            else loc sp_label "<none_given>"

            // To get mean and coefficient of variation
            `apply_svy' mean `v'
            mat results_matrix = r(table)
            loc mean_perf = results_matrix[1,1]
            loc std_err = results_matrix[2,1]
            estat sd
            mat results_matrix = r(sd)
            loc sd = results_matrix[1,1]
            if `svy' {
                estat cv
                mat results_matrix = r(cv)
                loc coeff_var = results_matrix[1,1]
            }
            else {
                loc coeff_var = (`sd'/`mean_perf') * 100
            }

            // To calculate our percentile ratios
            centile `v', centile(10 25 75 90)
            loc p10 `r(c_1)'
            loc p25 `r(c_2)'
            loc p75 `r(c_3)'
            loc p90 `r(c_4)'
            loc ratio_p90p10 `= `p90'/`p10''
            loc ratio_p75p25 `= `p75'/`p25''

            // To get our generalized entropy estimates
            svygei `v'
            loc ge_0 = e(ge0)
            loc ge_1 = e(ge1)
            loc ge_2 = e(ge2)

            // To get our zero-score reporting
            tempvar iszero pct_zero
            gen iszero = 1 if `v'==0
            recode iszero (. = 0)
            * summ iszero
            `apply_svy' mean iszero
            mat results_matrix = r(table)
            loc pct_zero = results_matrix[1,1]

            // Store these core results to be concatenated into the final post after adding in any optional ones
            loc coreResults "("`dataset'") ("`v'") (`j') ("`sp_label'") ("`curr_var'") (gini[`j',1]) (`mean_perf') (`std_err') (`sd') (`coeff_var') (`pct_zero') (`p90') (`p10') (`ratio_p90p10') (`p75') (`p25') (`ratio_p75p25') (`ge_0') (`ge_1') (`ge_2') "
            capture assert `: word count coreVars' == `: word count coreResults'
                if !_rc==0 {
                    di "The program returned a different number of result placeholders and results."
                    di "These were the placeholders: `coreVars'"
                    di "These were the results: `coreResults'"
                    exit 9
                }

            // If analysis by sex was requested
            if `by_fem' {
                di as error "======|| Analysis over sex invoked!||======"
                di as error "======" as result " [`v'], subpop [`j'], var [`female'] " as error "======"

                // For females: obtain estimates of means (w std errors)
                `apply_svy' mean `v' if `female'==1
                mat results_matrix = r(table)
                loc females_mean = results_matrix[1,1]
                loc females_stderr = results_matrix[2,1]
                loc females_pval = results_matrix[4,1]
                loc females_95cilow = results_matrix[5,1]
                loc females_95cihigh = results_matrix[6,1]
                estat sd
                mat results_matrix = r(sd)
                loc females_stddev = results_matrix[1,1]
                if `svy' {
                    estat cv
                    mat results_matrix = r(cv)
                    loc females_cv = results_matrix[1,1]
                }
                else {
                    loc females_cv = (`females_stddev'/`females_mean') * 100
                }
                // Obtain percentage of zero scores for females in the subpopulation
                `apply_svy' mean iszero if `female'==1
                mat results_matrix = r(table)
                loc females_pct_zero = results_matrix[1,1]


                // For males: obtain estimates of means (w std errors)
                `apply_svy' mean `v' if `female'==0
                mat results_matrix = r(table)
                loc males_mean = results_matrix[1,1]
                loc males_stderr = results_matrix[2,1]
                loc males_pval = results_matrix[4,1]
                loc males_95cilow = results_matrix[5,1]
                loc males_95cihigh = results_matrix[6,1]
                estat sd
                mat results_matrix = r(sd)
                loc males_stddev = results_matrix[1,1]
                if `svy' {
                    estat cv
                    mat results_matrix = r(cv)
                    loc males_cv = results_matrix[1,1]
                }
                else {
                    loc males_cv = (`males_stddev'/`males_mean') * 100
                }

                // Obtain percentage of zero scores for females in the subpopulation
                `apply_svy' mean iszero if `female'==0
                mat results_matrix = r(table)
                loc males_pct_zero = results_matrix[1,1]

                loc femaleResults "(`females_mean') (`females_stderr') (`females_pval') (`females_95cilow') (`females_95cihigh') (`females_cv') (`females_stddev') (`females_pct_zero') (`males_mean') (`males_stderr') (`males_pval') (`males_95cilow') (`males_95cihigh') (`males_cv') (`males_stddev') (`males_pct_zero')"
                capture assert `: word count femaleVars' == `: word count femaleResults'
                if !_rc==0 {
                    di "The program returned a different number of result placeholders and results."
                    di "These were the placeholders: `femaleVars'"
                    di "These were the results: `femaleResults'"
                    exit 9
                }
            }
            else loc femaleResults = ""

            // If analysis by benchmark was requested
            if `by_bmark' {
                di as error "======|| Analysis of benchmarks invoked!||======"
                di as error "======" as result " [`v'], subpop [`j'], var(s) [`benchmarks'] " as error "======"

                // There may be multiple levels of benchmarks, so we need to loop over the varlist
                local benchmarkResults = ""
                foreach b of num 1/`benchmark_ct' {
                    // We want the pct of kids at each benchmark
                    loc bmark_currvar `: word `b' of `benchmarks''
                    di as error "======|| ||======"
                    di as error "======" as result "[`v'], subpop [`j'], b [`b'] benchmark [`bmark_currvar'] " as error "======"
                    di as result "Summarizing `bmark_currvar'!!"
                    `apply_svy' mean `bmark_currvar' // Since it's a boolean, mean of the boolean gives us percentage
                    mat results_matrix = r(table)
                    loc `bmark_currvar'_pct = results_matrix[1,1]
                    local benchmarkResults = "`benchmarkResults' (``bmark_currvar'_pct')"
                    if `debug' pause
                }
                capture assert `: word count benchmarkVars' == `: word count benchmarkResults'
                if !_rc==0 {
                    di "The program returned a different number of result placeholders and results."
                    di "These were the placeholders: `benchmarkVars'"
                    di "These were the results: `benchmarkResults'"
                    exit 9
                }
            if `verbose' di as error "BenchmarkResults to write: `benchmarkResults'"
            }
            else loc benchmarkResults = ""

            if `by_urban' {
                di as error "======|| Analysis of urbanity invoked!||======"
                di as error "======" as result " [`v'], subpop [`j'], var [`urbanity'] " as error "======"

                `apply_svy' mean `v' if `urbanity'==1
                mat results_matrix = r(table)
                loc urban_mean = results_matrix[1,1]
                loc urban_stderr = results_matrix[2,1]
                loc urban_pval = results_matrix[4,1]
                loc urban_95cilow = results_matrix[5,1]
                loc urban_95cihigh = results_matrix[6,1]
                estat sd
                mat results_matrix = r(sd)
                loc urban_stddev = results_matrix[1,1]
                if `svy' {
                    estat cv
                    mat results_matrix = r(cv)
                    loc urban_cv = results_matrix[1,1]
                }
                else {
                    loc urban_cv = (`urban_stddev'/`urban_mean') * 100
                }
                // Obtain percentage of zero scores for urbanites in the subpopulation
                `apply_svy' mean iszero if `urbanity'==1
                mat results_matrix = r(table)
                loc urban_pct_zero = results_matrix[1,1]

                // For rural
                `apply_svy' mean `v' if `urbanity'==0
                mat results_matrix = r(table)
                loc rural_mean = results_matrix[1,1]
                loc rural_stderr = results_matrix[2,1]
                loc rural_pval = results_matrix[4,1]
                loc rural_95cilow = results_matrix[5,1]
                loc rural_95cihigh = results_matrix[6,1]
                estat sd
                mat results_matrix = r(sd)
                loc rural_stddev = results_matrix[1,1]
                if `svy' {
                    estat cv
                    mat results_matrix = r(cv)
                    loc rural_cv = results_matrix[1,1]
                }
                else {
                    loc rural_cv = (`rural_stddev'/`rural_mean') * 100
                }

                // Obtain percentage of zero scores for ruralites in the subpopulation
                `apply_svy' mean iszero if `urbanity'==0
                mat results_matrix = r(table)
                loc rural_pct_zero = results_matrix[1,1]

                loc urbanityResults "(`urban_mean') (`urban_stderr') (`urban_pval') (`urban_95cilow') (`urban_95cihigh') (`urban_cv') (`urban_stddev') (`urban_pct_zero') (`rural_mean') (`rural_stderr') (`rural_pval') (`rural_95cilow') (`rural_95cihigh') (`rural_cv') (`rural_stddev') (`rural_pct_zero')"
                capture assert `: word count urbanityVars' == `: word count urbanityResults'
                if !_rc==0 {
                    di "The program returned a different number of result placeholders and results."
                    di "These were the placeholders: `urbanityVars'"
                    di "These were the results: `urbanityResults'"
                    exit 9
                }
            }
            else loc urbanityResults = ""

            if `by_ses' {
                di as error "======|| Analysis by SES invoked!||======"
                di as error "======" as result " [`v'], subpop [`j'], var [`sestatus'] " as error "======"
                local sesResults = ""
                foreach `s' of num 1/`ses_cut_ct' {
                    loc ses_currvar `: word `s' of `sestatus''


                    `apply_svy' mean `v' if `ses_currvar'==1
                    mat results_matrix = r(table)
                    loc ses_currmean = results_matrix[1,1]
                    loc ses_currstderr = results_matrix[2,1]
                    loc ses_currpval = results_matrix[4,1]
                    loc ses_curr95cilow = results_matrix[5,1]
                    loc ses_curr95cihigh = results_matrix[6,1]
                    estat sd
                    mat results_matrix = r(sd)
                    loc ses_currstddev = results_matrix[1,1]
                    if `svy' {
                        estat cv
                        mat results_matrix = r(cv)
                        loc ses_currcv = results_matrix[1,1]
                    }
                    else {
                        loc ses_currcv = (`ses_currstddev'/`ses_currmean') * 100
                    }

                    estat cv
                    mat results_matrix = r(cv)
                    loc ses_currcv = results_matrix[1,1]

                    `apply_svy' mean iszero if `ses_currvar'==1
                    mat results_matrix = r(table)
                    loc ses_currpct_zero = results_matrix[1,1]
                    loc sesResults = "`sesResults' (`ses_currmean') (`ses_currstderr') (`ses_currpval') (`ses_curr95cilow') (`ses_curr95cihigh') (`ses_currcv') (`ses_currstddev') (`ses_currpct_zero')"
                }
                capture assert `: word count sesVars' == `: word count sesResults'
                if !_rc==0 {
                    di "The program returned a different number of result placeholders and results."
                    di "These were the placeholders: `sesVars'"
                    di "These were the results: `sesResults'"
                    exit 9
                }
            }
            else loc sesResults = ""

            // Sending latest data to our postfile
            * local resultRow "("`dataset'") ("`curr_var'") (`j') ("`sp_label'") (gini[`j',1]) (`p90') (`p10') (`ratio_p90p10') (`p75') (`p25') (`ratio_p75p25') (`ge_0') (`ge_1') (`ge_2') (`pct_zero')"
            local resultRow `" `coreResults' `femaleResults' `benchmarkResults' `urbanityResults' `sesResults' "'
            capture post `postRes' `resultRow'
            if !_rc==0 {
                di `"These are the results we attempted to post:"'
                di `"CoreVars: `coreVars'"'
                di `"CoreResults: `coreResults'"'
                di `"femaleVars: `femaleVars'"'
                di `"femaleResults: `femaleResults'"'
                di `"benchmarkVars: `benchmarkVars'"'
                di `"benchmarkResults: `benchmarkResults'"'
                di `"urbanityVars: `urbanityVars'"'
                di `"urbanityResults: `urbanityResults'"'
                di `"sesVars: `sesVars'"'
                di `"sesResults: `sesResults'"'
                exit _rc
            }
            di as result "Restoring here!"
            restore
        }
    loc i `++i'
    }
postclose `postRes'
preserve
use `results', clear
noisily di "Find results in `:pwd' at `target'"
save `target'.dta, replace
restore
end