set autotabgraphs on
pause on
// Stack our tusome and primr datasets
use "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\primr_core.dta", clear
append using "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\tusome_core.dta"


// we want to separate our demographic variables from our instrumental variables
local demo_vars = "project language reference comparison"
// these are the variables we'll comapre across two time points
local vars_to_compare = "mean cv ratio_p90p10 ratio_p75p25 pct_zero gini ge2_overall between_ge2 within_ge2"

// we'll use a tempfile for our merging process
tempfile time_0 time_1

gen match_id = string(subpop_id, "%02.0f")
local subpops_to_expand "Baseline_Coh1_Control_Gr1 Baseline_Coh1_Control_Gr2 Baseline_Coh2_Control_Gr1 Baseline_Coh2_Control_Gr2 Baseline_Coh3_Control_Gr1 Baseline_Coh3_Control_Gr2 Midline_Coh1_Full_Treatment_Gr1 Midline_Coh1_Full_Treatment_Gr2 Midline_Coh2_Control_Gr1 Midline_Coh2_Control_Gr2 Midline_Coh3_Control_Gr1 Midline_Coh3_Control_Gr2 Endline_Coh1_Full_Treatment_Gr1 Endline_Coh1_Full_Treatment_Gr2 Endline_Coh2_Full_Treatment_Gr1 Endline_Coh2_Full_Treatment_Gr2 Endline_Coh3_Control_Gr1 Endline_Coh3_Control_Gr2"

foreach s of loc subpops_to_expand {
    expand 2 if subpop_label=="`s'"
}

egen match_num = tag(subpop_label measure_label)

gen match_key = ""

replace match_key = "01.07" if dataset=="primr" & ((match_id=="01" & match_num==1) | (match_id=="07" & match_num==0))
replace match_key = "01.13" if dataset=="primr" & ((match_id=="01" & match_num==0) | (match_id=="13" & match_num==1))
replace match_key = "02.08" if dataset=="primr" & ((match_id=="02" & match_num==1) | (match_id=="08" & match_num==0))
replace match_key = "02.14" if dataset=="primr" & ((match_id=="02" & match_num==0) | (match_id=="14" & match_num==1))
replace match_key = "03.09" if dataset=="primr" & ((match_id=="03" & match_num==1) | (match_id=="09" & match_num==0))
replace match_key = "03.15" if dataset=="primr" & ((match_id=="03" & match_num==0) | (match_id=="15" & match_num==1))
replace match_key = "04.10" if dataset=="primr" & ((match_id=="04" & match_num==1) | (match_id=="10" & match_num==0))
replace match_key = "04.16" if dataset=="primr" & ((match_id=="04" & match_num==0) | (match_id=="16" & match_num==1))
replace match_key = "05.11" if dataset=="primr" & ((match_id=="05" & match_num==1) | (match_id=="11" & match_num==0))
replace match_key = "05.17" if dataset=="primr" & ((match_id=="05" & match_num==0) | (match_id=="17" & match_num==1))
replace match_key = "06.12" if dataset=="primr" & ((match_id=="06" & match_num==1) | (match_id=="12" & match_num==0))
replace match_key = "06.18" if dataset=="primr" & ((match_id=="06" & match_num==0) | (match_id=="18" & match_num==1))
replace match_key = "07.13" if dataset=="primr" & ((match_id=="07" & match_num==1) | (match_id=="13" & match_num==0))
replace match_key = "08.14" if dataset=="primr" & ((match_id=="08" & match_num==1) | (match_id=="14" & match_num==0))
replace match_key = "09.15" if dataset=="primr" & ((match_id=="09" & match_num==1) | (match_id=="15" & match_num==0))
replace match_key = "10.16" if dataset=="primr" & ((match_id=="10" & match_num==1) | (match_id=="16" & match_num==0))
replace match_key = "11.17" if dataset=="primr" & ((match_id=="11" & match_num==1) | (match_id=="17" & match_num==0))
replace match_key = "12.18" if dataset=="primr" & ((match_id=="12" & match_num==1) | (match_id=="18" & match_num==0))
replace match_key = "01.03" if dataset=="tusome" & inlist(match_id, "01", "03")
replace match_key = "02.04" if dataset=="tusome" & inlist(match_id, "02", "04")



sort match_id match_num match_key
groups match_key match_id subpop_label match_num

pause "Check that everything's present as expected..."
* tempfile t0_data t1_data both_data

