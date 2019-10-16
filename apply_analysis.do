program define apply_analysis
    * syntax [varlist] [if] , over(varname) langlabel(string) resultsfile(string) [verbose(default=0) detail *]
    syntax [varlist] [if] , DATAset(string) SUBvar(varname) VARlabel(string) RESultsfile(string) [ SPLabel(string) verbose(integer 0)]
    if `verbose' ==1 {                  // Helpful for debugging
        di `"`0'"'
    }
    capture assert `:word count `varlist''==`:word count `varlabel''   // Verify we have the same number of labels as input vars
    if _rc==9 {
        di "{p}You have not provided a variable label{p_end}{p}for each variable you wish to analyze.{p_end}"
        exit 9
    }
    tempfile results            // This is a placeholder for our results
    tempname postRes            // Ensures no namespace clashes
    local target `resultsfile'  // User-supplied: this is where we want the results to be written to file
    // The variables we want for each of our observations (where each obs is a subpopulation)
    local varsOfInterest "str20(dataset language) sub_pop_id str40 sub_pop_label svy_gini p90 p10 ratio_p90p10 p75 p25 ratio_p75p25 ge_0 ge_1 ge_2 float pct_zero"
    levelsof `subvar', loc(subPopCt)    // How many loops we need to do
    if `verbose' ==1 {                  // Helpful for debugging
        di "subvar variable: `subvar'"
        di "`subPopCt' subvars"
        di "Destination: `target'"
        di "Languages: `varlabel'"
    }
    // This is where we actually define the postfile to hold our results
    postfile `postRes' `varsOfInterest' using `results'
    loc i = 1                       // We want to be able to track our iteration so we can pull in a user-friendly name for the language variable
    foreach v of loc varlist {
        local curr_var `: word `i' of `varlabel''   // User-friendly name for language variable
        pshare `v', over(`subvar') `options'        // To calculate our survey-weighted Gini coefficient
        mat gini = e(G)                             // Saving Gini coefficient matrix so we can iterate over it
        foreach j of num 1/`subPopCt' {             // Iterating through our subpopulations
            if `verbose'==1 {
                di "Current Gini value: " gini[`j',1]
            }
            preserve
            // The -centile- and -svygei- commands don't give per-subpopulation results w/o dummy variables for being in/out of the subpopulations
            // Looping over the subpopulations and dropping all 'out' observations gets us the same effect
            keep if `subvar'==`j'
            // Since the sublabel parameter was optional, we need to capture the case where nothing is provided
            if "`splabel'" != "" {
                loc sp_label `: word `j' of `splabel''
                if "`sp_label'" == "" loc sp_label "<none_given>"
            }
            else {
                loc sp_label ""
            }
            * centile `v' if `subvar'==`j', centile(10 25 75 90)
            // To calculate our ratios
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
            tempvar iszero pct_zero
            gen iszero = 1 if `v'==0
            recode iszero (. = 0)
            egen avg_zero = mean(iszero)
            loc pct_zero = avg_zero[1]
            restore
            // Sending latest data to our postfile
            local resultRow "("`dataset'") ("`curr_var'") (`j') ("`sp_label'") (gini[`j',1]) (`p90') (`p10') (`ratio_p90p10') (`p75') (`p25') (`ratio_p75p25') (`ge_0') (`ge_1') (`ge_2') (`pct_zero')"
            post `postRes' `resultRow'
        }
    loc i `++i'
    }
postclose `postRes'
preserve
use `results', clear
di "Find results in `:pwd'"
save `target'.dta, replace
restore
end