# Stata-R Bridge for processR Panel Data Analysis
# This R script provides a bridge between Stata and processR for panel data analysis

# Function to perform panel mediation analysis from Stata
stata_panel_mediation <- function(data_file, x_var, m_vars, y_var, id_var, time_var, 
                                 panel_model = "within", robust_se = TRUE, 
                                 output_file = "panel_results.csv") {
  
  # Load required libraries
  library(processR)
  library(plm)
  
  # Read data from Stata
  if (tools::file_ext(data_file) == "dta") {
    library(haven)
    data <- read_dta(data_file)
  } else if (tools::file_ext(data_file) == "csv") {
    data <- read.csv(data_file)
  } else {
    stop("Unsupported data format. Please use .dta or .csv files.")
  }
  
  # Convert character vectors to character (for multiple mediators)
  if (length(m_vars) == 1 && grepl(",", m_vars)) {
    m_vars <- trimws(strsplit(m_vars, ",")[[1]])
  }
  
  # Perform panel mediation analysis
  result <- multipleMediation(
    X = x_var,
    M = m_vars,
    Y = y_var,
    data = data,
    panel = TRUE,
    id = id_var,
    time = time_var,
    panel_model = panel_model,
    robust_se = robust_se
  )
  
  # Extract results for Stata
  indirect_effects <- data.frame(
    mediator = names(result$indirect_effects),
    indirect_effect = unlist(result$indirect_effects),
    stringsAsFactors = FALSE
  )
  
  direct_effects <- data.frame(
    variable = names(result$direct_effects),
    direct_effect = unlist(result$direct_effects),
    stringsAsFactors = FALSE
  )
  
  total_effects <- data.frame(
    variable = names(result$total_effects),
    total_effect = unlist(result$total_effects),
    stringsAsFactors = FALSE
  )
  
  # Combine results
  results_summary <- list(
    indirect = indirect_effects,
    direct = direct_effects,
    total = total_effects,
    model_info = result$panel_info
  )
  
  # Save results to CSV for Stata to read
  write.csv(indirect_effects, 
            paste0(tools::file_path_sans_ext(output_file), "_indirect.csv"), 
            row.names = FALSE)
  write.csv(direct_effects, 
            paste0(tools::file_path_sans_ext(output_file), "_direct.csv"), 
            row.names = FALSE)
  write.csv(total_effects, 
            paste0(tools::file_path_sans_ext(output_file), "_total.csv"), 
            row.names = FALSE)
  
  # Print summary to console (visible in Stata)
  cat("Panel Data Mediation Analysis Results\n")
  cat("====================================\n\n")
  
  cat("Panel Model:", result$panel_info$model, "\n")
  cat("Number of individuals:", result$panel_info$n_individuals, "\n")
  cat("Number of time periods:", result$panel_info$n_time_periods, "\n")
  cat("Total observations:", result$panel_info$n_obs, "\n\n")
  
  cat("Indirect Effects:\n")
  print(indirect_effects)
  cat("\nDirect Effects:\n")
  print(direct_effects)
  cat("\nTotal Effects:\n")
  print(total_effects)
  
  return(results_summary)
}

# Function for model comparison
stata_panel_comparison <- function(data_file, x_var, m_vars, y_var, id_var, time_var,
                                  models = c("pooling", "within", "random"),
                                  output_file = "comparison_results.csv") {
  
  library(processR)
  library(plm)
  
  # Read data
  if (tools::file_ext(data_file) == "dta") {
    library(haven)
    data <- read_dta(data_file)
  } else {
    data <- read.csv(data_file)
  }
  
  # Parse multiple mediators
  if (length(m_vars) == 1 && grepl(",", m_vars)) {
    m_vars <- trimws(strsplit(m_vars, ",")[[1]])
  }
  
  comparison_results <- data.frame(
    model = character(),
    mediator = character(),
    indirect_effect = numeric(),
    stringsAsFactors = FALSE
  )
  
  for (model in models) {
    tryCatch({
      result <- multipleMediation(
        X = x_var, M = m_vars, Y = y_var,
        data = data, panel = TRUE,
        id = id_var, time = time_var,
        panel_model = model, robust_se = FALSE
      )
      
      for (i in seq_along(result$indirect_effects)) {
        comparison_results <- rbind(comparison_results, data.frame(
          model = model,
          mediator = names(result$indirect_effects)[i],
          indirect_effect = result$indirect_effects[[i]],
          stringsAsFactors = FALSE
        ))
      }
    }, error = function(e) {
      cat("Error with model", model, ":", e$message, "\n")
    })
  }
  
  # Save comparison results
  write.csv(comparison_results, output_file, row.names = FALSE)
  
  cat("Model Comparison Results:\n")
  print(comparison_results)
  
  return(comparison_results)
}

# Wrapper function that can be called from Stata command line
# Usage: Rscript processR_stata_bridge.R data.csv x_var "m1,m2" y_var id_var time_var
if (length(commandArgs(trailingOnly = TRUE)) > 0) {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) >= 6) {
    data_file <- args[1]
    x_var <- args[2]
    m_vars <- args[3]
    y_var <- args[4]
    id_var <- args[5]
    time_var <- args[6]
    
    # Optional arguments
    panel_model <- ifelse(length(args) >= 7, args[7], "within")
    output_file <- ifelse(length(args) >= 8, args[8], "stata_results.csv")
    
    # Run analysis
    result <- stata_panel_mediation(data_file, x_var, m_vars, y_var, 
                                   id_var, time_var, panel_model, 
                                   TRUE, output_file)
  } else {
    cat("Usage: Rscript processR_stata_bridge.R data_file x_var m_vars y_var id_var time_var [panel_model] [output_file]\n")
  }
}
