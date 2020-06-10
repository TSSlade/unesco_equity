use "$tusome_src", clear
svyset

// Start defining subpopulations we'll need
egen sub_population = group(treat_phase grade)
levelsof(sub_population), loc(sub_pop_ids)              // Store sub_population IDs for later use
local n_sub_pops: word count `sub_pop_ids'              // Need the ct for loops

label define lbl_sub_population 1 "Gr 1 Baseline" 2 "Gr 2 Baseline" 3 "Gr 1 Midline" 4 "Gr 2 Midline", replace      // Let's make some labels
label val sub_population lbl_sub_population             // ...and apply them
local subpop_names `" "Gr 1 Baseline" "Gr 2 Baseline" "Gr 1 Midline" "Gr 2 Midline" "'

local cluster_levels "school student"
local n_cluster_levels: word count `cluster_levels'
local clustered_lang_vars "schl_eng_orf schl_kis_orf"
local clustered_zero_vars "schl_zero_pct_eng schl_zero_pct_kis"

// Sanity check
groups grade treat_phase sub_population
* pause       // Just to make you think about it...

// Start defining elements of our other loops
local lang_vars "e_orf_a k_orf"                         // Variable names for our ORF
local n_lang_vars `: word count `lang_vars''              // Need a counter to convert varnames into human names
local lang_names "eng kis"                              // Define the human names
assert `n_lang_vars'==`:word count `lang_names''        // Make sure these list lengths match
local zero_vars "eng_zero kis_zero"                     // Variable names for our zero-score dummies

// Let's generate some school-clustered performance measures
* set trace on
* di "Starting!!"
di "Number of lang_vars: `n_lang_vars'"
* foreach i of num 1/`n_lang_vars' {                      // Looping over our languages
local target = `n_lang_vars'
local k = 0
while `k' < `target' {                      // Looping over our languages
    di "Made it here!!"
    local lang_name `: word `k' of `lang_names''
    local lang_var `: word `k' of `lang_vars''
    egen schl_`lang_name'_orf = mean(`lang_var'), by(school_code sub_population)               // School-level ORF by language
    gen `lang_name'_zero = 1 if `lang_var'==0                                                  // Zero-score dummy for each child
    recode `lang_name'_zero (. = 0)                                                             // Making non-zeros non-missing for the dummy var
    egen schl_zero_pct_`lang_name' = mean(`lang_name'_zero), by(school_code sub_population)     // School-level pct of zeros by lang
    local k `++k'
}
* set trace off
di "Sub_pop ct: `n_sub_pops' in tusome_config"
scalar n_sub_pops = `n_sub_pops'