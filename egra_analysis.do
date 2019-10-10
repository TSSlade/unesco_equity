/*
Script to conduct basic analyses of an EGRA dataset
for the purposes of the Crouch et al study on equity measures
*/

pause on                    // To enable inspection of our code mid-execution
set autotabgraphs on        // Otherwise the EDA graphs open too many windows and get annoying
global data_source="data/PUF_KenyaTusome_Stu_BaseMid_170311.dta" // Replace with the path to your dataset
use $data_source

/*
RTI's PUF (public-use file) versions of EGRA/EGMA datasets come with survey weights already
defined. Please be sure to run any commands which will generate estimates using the
prefix `svy: `. They also contain some basic notes that may be helpful in getting oriented
to the data.

There is no guarantee that EGRA/EGMA datasets generated by other institutions will have
similar resources in place.
*/

/*
Required packages:
    epctile (-findit epctile-, then click to install)
    pshare (-findit pshare-, then click to install)
        For ref: https://www.stata.com/meeting/germany15/abstracts/materials/de15_jann.pdf
*/

// Getting oriented
notes                   // Display notes regarding the generation of composite variables
svyset                  // Display notes regarding how the survey weights have been applied

/*
Variables of interest
    oral reading fluency
        e_orf_a         Oral Reading Fluency in English () N.B.: this is the one used for the EGRA Barometer
        e_orf_b         Oral Reading Fluency in English ()
        k_orf           Oral Reading Fluency in Kiswahili
        grade           Pupil's grade (1, 2)
        female          Pupil's sex (1 = girl, 0 = boy)
        treat_phase     Round of data collection (1 = 'Baseline', 2 = midline)
 */

// Use of subpop([conditions]) preserves correct standard errors if the condition is not splitting on one of the sampling strata
// Use logit when working with svyset (ratio comparison option) or svytab
// Cross-sectional: 90th pctile vs. 10th pctile
// Learning gains unassociated with SSES: means gaps are not being closed
// Absolute performance (as achievement, not gain) is associated with SSES, though...


// Exploring the data

capture graph drop *
levelsof grade, local(grades)                                 // To loop over arbitrary # of grades
levelsof treat_phase, local(rounds)                           // To loop over arbitrary # of rounds
local colorlist "ltblue cranberry sand navy maroon dkorange"  // Setting up colors for grade histograms

// Histograms of oral reading fluency
//      by grade, phase, and language
foreach lang of var e_orf_a k_orf {
    local histlist " "                          // Initialize macro to store graph names
    summarize `lang'
    local text_y `=0.8*`r(max)''                // Getting max value for label placement
    foreach r of loc rounds {
        foreach g of loc grades {
            local barcolor = word("`colorlist'", `g')       // Accessing the nth color from our list
            hist `lang' if grade==`g' & treat_phase==`r', width(5) bcolor("`barcolor'") name("`lang'_gr`g'_phase`r'") text( 0.07 `text_y' "`lang' Gr `g' Rd `r'")
            graph export "imgs/histogram_`lang'_gr`g'_phase`r'.svg", name(`lang'_gr`g'_phase`r') replace
            local histlist "`histlist' `lang'_gr`g'_phase`r'"
        }
    }
    di "Histograms for `lang': `histlist'"
    graph combine `histlist', ycommon xcommon name("histograms_combined_`lang'", replace)   // Generating single overview graph
    graph export "imgs/histograms_baseline_midline_`lang'.svg", name("histograms_combined_`lang'") replace
    graph close `histlist'
}

// Scatterplots of oral reading fluency
//      by the same child
//      across languages
//      by grade and phase
summarize e_orf_a
local text_y `=0.8 * `r(max)''                // Getting max value for label placement
summarize k_orf
local text_x `=0.8 * `r(max)''                // Getting max value for label placement
local scatterlist " "                          // Initialize macro to store graph names
foreach r of loc rounds {
    foreach g of loc grades {
        local dotcolor = word("`colorlist'", `g')       // Accessing the nth color from our list
        scatter e_orf_a k_orf if grade==`g' & treat_phase==`r', mcolor("`dotcolor'"%50) mlwidth(none) msize(vsmall) name(scatter_gr`g'_phase`r', replace) text( `text_x' `text_y' "`lang' Gr `g' Rd `r'")
        graph export "imgs/scatter_gr`g'_phase`r'.svg", replace
        local scatterlist "`scatterlist' scatter_gr`g'_phase`r'"
    }
}
di "Scatterplots: `scatterlist'"
graph combine `scatterlist', ycommon xcommon name("scatterplots_combined", replace)     // Generating single overview graph
graph export "imgs/scatterplots_baseline_midline.svg", name("scatterplots_combined") replace
graph close `scatterlist'

