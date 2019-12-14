pause on
// Stack our tusome and primr datasets
use "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\primr_core.dta", clear
append using "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\tusome_core.dta"


// we want to separate our demographic variables from our instrumental variables
local demo_vars = "project language reference comparison"
// these are the variables we'll comapre across two time points
local vars_to_compare = "mean cv ratio_p90p10 ratio_p75p25 pct_zero gini ge2_overall ge2_ingroup ge2_outgroup between_ge2 within_ge2"

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