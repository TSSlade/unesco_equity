use "$primr_src", clear
svyset

// Start defining subpopulations we'll need
egen sub_population = group(treat_phase cohort treatment grade)
levelsof(sub_population), loc(sub_pop_ids)              // Store sub_population IDs for later use
local n_sub_pops: word count `sub_pop_ids'              // Need the ct for loops

label define lbl_sub_population 1 "Baseline Coh1 Control Gr 1"  2 "Baseline Coh1 Control Gr 2" 3 "Baseline Coh2 Control Gr 1"  4 "Baseline Coh2 Control Gr 2" 5 "Baseline Coh3 Control Gr 1"  6 "Baseline Coh3 Control Gr 2" 7 "Midline Coh1 Treatment Gr 1" 8 "Midline Coh1 Treatment Gr 2" 9 "Midline Coh2 Control Gr 1"   10 "Midline Coh2 Control Gr 2" 11 "Midline Coh3 Control Gr 1"  12 "Midline Coh3 Control Gr 2" 13 "Endline Coh1 Treatment Gr 1" 14 "Endline Coh1 Treatment Gr 2" 15 "Endline Coh2 Treatment Gr 1" 16 "Endline Coh2 Treatment Gr 2" 17 "Endline Coh3 Control Gr 1" 18 "Endline Coh3 Control Gr 2" , replace      // Let's make some labels

groups sub_population treat_phase cohort treatment grade, missing
label val sub_population lbl_sub_population             // ...and apply them
local subpop_names `" "Baseline Coh1 Control Gr 1" "Baseline Coh1 Control Gr 2" "Baseline Coh2 Control Gr 1" "Baseline Coh2 Control Gr 2" "Baseline Coh3 Control Gr 1"  "Baseline Coh3 Control Gr 2" "Midline Coh1 Treatment Gr 1" "Midline Coh1 Treatment Gr 2" "Midline Coh2 Control Gr 1" "Midline Coh2 Control Gr 2" "Midline Coh3 Control Gr 1" "Midline Coh3 Control Gr 2" "Endline Coh1 Treatment Gr 1" "Endline Coh1 Treatment Gr 2" "Endline Coh2 Treatment Gr 1" "Endline Coh2 Treatment Gr 2" "Endline Coh3 Control Gr 1" "Endline Coh3 Control Gr 2" "'

local cluster_levels "school student"
local n_cluster_levels: word count `cluster_levels'
local clustered_lang_vars "schl_eng_orf schl_kis_orf"
local clustered_zero_vars "schl_zero_pct_eng schl_zero_pct_kis"

// Sanity check
groups grade treat_phase sub_population
pause       // Just to make you think about it...

// Start defining elements of our other loops
local lang_vars "eq_orf k_eq_orf"                         // Variable names for our ORF
local n_lang_vars : word count `lang_vars'              // Need a counter to convert varnames into human names
local lang_names "eng kis"                              // Define the human names
assert `n_lang_vars'==`:word count `lang_names''        // Make sure these list lengths match
local zero_vars "eng_zero kis_zero"                     // Variable names for our zero-score dummies

// Let's generate some school-clustered performance measures
foreach i of num 1/`n_lang_vars' {                      // Looping over our languages
    local lang_name `: word `i' of `lang_names''
    local lang_var `: word `i' of `lang_vars''
    egen schl_`lang_name'_orf = mean(`lang_var'), by(school_code sub_population)               // School-level ORF by language
    gen `lang_name'_zero = 1 if `lang_var'==0                                                  // Zero-score dummy for each child
    recode `lang_name'_zero (. = 0)                                                             // Making non-zeros non-missing for the dummy var
    egen schl_zero_pct_`lang_name' = mean(`lang_name'_zero), by(school_code sub_population)     // School-level pct of zeros by lang
}
