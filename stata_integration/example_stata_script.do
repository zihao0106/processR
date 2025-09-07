* Example Stata script demonstrating processR panel data analysis
* Author: processR Extension Team
* Date: 2025-09-07

clear all
set more off

* Set working directory (adjust as needed)
cd "/Users/adamhu/processR"

* Install the processR Stata integration
capture run stata_integration/processR_stata.ado

* Example 1: Create sample panel data for demonstration
clear
set obs 200

* Create firm and year identifiers
gen firm = ceil(_n/20)
bysort firm: gen year = 1935 + _n - 1

* Create panel structure
xtset firm year

* Generate example variables similar to Grunfeld dataset
set seed 12345
gen inv = 50 + 10*uniform() + firm*2 + (year-1940)*0.5 + 20*rnormal()
gen capital = 100 + 5*uniform() + firm*5 + (year-1940)*1.2 + 30*rnormal()

* Create mediator variable (efficiency)
gen efficiency = 0.3*inv + 0.2*capital + 15*rnormal()

* Create outcome variable (firm value)
gen value = 0.4*inv + 0.6*efficiency + 0.1*capital + 50*rnormal()

* Add a second mediator for multiple mediation example
gen innovation = 0.2*inv + 0.15*capital + 12*rnormal()
replace value = value + 0.3*innovation

* Save sample data
save sample_panel_data.dta, replace

* Example 2: Basic panel mediation analysis
display "=== Example 1: Basic Panel Mediation Analysis ==="
processR_panel inv efficiency value, id(firm) time(year) model(within) output(basic_results)

* Example 3: Multiple mediators
display ""
display "=== Example 2: Multiple Mediators Analysis ==="
processR_panel inv efficiency innovation value, id(firm) time(year) model(random) output(multiple_results)

* Example 4: Model comparison
display ""
display "=== Example 3: Panel Model Comparison ==="
processR_compare inv efficiency value, id(firm) time(year) models(pooling,within,random) output(comparison_results)

* Example 5: Different panel models
display ""
display "=== Example 4: Between Estimator ==="
processR_panel inv efficiency value, id(firm) time(year) model(between) output(between_results)

* Example 6: Load and examine results
display ""
display "=== Example 5: Examining Results in Stata ==="

* Load indirect effects
capture {
    preserve
    import delimited "basic_results_indirect.csv", clear
    display "Indirect Effects from Basic Analysis:"
    list
    restore
}

* Load direct effects  
capture {
    preserve
    import delimited "basic_results_direct.csv", clear
    display "Direct Effects from Basic Analysis:"
    list
    restore
}

* Load model comparison results
capture {
    preserve
    import delimited "comparison_results.csv", clear
    display "Model Comparison Results:"
    list
    
    * Create a simple plot if possible
    if _N > 0 {
        encode model, gen(model_num)
        scatter indirect_effect model_num, ///
            xlabel(1 "Pooling" 2 "Within" 3 "Random") ///
            title("Indirect Effects by Panel Model") ///
            ytitle("Indirect Effect Size") xtitle("Panel Model")
        graph export model_comparison.png, replace
        display "Graph saved as model_comparison.png"
    }
    restore
}

* Example 7: Working with real data (if available)
display ""
display "=== Example 6: Tips for Your Own Data ==="
display "To use processR with your own panel data:"
display "1. Ensure your data is properly xtset"
display "2. Check for missing values in key variables" 
display "3. Use processR_panel varlist, id(idvar) time(timevar)"
display "4. Compare different panel models using processR_compare"
display "5. Examine results files: *_indirect.csv, *_direct.csv, *_total.csv"

* Clean up temporary files (optional)
display ""
display "Analysis completed! Check the CSV files for detailed results."
display "Files created:"
display "- basic_results_*.csv (basic mediation)"
display "- multiple_results_*.csv (multiple mediators)"  
display "- between_results_*.csv (between estimator)"
display "- comparison_results.csv (model comparison)"

* Note about file locations
display ""
display "Note: All result files are saved in the current working directory:"
display "`c(pwd)'"