gen is_time0 = .
gen is_time1 = .

recode is_time0 (. = 1) if ustrleft(match_key, 2)==match_id
recode is_time1 (. = 1) if ustrright(match_key, 2)==match_id

preserve
    keep if is_time1 == 1

    foreach stem of loc vars_to_compare {
        ren `stem' `stem'_com
    }
    ren subpop_label subpop_label_com

    groups match_key match_id subpop_label match_num
    pause "Inspect time_1 file..."
    save "`time_1'"
restore

preserve
    keep if is_time0 == 1

    foreach stem of loc vars_to_compare {
        ren `stem' `stem'_ref
    }
        ren subpop_label subpop_label_ref

    groups match_key match_id subpop_label match_num
    pause "Inspect time_0 file..."
    save "`time_0'"
restore


use "`time_0'", clear
merge 1:1 dataset match_key measure_label using "`time_1'", keepusing(*_com)

drop is_time*

local vars_to_compare = "mean cv ratio_p90p10 ratio_p75p25 pct_zero gini ge2_overall between_ge2 within_ge2"

foreach v of loc vars_to_compare {
    gen `v'_diff = `v'_com - `v'_ref
    order `v'_diff, after(`v'_com)
    di as error "------- For variable [`v']: -------"
    groups measure_label match_key subpop_label_ref subpop_label_com `v'_diff
}

foreach v in gini mean cv pct_zero {
    gen `v'_ref_squared = `v'_ref^2
    foreach n of num 15 85 {
        qreg `v'_com `v'_ref `v'_ref_squared, quantile(0.`n')
        matrix `v'_qreg`n' = r(table)
        scalar `v'_qreg_coeff`n'_t0 = `v'_qreg`n'[1,1]
        scalar `v'_qreg_coeff`n'_t0_squared = `v'_qreg`n'[1,2]
        scalar `v'_qreg_coeff`n'_int = `v'_qreg`n'[1,3]

        gen `v'_line_at_`n' = `v'_qreg_coeff`n'_int + (`v'_ref * `v'_qreg_coeff`n'_t0) + (`v'_ref_squared * `v'_qreg_coeff`n'_t0_squared)
    }
}

order *, alphabetic
order dataset match_key subpop_label_ref subpop_label_com grade cohort measure_label

export excel "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\quantile_regressions.xlsx", sh(quantiles) sheetmod first(var)


program define make_qreg_scatters
    syntax , Yvar(var) Xvar(var) EQuality(var) [High(var) Low(var) XRange(string) YRange(string)]

    twoway scatter `Yvar' `Xvar'  || ///
        scatter `EQuality' `Xvar' || ///
               qfit `High' `Xvar' || ///
               qfit `Low' `Xvar',    ///
               xscale(range(`XRange')) ///
               yscale(range(`YRange')) ///
               xlabel(`XRange', nogrid) ///
               ylabel(`YRange', nogrid) ///
               aspect(1)
end



clonevar mean_line_of_equality = mean_ref
clonevar cv_line_of_equality = cv_ref
clonevar pct_zero_line_of_equality = pct_zero_ref
clonevar gini_line_of_equality = gini_ref


loc gini_plot       = `" gini_com gini_ref gini_line_of_equality gini_line_at_85 gini_line_at_15 "0.3(0.1)1" "0.3(0.1)1" "'
loc gini_plot_labels = `" "Gini Coefficient at t_0" "Gini Coefficient at t_1" "'
loc gini_plot_title = `" "Change in Gini coefficient" "over time, with lines of regression" "'
loc gini_plot_legend = `" label(4 "Gini") label(1 "Line of Equality") label(2 "p85 regression") label(3 "p15 regression") "'

loc mean_plot       = `" mean_com mean_ref mean_line_of_equality mean_line_at_85 mean_line_at_15 "0(10)70" "0(10)70" "'
loc mean_plot_labels = `" "Mean ORF (cwpm) at t_0" "Mean ORF (cwpm) at t_1" "'
loc mean_plot_title = `" "Change in Mean ORF (cwpm)" "over time, with lines of regression" "'
loc mean_plot_legend = `" label(4 "Mean ORF") label(1 "Line of Equality") label(2 "p85 regression") label(3 "p15 regression") "'

loc cv_plot         = `" cv_com cv_ref cv_line_of_equality cv_line_at_85 cv_line_at_15 "0(4)20" "0(4)20" "'
loc cv_plot_labels = `" "Coefficient of Variation at t_0" "Coefficient of Variation at t_1" "'
loc cv_plot_title = `" "Change in Coefficient of Variation (%)" "over time, with lines of regression" "'
loc cv_plot_legend = `" label(4 "Coefficient of Variation") label(1 "Line of Equality") label(2 "p85 regression") label(3 "p15 regression") "'

loc pct_zero_plot   = `" pct_zero_com pct_zero_ref pct_zero_line_of_equality pct_zero_line_at_85 pct_zero_line_at_15 "0(.1).70" "0(.1).70" "'
loc pct_zero_plot_labels = `" "Percentage of Zero Scores at t_0" "Percentage of Zero Scores at t_1" "'
loc pct_zero_plot_title = `" "Change in Percentage of Zero Scores (%)" "over time, with lines of regression" "'
loc pct_zero_plot_legend = `" label(4 "Pct Zero Scores") label(1 "Line of Equality") label(2 "p85 regression") label(3 "p15 regression") "'

loc plotlist "gini_plot mean_plot cv_plot pct_zero_plot"

foreach p of loc plotlist {
    loc yvar: word 1 of ``p''
    loc xvar: word 2 of ``p''
    loc eqlin: word 3 of ``p''
    loc trend_upper: word 4 of ``p''
    loc trend_lower: word 5 of ``p''
    loc yrange: word 6 of ``p''
    loc xrange: word 7 of ``p''
    loc xaxis_title: word 1 of ``p'_labels'
    loc yaxis_title: word 2 of ``p'_labels'
    * loc legend: ```p'_legend''
    * loc plot_title:  word 3 of ``p'_labels'

twoway ///
    line `eqlin' `xvar'      , msymbol(o) lcolor(gs12) lpattern(solid) lwidth(vthin)  ||    ///
    qfit `trend_upper' `xvar', lpattern(shortdash) lcolor(gs0) || ///
    qfit `trend_lower' `xvar', lpattern(shortdash) lcolor(gs0) || ///
    scatter `yvar' `xvar' , msymbol(o) mcolor(cranberry) msize(small)    ///
    yscale(range(`yrange') titlegap(4))      ///
    xscale(range(`xrange') titlegap(2))      ///
    ylabel(`yrange', nogrid) ytitle(`yaxis_title', margin(medium))    ///
    xlabel(`xrange', nogrid) xtitle(`xaxis_title', margin(medium))    ///
     ///
    legend(``p'_legend' span) ///
    aspect(1) name(`p', replace) title(``p'_title') ///
    graphregion(margin(l+5 r+5)) ///
    plotregion(margin(l+5 r+5)) ///
    xsize(5) ysize(5)
    graph save "qreg_`p'_stata.gph"
    graph export "qreg_`p'_stata.svg" ,name(`p')
    graph export "qreg_`p'_stata.png" ,name(`p')
}

**** Graphs with fitted lines

loc gini_plot       = `" gini_com gini_ref gini_line_of_equality gini_line_at_85 gini_line_at_15 "0.3(0.1)1" "0.3(0.1)1" "'   
loc gini_plot_labels = `" "Gini Coefficient at t_0" "Gini Coefficient at t_1" "'
loc gini_plot_title = `" "Change in Gini coefficient" "over time" "'
loc gini_plot_legend = `" label(3 "Gini") label(1 "Line of Equality") label(2 "fitted line") "'

loc mean_plot       = `" mean_com mean_ref mean_line_of_equality mean_line_at_85 mean_line_at_15 "0(10)70" "0(10)70" "'
loc mean_plot_labels = `" "Mean ORF (cwpm) at t_0" "Mean ORF (cwpm) at t_1" "'
loc mean_plot_title = `" "Change in Mean ORF (cwpm)" "over time" "'
loc mean_plot_legend = `" label(3 "Mean ORF") label(1 "Line of Equality") label(2 "fitted line") "'

loc cv_plot         = `" cv_com cv_ref cv_line_of_equality cv_line_at_85 cv_line_at_15 "0(4)20" "0(4)20" "'
loc cv_plot_labels = `" "Coefficient of Variation at t_0" "Coefficient of Variation at t_1" "'
loc cv_plot_title = `" "Change in Coefficient of Variation (%)" "over time" "'
loc cv_plot_legend = `" label(3 "Coefficient of Variation") label(1 "Line of Equality") label(2 "fitted line") "'

loc pct_zero_plot   = `" pct_zero_com pct_zero_ref pct_zero_line_of_equality pct_zero_line_at_85 pct_zero_line_at_15 "0(.1).70" "0(.1).70" "'
loc pct_zero_plot_labels = `" "Percentage of Zero Scores at t_0" "Percentage of Zero Scores at t_1" "'
loc pct_zero_plot_title = `" "Change in Percentage of Zero Scores (%)" "over time" "'
loc pct_zero_plot_legend = `" label(3 "Pct Zero Scores") label(1 "Line of Equality") label(2 "fitted line") "'

loc plotlist "gini_plot mean_plot cv_plot pct_zero_plot"  

foreach p of loc plotlist {
    loc yvar: word 1 of ``p''
    loc xvar: word 2 of ``p''
    loc eqlin: word 3 of ``p''
    loc trend_lower: word 5 of ``p''
    loc yrange: word 6 of ``p''
    loc xrange: word 7 of ``p''
	loc xline: word 6 of ``p''
	loc yline: word 6 of ``p''
    loc xaxis_title: word 1 of ``p'_labels'
    loc yaxis_title: word 2 of ``p'_labels'
    
twoway ///
    line `eqlin' `xvar', msymbol(o) lcolor(gs12) lpattern(solid) lwidth(vthin)  ||    ///
    lfit `yvar' `xvar', lpattern(shortdash) lcolor(gs0) || ///
    scatter `yvar' `xvar' , msymbol(o) mcolor(cranberry) msize(small)    ///
    yscale(range(`yrange') titlegap(4))      ///
    xscale(range(`xrange') titlegap(2))      ///
    ylabel(`yline', nogrid) ytitle(`yaxis_title', margin(medium))    ///
    xlabel(`xline', nogrid) xtitle(`xaxis_title', margin(medium))    ///
     ///
    legend(``p'_legend' span) ///
    aspect(1) name(`p', replace) title(``p'_title') ///
    graphregion(margin(l+5 r+5)) ///
    plotregion(margin(l+5 r+5)) ///
    xsize(5) ysize(5)
    graph save "bins/CS20-mt-S03-V01-qreg_`p'_stata_lfit.gph", replace
    graph export "bins/CS20-mt-S03-V01-qreg_`p'_stata_lfit.svg" ,name(`p') replace
    graph export "bins/CS20-mt-S03-V01-qreg_`p'_stata_lfit.png" ,name(`p') replace

}
 
**** Quantile regression using differences
 
 gen mean_diff_squared = mean_diff^2
    foreach n of num 15 85 {
        qreg gini_diff mean_diff mean_diff_squared, quantile(0.`n')
        matrix diff_qreg`n' = r(table)
        scalar diff_qreg_coeff`n' = diff_qreg`n'[1,1]
        scalar diff_qreg_coeff`n'_squared = diff_qreg`n'[1,2]
        scalar diff_qreg_coeff`n'_int = diff_qreg`n'[1,3]

        gen diff_line_at_`n' = diff_qreg_coeff`n'_int + (mean_diff * diff_qreg_coeff`n') + (mean_diff_squared * diff_qreg_coeff`n'_squared)
    }

twoway scatter gini_diff mean_diff , msymbol(o) mcolor(cranberry) msize(small) legend(label(3 "p15 regression line") label(1 Change in Gini Coefficient) label(2 "fitted line") label(4 "p85 regression line")) || lfit gini_diff mean_diff, lpattern(solid) lcolor(gs0) || lfit diff_line_at_15 mean_diff,lpattern(shortdash) lcolor(gs0) || lfit diff_line_at_85 mean_diff,lpattern(longdash) lcolor(gs0) ///
       ///
       yscale(range(-0.4(0.1)0.1) titlegap(4))  ylabel(-0.4(0.1)0.1, nogrid) ytitle(Change in Gini Index, margin(medium))  ///
	   xscale(range(0(5)35) titlegap(2))  xlabel(0(5)35, nogrid) xtitle( Change in mean ORF, margin(medium))  ||
	   graph save "bins/CS20-mt-S03-V01-qreg_diff_lfit.gph", replace
       graph export "bins/CS20-mt-S03-V01-qreg_diff_lfit.svg" ,replace
       graph export "bins/CS20-mt-S03-V01-qreg_diff_lfit.png" , replace
