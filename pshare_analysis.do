program drop _all

program define apply_pshare
    * syntax [varlist] [if] , over(varname) langlabel(string) resultsfile(string) [verbose(default=0) detail *]
    syntax [varlist] [if] , Over(varname) LANGlabel(string) RESultsfile(string) [verbose(integer 0) detail *]
    capture assert `:word count `varlist''==`:word count `langlabel''
    if _rc==9 {
        di "{p}You have not provided a language label{p_end}{p}for each variable you wish to analyze.{p_end}"
        exit 9
    }
    tempfile results
    tempname postRes
    local target `resultsfile'
    local varsOfInterest "str20 language subPop svy_gini"
    levelsof `over', loc(subPopCt)
    if `verbose' ==1 {
        di "Over: `over'"
        di "`subPopCt' subpopulations"
        di "Destination: `target'"
        di "Languages: `langlabel'"
    }
    postfile `postRes' `varsOfInterest' using `results'
    loc i = 1
    foreach v of loc varlist {
        local langName `: word `i' of `langlabel''
        pshare `v', over(`over') `options'
        mat gini = e(G)
        foreach j of num 1/`subPopCt' {
            if `verbose'==1 {
                di "Current Gini value: " gini[`j',1]
            }
            loc currGini gini[`j', 1]
            local resultRow "("`langName'") (`j') (gini[`j',1])"
            post `postRes' `resultRow'
        }
    loc i `++i'
    }
postclose `postRes'
preserve
use `results', clear
di "Find results in"
pwd
save `target'.dta, replace
restore
end