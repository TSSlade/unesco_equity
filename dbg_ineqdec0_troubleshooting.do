capture program drop show_ge2
capture drop ingroup outgroup
program define show_ge2
syntax [varname] , Over(varname) [Idlist(string)]

* di "`0'"
qui levelsof `over', loc(ovs)

qui ineqdec0 `varlist', bygroup(`over')

loc overall_ge2 r(ge2)
loc between_ge2 r(between_ge2)
loc within_ge2 r(within_ge2)

foreach ov of loc ovs {
    scalar ge2_fromby_`ov' = r(ge2_`ov')
}

tempvar ingroup outgroup
gen ingroup = 0
gen outgroup = 0

foreach ov of loc ovs {
    qui recode ingroup (0 = 1) if `over'==`ov'
    qui ineqdec0 `varlist', bygroup(ingroup)
    loc overall_ge2_`ov' = r(ge2)
    loc between_ge2_`ov' = r(between_ge2)
    loc within_ge2_`ov' = r(within_ge2)
    loc ge2_ingroup_`ov' = r(ge2_1)
    loc ge2_outgroup_`ov' = r(ge2_0)
    qui replace ingroup = 0
}

di as error "Output for " as command " ineqdec0 `varlist', bygroup(`over')"
di as error "{hline 60}"
di as error "Value" /*
        */  _col(10) as error "{c | } ge(2) " /*
        */  _col(20) as error "{c | } between " /*
        */  _col(30) as error "{c | } within " /*
        */  _col(40) as error "{c | } sum(check) " /*
        */  _col(55) as error "{c | } for -in- " /*
        */  _col(67) as error "{c | } for -out- " /*
        */  _col(80) as error "{c | } subpopulation"
di as error "{hline 60}"
* di as error "Stored value" _col{18} as error " {c | } " as error " via -over- " _col(25) as error " {c | } "
di    _col(10) as error "{c | } " as result %4.3f `overall_ge2' /*
    */_col(20) as error "{c | } " as result %4.3f `between_ge2' /*
    */_col(30) as error "{c | } " as result %4.3f `within_ge2' /*
    */_col(40) as error "{c | } " as result %4.3f `between_ge2' + `within_ge2' /*
    */_col(55) as error "{c | } " as text "{c - }" /*
    */_col(67) as error "{c | } " as text "{c - }" /*
    */_col(80) as error "{c | } " as text "Overall, from -bygroup- " /**/
