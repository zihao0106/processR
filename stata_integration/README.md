# processR-Stata Integration Guide

## Overview

This guide shows how to use the extended processR package (with panel data capabilities) from within Stata. There are several methods available, each with different advantages.

## Method 1: Direct R Bridge (Recommended)

### Requirements
- R installed with processR package from your GitHub repository
- Stata 14.0 or later

### Installation Steps

1. **Install processR in R:**
```r
# Install from your GitHub repository
devtools::install_github("zihao0106/processR")

# Load required packages
library(processR)
library(plm)
library(haven)  # for reading Stata files
```

2. **Copy the integration files to your Stata working directory:**
   - `processR_stata_bridge.R`
   - `processR_stata.ado`

3. **In Stata, install the program:**
```stata
* Add the program to your adopath or run it directly
run processR_stata.ado
```

### Usage Examples

#### Basic Panel Mediation Analysis
```stata
* Example with the Grunfeld dataset
* Assuming you have variables: inv (X), efficiency (M), value (Y), firm (ID), year (TIME)

processR_panel inv efficiency value, id(firm) time(year) model(within)
```

#### Multiple Mediators
```stata
* With multiple mediators
processR_panel inv efficiency innovation value, id(firm) time(year) model(random)
```

#### Model Comparison
```stata
* Compare different panel models
processR_compare inv efficiency value, id(firm) time(year) models(pooling,within,random)
```

## Method 2: File-Based Exchange

### Step 1: Export Data from Stata
```stata
* Export your data to CSV
export delimited using "panel_data.csv", replace
```

### Step 2: Run Analysis in R
```r
# Load your data
data <- read.csv("panel_data.csv")

# Run panel mediation analysis
result <- multipleMediation(
  X = "inv",
  M = "efficiency", 
  Y = "value",
  data = data,
  panel = TRUE,
  id = "firm",
  time = "year",
  panel_model = "within"
)

# Export results
write.csv(data.frame(
  effect_type = c(rep("indirect", length(result$indirect_effects)),
                  rep("direct", length(result$direct_effects)),
                  rep("total", length(result$total_effects))),
  variable = c(names(result$indirect_effects),
               names(result$direct_effects), 
               names(result$total_effects)),
  coefficient = c(unlist(result$indirect_effects),
                  unlist(result$direct_effects),
                  unlist(result$total_effects))
), "processR_results.csv", row.names = FALSE)
```

### Step 3: Import Results to Stata
```stata
* Import results
import delimited "processR_results.csv", clear
list
```

## Method 3: Using Stata's rcall Package

If you have the `rcall` package installed:

```stata
* Install rcall if not already installed
* ssc install rcall

* Set up R environment
rcall: library(processR); library(plm)

* Define your data in Stata and pass to R
rcall: ///
data <- st.data(); ///
result <- multipleMediation( ///
  X = "inv", M = "efficiency", Y = "value", ///
  data = data, panel = TRUE, ///
  id = "firm", time = "year", ///
  panel_model = "within" ///
); ///
cat("Indirect effects:", result$indirect_effects$indirect_efficiency)
```

## Method 4: Command Line Interface

### Create a batch processing script:

```stata
* Export data
export delimited using "temp_data.csv", replace

* Call R script via shell command
shell Rscript stata_integration/processR_stata_bridge.R "temp_data.csv" "inv" "efficiency" "value" "firm" "year" "within" "results"

* Import results
import delimited "results_indirect.csv", clear
list
```

## Advanced Features

### Dynamic Panel Models
```stata
* For dynamic panel models with lags
processR_panel inv efficiency value, id(firm) time(year) model(within) lag(1)
```

### Custom Output Locations
```stata
* Specify output file location
processR_panel inv efficiency value, id(firm) time(year) output(my_results) replace
```

### Error Handling
The integration includes robust error handling for:
- Missing variables
- Invalid panel structure
- R package installation issues
- File I/O problems

## Advantages of Each Method

| Method | Pros | Cons |
|--------|------|------|
| Direct R Bridge | Seamless integration, automatic | Requires R setup |
| File Exchange | Simple, no dependencies | Manual process |
| rcall | Native Stata integration | Requires rcall package |
| Command Line | Flexible, scriptable | More complex setup |

## Troubleshooting

### Common Issues:

1. **R not found:** Ensure R is in your system PATH
2. **Package not installed:** Run `devtools::install_github("zihao0106/processR")` in R
3. **File path issues:** Use full paths for file locations
4. **Memory issues:** For large datasets, consider using file exchange method

### Performance Tips:

1. Use `robust_se = FALSE` for faster computation in comparisons
2. For very large panels, consider subsampling for initial exploration
3. Cache results using the `replace` option to avoid recomputation

## Example Workflow

Here's a complete example workflow:

```stata
* 1. Load your panel dataset
use panel_data.dta, clear

* 2. Check panel structure
xtset firm year

* 3. Run processR analysis
processR_panel investment efficiency firm_value, ///
    id(firm) time(year) model(within) output(mediation_results)

* 4. Compare models
processR_compare investment efficiency firm_value, ///
    id(firm) time(year) models(pooling,within,random)

* 5. View results
import delimited "mediation_results_indirect.csv", clear
list
```

This integration allows you to leverage the advanced panel data mediation capabilities of processR while working within your familiar Stata environment.
