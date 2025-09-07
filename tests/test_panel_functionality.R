# Test Panel Data Functionality for processR
# 
# This script tests the panel data extensions to processR

# Load required libraries
if (!require(processR)) {
  message("processR package needs to be loaded")
}

if (!require(plm)) {
  install.packages("plm")
  library(plm)
}

# Test 1: Panel data detection
test_panel_detection <- function() {
  cat("Testing panel data detection...\n")
  
  # Load test data
  data(Grunfeld, package = "plm")
  
  # Test with proper panel data
  result1 <- is_panel_data(Grunfeld, id = "firm", time = "year")
  cat("Grunfeld dataset panel detection:", result1, "\n")
  
  # Test with cross-sectional data
  cross_section <- Grunfeld[Grunfeld$year == 1935, ]
  result2 <- is_panel_data(cross_section, id = "firm", time = "year")
  cat("Cross-sectional data panel detection:", result2, "\n")
  
  # Test with missing id/time
  result3 <- is_panel_data(Grunfeld, id = NULL, time = "year")
  cat("Missing ID panel detection:", result3, "\n")
  
  return(list(panel_data = result1, cross_section = result2, missing_id = result3))
}

# Test 2: Panel data preparation
test_panel_preparation <- function() {
  cat("\nTesting panel data preparation...\n")
  
  data(Grunfeld, package = "plm")
  
  # Prepare panel data
  panel_data <- prepare_panel_data(Grunfeld, id = "firm", time = "year")
  
  cat("Original data dimensions:", dim(Grunfeld), "\n")
  cat("Panel data dimensions:", dim(panel_data), "\n")
  cat("Panel data class:", class(panel_data), "\n")
  
  return(panel_data)
}

# Test 3: Basic panel mediation analysis
test_basic_panel_mediation <- function() {
  cat("\nTesting basic panel mediation analysis...\n")
  
  data(Grunfeld, package = "plm")
  
  # Add synthetic mediator variable
  set.seed(123)
  Grunfeld$efficiency <- 0.3 * Grunfeld$inv + 0.2 * Grunfeld$capital + rnorm(nrow(Grunfeld), 0, 50)
  
  # Test panel mediation
  tryCatch({
    panel_result <- panel_multipleMediation(
      X = "inv",
      M = "efficiency", 
      Y = "value",
      id = "firm",
      time = "year",
      data = Grunfeld,
      model = "within",
      robust = TRUE
    )
    
    cat("Panel mediation analysis completed successfully\n")
    cat("Indirect effect:", panel_result$indirect_effects$indirect_efficiency, "\n")
    cat("Direct effect:", panel_result$direct_effects$direct_inv, "\n")
    
    return(panel_result)
    
  }, error = function(e) {
    cat("Error in panel mediation analysis:", e$message, "\n")
    return(NULL)
  })
}

# Test 4: Integration with multipleMediation function
test_integration <- function() {
  cat("\nTesting integration with multipleMediation...\n")
  
  data(Grunfeld, package = "plm")
  
  # Add synthetic mediator
  set.seed(123)
  Grunfeld$efficiency <- 0.3 * Grunfeld$inv + 0.2 * Grunfeld$capital + rnorm(nrow(Grunfeld), 0, 50)
  
  # Test auto-detection
  tryCatch({
    result_auto <- multipleMediation(
      X = "inv",
      M = "efficiency",
      Y = "value", 
      data = Grunfeld,
      id = "firm",
      time = "year"  # Should auto-detect panel structure
    )
    
    cat("Auto-detection integration successful\n")
    return(result_auto)
    
  }, error = function(e) {
    cat("Error in integration test:", e$message, "\n")
    return(NULL)
  })
}

# Test 5: Multiple mediators
test_multiple_mediators <- function() {
  cat("\nTesting multiple mediators in panel data...\n")
  
  data(Grunfeld, package = "plm")
  
  # Add multiple synthetic mediators
  set.seed(123)
  Grunfeld$efficiency <- 0.3 * Grunfeld$inv + 0.2 * Grunfeld$capital + rnorm(nrow(Grunfeld), 0, 50)
  Grunfeld$innovation <- 0.2 * Grunfeld$inv + 0.1 * Grunfeld$capital + rnorm(nrow(Grunfeld), 0, 30)
  
  tryCatch({
    result_multiple <- panel_multipleMediation(
      X = "inv",
      M = c("efficiency", "innovation"),
      Y = "value",
      id = "firm", 
      time = "year",
      data = Grunfeld,
      model = "within"
    )
    
    cat("Multiple mediators analysis completed\n")
    cat("Number of mediators:", length(result_multiple$indirect_effects), "\n")
    
    return(result_multiple)
    
  }, error = function(e) {
    cat("Error in multiple mediators test:", e$message, "\n")
    return(NULL)
  })
}

# Run all tests
run_all_tests <- function() {
  cat("=== processR Panel Data Extension Tests ===\n")
  
  results <- list()
  
  # Run tests
  results$detection <- test_panel_detection()
  results$preparation <- test_panel_preparation()
  results$basic_mediation <- test_basic_panel_mediation()
  results$integration <- test_integration()
  results$multiple_mediators <- test_multiple_mediators()
  
  cat("\n=== Test Summary ===\n")
  cat("Panel detection test:", !is.null(results$detection), "\n")
  cat("Panel preparation test:", !is.null(results$preparation), "\n") 
  cat("Basic mediation test:", !is.null(results$basic_mediation), "\n")
  cat("Integration test:", !is.null(results$integration), "\n")
  cat("Multiple mediators test:", !is.null(results$multiple_mediators), "\n")
  
  return(results)
}

# Example usage:
# test_results <- run_all_tests()

# Check available panel models
check_panel_models <- function() {
  cat("\n=== Available Panel Models ===\n")
  cat("- within: Fixed effects model\n")
  cat("- random: Random effects model\n") 
  cat("- pooling: Pooled OLS model\n")
  cat("- between: Between estimator\n")
  
  cat("\n=== Panel Effect Types ===\n")
  cat("- individual: Individual fixed/random effects\n")
  cat("- time: Time fixed/random effects\n")
  cat("- twoways: Both individual and time effects\n")
}

# Performance comparison
compare_panel_models <- function() {
  cat("\n=== Panel Model Comparison ===\n")
  
  data(Grunfeld, package = "plm")
  set.seed(123)
  Grunfeld$efficiency <- 0.3 * Grunfeld$inv + 0.2 * Grunfeld$capital + rnorm(nrow(Grunfeld), 0, 50)
  
  models <- c("pooling", "within", "random", "between")
  results <- list()
  
  for (model in models) {
    tryCatch({
      start_time <- Sys.time()
      
      result <- panel_multipleMediation(
        X = "inv", M = "efficiency", Y = "value",
        id = "firm", time = "year", data = Grunfeld,
        model = model, robust = FALSE  # Disable robust SE for speed
      )
      
      end_time <- Sys.time()
      
      results[[model]] <- list(
        indirect_effect = result$indirect_effects$indirect_efficiency,
        computation_time = as.numeric(end_time - start_time, units = "secs")
      )
      
      cat(sprintf("Model %s: Indirect effect = %.4f, Time = %.3f seconds\n", 
                  model, result$indirect_effects$indirect_efficiency,
                  as.numeric(end_time - start_time, units = "secs")))
      
    }, error = function(e) {
      cat("Error with model", model, ":", e$message, "\n")
    })
  }
  
  return(results)
}

# Uncomment to run tests:
# run_all_tests()
# check_panel_models()
# compare_panel_models()