// Comparing percentiles
* epctile e_orf_a, percentiles(10 90) over(grade treat_phase) speclabel svy
* epctile k_orf, percentiles(10 90) over(grade treat_phase) speclabel svy

levelsof grade, local(grades)                                 // To loop over arbitrary # of grades
levelsof treat_phase, local(rounds)                           // To loop over arbitrary # of rounds
local percentiles_of_interest "10 25 34 67 75 90"
local percentile_count: word count `percentiles_of_interest'
local lang_vars "e_orf_a k_orf"
local languages "eng kis"
local language_count: word count `languages'

// Generating the list of percentiles we care about (just as scalars)
//

local named_scalars " "
foreach i of num 1/`language_count' {
    local lang_var = word("`lang_vars'", `i')
    local language = word("`languages'", `i')
    foreach g of loc grades {
        foreach r of loc rounds {
            _pctile `lang_var' if grade==`g' & treat_phase==`r', percentiles(`percentiles_of_interest')
            foreach p of num 1/`percentile_count' {
                local poi = word("`percentiles_of_interest'", `p')
                local current_scalar = "`language'_g`g'_r`r'_p`poi'"
                scalar define `current_scalar' = `r(r`p')'
                local named_scalars "`named_scalars' `current_scalar'"
            }
        }
    }
}

// Several of our lower percentiles were zero scores. This means we cannot calculate, e.g.
// the ratio of p90:p10 because it will throw a division-by-zero error. Here we add a minute
// non-zero element as a workaround
local epsilon = 1e-10
di "`named_scalars'"
foreach ns of loc named_scalars {
    if `ns'==0 {
        scalar define `ns' = `=`ns'' + `epsilon'
        di "`ns' now `=`ns''"
    }
}

local ratio90_10 "90 10"
local ratio75_25 "75 25"
local ratio67_34 "67 34"
local comparisons "ratio90_10 ratio75_25 ratio67_34"
foreach c of loc comparisons {
    loc bigger = word("``c''", 1)
    loc smaller = word("``c''", 2)
    foreach i of num 1/2 {
        di "Kiswahili `bigger':`smaller' " kis_g2_r2_p`bigger' / kis_g2_r2_p`smaller'
        di "English `bigger':`smaller' " eng_g2_r2_p`bigger' / eng_g2_r2_p`smaller'
    }
}

local lang_vars "e_orf_a k_orf"
local languages "eng kis"
local language_count: word count `languages'
levelsof grade, local(grades)                                 // To loop over arbitrary # of grades
levelsof treat_phase, local(rounds)                           // To loop over arbitrary # of rounds

foreach i of num 1/`language_count' {
    local lang_var = word("`lang_vars'", `i')
    local language = word("`languages'", `i')
    foreach r of loc rounds {
        foreach g of loc grades {
            pshare `lang_var', gini svy(if treat_phase==`r' & grade==`g')
            pshare histogram, name(pshare_`language'_g`g'_r`r', replace)
            matrix gini = e(G)
            scalar gini_`language'_g`g'_r`r'=gini[rownumb(gini,"`lang_var'"),colnumb(gini,"Gini")]
            graph export "imgs/pshare_`language'_g`g'_r`r'.svg", replace
        }
    }
}
scalar list

/*
Useful links for reference:
https://en.wikipedia.org/wiki/Gini_coefficient
https://www.statalist.org/forums/forum/general-stata-discussion/general/1450130-how-to-retrieve-extract-scalars-from-a-matrix-based-on-their-row-names-and-column-names
https://www.statalist.org/forums/forum/general-stata-discussion/general/1362382-extract-coefficients-from-e-b-after-regress
*/