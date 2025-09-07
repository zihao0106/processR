* Stata program to call processR panel data analysis
* Author: processR Extension Team
* Date: 2025-09-07

* Program: processR_panel
* Description: Stata wrapper for processR panel data mediation analysis

capture program drop processR_panel
program define processR_panel
    version 14.0
    syntax varlist(min=3) [if] [in], ID(varname) TIME(varname) ///
        [MODEL(string) OUTput(string) REPlace]
    
    * Parse variable list
    local nvars : word count `varlist'
    if `nvars' < 3 {
        display as error "At least 3 variables required: X M Y"
        exit 198
    }
    
    * Extract X, Y, and mediators
    local x_var : word 1 of `varlist'
    local y_var : word `nvars' of `varlist'
    
    * Mediators are the variables in between
    local m_vars ""
    forvalues i = 2/`=`nvars'-1' {
        local m_var : word `i' of `varlist'
        if "`m_vars'" == "" {
            local m_vars "`m_var'"
        }
        else {
            local m_vars "`m_vars',`m_var'"
        }
    }
    
    * Set defaults
    if "`model'" == "" local model "within"
    if "`output'" == "" local output "processR_results"
    
    * Mark sample
    marksample touse
    
    * Check for required variables
    capture confirm variable `id'
    if _rc {
        display as error "ID variable `id' not found"
        exit 111
    }
    
    capture confirm variable `time'
    if _rc {
        display as error "TIME variable `time' not found"
        exit 111
    }
    
    * Export data to temporary file
    tempfile datafile
    export delimited `varlist' `id' `time' if `touse' using "`datafile'", replace
    
    * Prepare R script path
    local r_script_path "`c(pwd)'/stata_integration/processR_stata_bridge.R"
    
    * Check if R script exists
    capture confirm file "`r_script_path'"
    if _rc {
        display as error "R bridge script not found at: `r_script_path'"
        display as error "Please ensure processR_stata_bridge.R is in the stata_integration folder"
        exit 601
    }
    
    * Call R script
    display "Running processR panel data analysis..."
    display "X variable: `x_var'"
    display "Mediator(s): `m_vars'"
    display "Y variable: `y_var'"
    display "ID variable: `id'"
    display "Time variable: `time'"
    display "Panel model: `model'"
    display ""
    
    * Execute R script
    local cmd `"Rscript "`r_script_path'" "`datafile'" "`x_var'" "`m_vars'" "`y_var'" "`id'" "`time'" "`model'" "`output'""'
    shell `cmd'
    
    * Import results back to Stata
    capture confirm file "`output'_indirect.csv"
    if !_rc {
        display ""
        display "Importing indirect effects..."
        preserve
        import delimited "`output'_indirect.csv", clear
        list
        if "`replace'" != "" {
            save "`output'_indirect.dta", replace
        }
        restore
    }
    
    capture confirm file "`output'_direct.csv"
    if !_rc {
        display ""
        display "Importing direct effects..."
        preserve
        import delimited "`output'_direct.csv", clear
        list
        if "`replace'" != "" {
            save "`output'_direct.dta", replace
        }
        restore
    }
    
    capture confirm file "`output'_total.csv"
    if !_rc {
        display ""
        display "Importing total effects..."
        preserve
        import delimited "`output'_total.csv", clear
        list
        if "`replace'" != "" {
            save "`output'_total.dta", replace
        }
        restore
    }
    
    display ""
    display "processR panel analysis completed!"
    display "Results saved to: `output'_*.csv"
    if "`replace'" != "" {
        display "Stata datasets saved to: `output'_*.dta"
    }
end

* Program: processR_compare
* Description: Compare different panel models

capture program drop processR_compare
program define processR_compare
    version 14.0
    syntax varlist(min=3) [if] [in], ID(varname) TIME(varname) ///
        [MODels(string) OUTput(string)]
    
    * Set defaults
    if "`models'" == "" local models "pooling,within,random"
    if "`output'" == "" local output "model_comparison"
    
    * Parse variable list (same as above)
    local nvars : word count `varlist'
    local x_var : word 1 of `varlist'
    local y_var : word `nvars' of `varlist'
    
    local m_vars ""
    forvalues i = 2/`=`nvars'-1' {
        local m_var : word `i' of `varlist'
        if "`m_vars'" == "" {
            local m_vars "`m_var'"
        }
        else {
            local m_vars "`m_vars',`m_var'"
        }
    }
    
    * Mark sample
    marksample touse
    
    * Export data
    tempfile datafile
    export delimited `varlist' `id' `time' if `touse' using "`datafile'", replace
    
    * Call R comparison function
    display "Comparing panel models: `models'"
    
    * Create R script for comparison
    tempfile r_compare_script
    file open rfile using "`r_compare_script'", write replace
    file write rfile "source('stata_integration/processR_stata_bridge.R')" _n
    file write rfile `"stata_panel_comparison("`datafile'", "`x_var'", "`m_vars'", "`y_var'", "`id'", "`time'", c("' _n
    
    * Parse models
    local model_list = subinstr("`models'", ",", `"", ""', .)
    file write rfile `""`model_list'"), "`output'.csv")"' _n
    file close rfile
    
    shell Rscript "`r_compare_script'"
    
    * Import comparison results
    capture confirm file "`output'.csv"
    if !_rc {
        preserve
        import delimited "`output'.csv", clear
        list
        restore
        display "Model comparison completed! Results in `output'.csv"
    }
    else {
        display as error "Model comparison failed or no results generated"
    }
end