di as error "{hline 60}"
foreach ov of loc ovs {
di as result "ge2_`ov'" /*
    */as error _col(10) "{c | } " as text %4.3f ge2_fromby_`ov' /*
    */_col(20) as error "{c | } " as text %4.3f `between_ge2_`ov'' /*
    */_col(30) as error "{c | } " as text %4.3f `within_ge2_`ov'' /*
    */_col(40) as error "{c | } " as text %4.3f `between_ge2_`ov'' + `within_ge2_`ov'' /*
    */_col(55) as error "{c | } " as text %4.3f `ge2_ingroup_`ov'' /*
    */_col(67) as error "{c | } " as text %4.3f `ge2_outgroup_`ov'' /*
    */_col(80) as error "{c | } " as text "`: label (`over') `ov''"
}

drop ingroup outgroup

end

capture program drop nested_ge2
capture drop ingroup outgroup
program define nested_ge2
syntax [varname] , PARent(varname) CHIld(varname) [Idlist(string)]

* di "`0'"
qui levelsof `parent', loc(parents)
qui levelsof `child', loc(children)

qui ineqdec0 `varlist', bygroup(`parent')


// Parent Loop
loc overall_ge2 r(ge2)
loc between_ge2 r(between_ge2)
loc within_ge2 r(within_ge2)

foreach par of loc parents {
    scalar ge2_fromby_`par' = r(ge2_`par')
}

tempvar ingroup outgroup
gen ingroup = 0
gen outgroup = 0

foreach par of loc parents {
    qui recode ingroup (0 = 1) if `parent'==`par'
    qui ineqdec0 `varlist', bygroup(ingroup)
    loc overall_ge2_`par' = r(ge2)
    loc between_ge2_`par' = r(between_ge2)
    loc within_ge2_`par' = r(within_ge2)
    loc ge2_ingroup_`par' = r(ge2_1)
    loc ge2_outgroup_`par' = r(ge2_0)
    qui replace ingroup = 0
}

di ""
di ""
di as error "Output for " as command " ineqdec0 `varlist', bygroup(`parent')"
di as error "{hline 60}"
di as error "Value" /*
        */  _col(10) as error "{c | } ge(2) " /*
        */  _col(20) as error "{c | } from 'by()' " /*
        */  _col(35) as error "{c | } between " /*
        */  _col(45) as error "{c | } within " /*
        */  _col(60) as error "{c | } sum(check) " /*
        */  _col(72) as error "{c | } for -in- " /*
        */  _col(85) as error "{c | } for -out- " /*
        */  _col(95) as error "{c | } subpopulation"
di as error "{hline 60}"
* di as error "Stored value" _col{18} as error " {c | } " as error " via -over- " _col(25) as error " {c | } "
di    _col(10) as error "{c | } " as result %4.3f `overall_ge2' /*
    */_col(20) as error "{c | } " as result %4.3f "" /*
    */_col(35) as error "{c | } " as result %4.3f `between_ge2' /*
    */_col(45) as error "{c | } " as result %4.3f `within_ge2' /*
    */_col(60) as error "{c | } " as result %4.3f `between_ge2' + `within_ge2' /*
    */_col(72) as error "{c | } " as text "{c - }" /*
    */_col(85) as error "{c | } " as text "{c - }" /*
    */_col(95) as error "{c | } " as text "Overall, from -bygroup- " /**/
di as error "{hline 60}"
foreach par of loc parents {
di as result "ge2_`par'" /*
//    as error _col(10) "{c | } " as text %4.3f ge2_fromby_`par'
    */as error _col(10) "{c | } " as text %4.3f `overall_ge2_`par'' /*
    */_col(20) as error "{c | } " as text %4.3f ge2_fromby_`par' /*
    */_col(35) as error "{c | } " as text %4.3f `between_ge2_`par'' /*
    */_col(45) as error "{c | } " as text %4.3f `within_ge2_`par'' /*
    */_col(60) as error "{c | } " as text %4.3f `between_ge2_`par'' + `within_ge2_`par'' /*
    */_col(72) as error "{c | } " as text %4.3f `ge2_ingroup_`par'' /*
    */_col(85) as error "{c | } " as text %4.3f `ge2_outgroup_`par'' /*
    */_col(95) as error "{c | } " as text "`: label (`parent') `par''"
}


// Child Loop

foreach par of loc parents {
    preserve
    keep if `parent'==`par'

    qui ineqdec0 `varlist', bygroup(`child')

    loc overall_ge2 r(ge2)
    loc between_ge2 r(between_ge2)
    loc within_ge2 r(within_ge2)

    foreach chi of loc children {
        scalar ge2_fromby_`chi' = r(ge2_`chi')
    }

    * tempvar ingroup outgroup
    * gen ingroup = 0
    * gen outgroup = 0

    foreach chi of loc children {
        qui recode ingroup (0 = 1) if `child'==`chi'
        qui ineqdec0 `varlist', bygroup(ingroup)
        loc overall_ge2_`chi' = r(ge2)
        loc between_ge2_`chi' = r(between_ge2)
        loc within_ge2_`chi' = r(within_ge2)
        loc ge2_ingroup_`chi' = r(ge2_1)
        loc ge2_outgroup_`chi' = r(ge2_0)
        qui replace ingroup = 0
    }

    di ""
    di ""
    di as error "Output for " as command " ineqdec0 `varlist', bygroup(`child')" as error " where `parent'==`par'"
    di as error "{hline 60}"
    di as error "Value" /*
            */  _col(10) as error "{c | } ge(2) " /*
            */  _col(20) as error "{c | } from 'by()' " /*
            */  _col(35) as error "{c | } between " /*
            */  _col(45) as error "{c | } within " /*
            */  _col(60) as error "{c | } sum(check) " /*
            */  _col(72) as error "{c | } for -in- " /*
            */  _col(85) as error "{c | } for -out- " /*
            */  _col(95) as error "{c | } subpopulation"
    di as error "{hline 60}"
    * di as error "Stored value" _col{18} as error " {c | } " as error " via -over- " _col(25) as error " {c | } "
    di    _col(10) as error "{c | } " as result %4.3f `overall_ge2' /*
        */_col(20) as error "{c | } " as result %4.3f "" /*
        */_col(35) as error "{c | } " as result %4.3f `between_ge2' /*
        */_col(45) as error "{c | } " as result %4.3f `within_ge2' /*
        */_col(60) as error "{c | } " as result %4.3f `between_ge2' + `within_ge2' /*
        */_col(72) as error "{c | } " as text "{c - }" /*
        */_col(85) as error "{c | } " as text "{c - }" /*
        */_col(95) as error "{c | } " as text "Overall, from -bygroup- " /**/
    di as error "{hline 60}"
    foreach chi of loc children {
    di as result "ge2_`chi'" /*
        */as error _col(10) "{c | } " as text %4.3f `overall_ge2_`par'' /*
        */_col(20) as error "{c | } " as text %4.3f ge2_fromby_`chi' /*
        */_col(35) as error "{c | } " as text %4.3f `between_ge2_`chi'' /*
        */_col(45) as error "{c | } " as text %4.3f `within_ge2_`chi'' /*
        */_col(60) as error "{c | } " as text %4.3f `between_ge2_`chi'' + `within_ge2_`chi'' /*
        */_col(72) as error "{c | } " as text %4.3f `ge2_ingroup_`chi'' /*
        */_col(85) as error "{c | } " as text %4.3f `ge2_outgroup_`chi'' /*
        */_col(95) as error "{c | } " as text "`: label (`child') `chi''"
    }

    restore
}

drop ingroup outgroup

end


* foreach round of loc round {
* preserve
* keep if treat_phase==`round'
* ineqdec0 eng_orf, bygroup(coh_x_grade)
* restore
* }

* Stored value      | via -bygroup-  | via -ingroup-  | for -outgroup- | subpopulation



/*

We have...
    + Treatment phases (baseline, midline, endline)
    + Cohorts (coh1, coh2, coh3)
    + Grades (1, 2)

Conceptually, we need to be thinking of
    baseline, midline, endline as distinct populations
    and also
    grades as distinct populations

However, if we keep cohorts 

Tusome
parent: treat_phase_x_grade --> e.g.,  Baseline_Gr1
child:  treat_phase_x_grade_x_school --> e.g., Baseline_Gr1_123456

PRIMR
parent: treat_phase_x_cohort_x_grade --> e.g., Baseline_Coh1_Gr1
parent: treat_phase_x_cohort_x_grade_x_school --> e.g., Baseline_Coh1_Gr1



*/
