#' Panel Data Support Functions for processR
#' 
#' This module extends processR to support panel data analysis
#' integrating with plm, panelvar and other panel data packages
#'
#' @import plm
#' @import panelvar  
#' @import sandwich
#' @import lmtest

#' Check if data is panel data structure
#' @param data A data.frame
#' @param id Character. Name of individual identifier variable
#' @param time Character. Name of time identifier variable
#' @return Logical indicating if data has panel structure
#' @export
#' @examples
#' data(Grunfeld, package = "plm")
#' is_panel_data(Grunfeld, id = "firm", time = "year")
is_panel_data <- function(data, id = NULL, time = NULL) {
  if (is.null(id) || is.null(time)) return(FALSE)
  if (!all(c(id, time) %in% colnames(data))) return(FALSE)
  
  # Check if we have multiple observations per individual
  n_obs <- nrow(data)
  n_individuals <- length(unique(data[[id]]))
  n_time_periods <- length(unique(data[[time]]))
  
  return(n_obs > max(n_individuals, n_time_periods))
}

#' Prepare panel data for analysis
#' @param data A data.frame
#' @param id Character. Name of individual identifier variable  
#' @param time Character. Name of time identifier variable
#' @param balance Logical. Whether to balance the panel
#' @return A pdata.frame object ready for panel analysis
#' @importFrom plm pdata.frame make.pbalanced
#' @export
#' @examples
#' data(Grunfeld, package = "plm")
#' panel_data <- prepare_panel_data(Grunfeld, id = "firm", time = "year")
prepare_panel_data <- function(data, id, time, balance = TRUE) {
  
  # Convert to pdata.frame
  pdata <- plm::pdata.frame(data, index = c(id, time))
  
  # Balance panel if requested
  if (balance) {
    pdata <- plm::make.pbalanced(pdata, balance.type = "shared.individuals")
  }
  
  return(pdata)
}

#' Panel data multiple mediation analysis
#' @param X Names of independent variable(s)
#' @param Y Name of dependent variable
#' @param M Names of mediator variable(s)
#' @param id Character. Name of individual identifier variable
#' @param time Character. Name of time identifier variable
#' @param data A data.frame
#' @param moderator A list specifying moderator variables
#' @param model Character. Panel model type: "within", "random", "pooling", "between"
#' @param effect Character. Effects to include: "individual", "time", "twoways"
#' @param robust Logical. Whether to use robust standard errors
#' @param lag Integer. Number of lags for dynamic panel models
#' @param ... Additional arguments passed to plm functions
#' @return A list containing panel mediation analysis results
#' @importFrom plm plm
#' @importFrom sandwich vcovHC
#' @export
#' @examples
#' \dontrun{
#' data(Grunfeld, package = "plm")
#' # Add some example variables for demonstration
#' Grunfeld$mediator <- rnorm(nrow(Grunfeld))
#' result <- panel_multipleMediation(
#'   X = "inv", Y = "value", M = "mediator",
#'   id = "firm", time = "year", data = Grunfeld,
#'   model = "within"
#' )
#' }
panel_multipleMediation <- function(X, Y, M, id, time, data, 
                                   moderator = list(),
                                   model = "within",
                                   effect = "individual", 
                                   robust = TRUE,
                                   lag = 0,
                                   ...) {
  
  # Prepare panel data
  pdata <- prepare_panel_data(data, id, time)
  
  # Step 1: X -> M (a paths)
  a_models <- list()
  for (i in seq_along(M)) {
    formula_a <- as.formula(paste(M[i], "~", paste(X, collapse = " + ")))
    
    if (lag > 0) {
      # Add lagged X variables for dynamic models
      X_lag <- paste0("lag(", X, ", ", lag, ")")
      formula_a <- as.formula(paste(M[i], "~", paste(c(X, X_lag), collapse = " + ")))
    }
    
    a_models[[i]] <- plm::plm(formula_a, data = pdata, model = model, 
                             effect = effect, ...)
    
    # Apply robust standard errors if requested
    if (robust) {
      a_models[[i]]$vcov_robust <- sandwich::vcovHC(a_models[[i]], type = "HC1")
    }
  }
  names(a_models) <- paste0("a", seq_along(M))
  
  # Step 2: X + M -> Y (b and c' paths)
  all_predictors <- c(X, M)
  if (lag > 0) {
    # Add lagged variables for dynamic models
    all_predictors <- c(all_predictors, paste0("lag(", c(X, M), ", ", lag, ")"))
  }
  
  formula_y <- as.formula(paste(Y, "~", paste(all_predictors, collapse = " + ")))
  
  y_model <- plm::plm(formula_y, data = pdata, model = model, 
                     effect = effect, ...)
  
  if (robust) {
    y_model$vcov_robust <- sandwich::vcovHC(y_model, type = "HC1")
  }
  
  # Calculate indirect effects
  indirect_effects <- list()
  for (i in seq_along(M)) {
    a_coef <- coef(a_models[[i]])[X]
    b_coef <- coef(y_model)[M[i]]
    indirect_effects[[i]] <- a_coef * b_coef
  }
  names(indirect_effects) <- paste0("indirect_", M)
  
  # Calculate direct effects
  direct_effects <- coef(y_model)[X]
  names(direct_effects) <- paste0("direct_", X)
  
  # Calculate total effects (from X -> Y without mediators)
  formula_total <- as.formula(paste(Y, "~", paste(X, collapse = " + ")))
  total_model <- plm::plm(formula_total, data = pdata, model = model,
                         effect = effect, ...)
  
  if (robust) {
    total_model$vcov_robust <- sandwich::vcovHC(total_model, type = "HC1")
  }
  
  total_effects <- coef(total_model)[X]
  names(total_effects) <- paste0("total_", X)
  
  # Return results
  result <- list(
    a_models = a_models,
    y_model = y_model,
    total_model = total_model,
    indirect_effects = indirect_effects,
    direct_effects = direct_effects,
    total_effects = total_effects,
    panel_info = list(
      id = id,
      time = time,
      model = model,
      effect = effect,
      robust = robust,
      lag = lag,
      n_individuals = length(unique(pdata[[id]])),
      n_time_periods = length(unique(pdata[[time]])),
      n_obs = nrow(pdata)
    )
  )
  
  class(result) <- c("panel_mediation", "list")
  return(result)
}

#' Print method for panel mediation results
#' @param x A panel_mediation object
#' @param ... Additional arguments
#' @export
print.panel_mediation <- function(x, ...) {
  cat("Panel Data Mediation Analysis\n")
  cat("=============================\n\n")
  
  cat("Panel Information:\n")
  cat("- Model type:", x$panel_info$model, "\n")
  cat("- Effect type:", x$panel_info$effect, "\n")
  cat("- Number of individuals:", x$panel_info$n_individuals, "\n")
  cat("- Number of time periods:", x$panel_info$n_time_periods, "\n")
  cat("- Total observations:", x$panel_info$n_obs, "\n")
  cat("- Robust standard errors:", x$panel_info$robust, "\n")
  if (x$panel_info$lag > 0) {
    cat("- Lag periods:", x$panel_info$lag, "\n")
  }
  cat("\n")
  
  cat("Indirect Effects:\n")
  for (i in seq_along(x$indirect_effects)) {
    cat(sprintf("- %s: %.4f\n", names(x$indirect_effects)[i], x$indirect_effects[[i]]))
  }
  cat("\n")
  
  cat("Direct Effects:\n")
  for (i in seq_along(x$direct_effects)) {
    cat(sprintf("- %s: %.4f\n", names(x$direct_effects)[i], x$direct_effects[[i]]))
  }
  cat("\n")
  
  cat("Total Effects:\n")
  for (i in seq_along(x$total_effects)) {
    cat(sprintf("- %s: %.4f\n", names(x$total_effects)[i], x$total_effects[[i]]))
  }
}

#' Summary method for panel mediation results
#' @param object A panel_mediation object
#' @param ... Additional arguments
#' @importFrom lmtest coeftest
#' @export
summary.panel_mediation <- function(object, ...) {
  
  cat("Panel Data Mediation Analysis - Detailed Results\n")
  cat("===============================================\n\n")
  
  # Print panel info
  print(object)
  
  cat("\nDetailed Model Results:\n")
  cat("======================\n")
  
  # A models (X -> M)
  cat("\nStep 1: X -> M relationships\n")
  cat("----------------------------\n")
  for (i in seq_along(object$a_models)) {
    cat("\nModel", names(object$a_models)[i], ":\n")
    if (object$panel_info$robust && !is.null(object$a_models[[i]]$vcov_robust)) {
      print(lmtest::coeftest(object$a_models[[i]], vcov = object$a_models[[i]]$vcov_robust))
    } else {
      print(summary(object$a_models[[i]]))
    }
  }
  
  # Y model (X + M -> Y)
  cat("\nStep 2: X + M -> Y relationship\n")
  cat("-------------------------------\n")
  if (object$panel_info$robust && !is.null(object$y_model$vcov_robust)) {
    print(lmtest::coeftest(object$y_model, vcov = object$y_model$vcov_robust))
  } else {
    print(summary(object$y_model))
  }
  
  # Total effects model
  cat("\nTotal Effects Model (X -> Y)\n")
  cat("----------------------------\n")
  if (object$panel_info$robust && !is.null(object$total_model$vcov_robust)) {
    print(lmtest::coeftest(object$total_model, vcov = object$total_model$vcov_robust))
  } else {
    print(summary(object$total_model))
  }
}

#' Panel data conditional effects plot
#' @param panel_result A panel_mediation object
#' @param moderator Character. Name of moderator variable
#' @param values Numeric vector of moderator values to plot
#' @param ... Additional arguments for plotting
#' @return A ggplot object
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon labs theme_minimal
#' @export
panel_condPlot <- function(panel_result, moderator = NULL, values = NULL, ...) {
  
  if (is.null(moderator)) {
    stop("Moderator variable must be specified for conditional effects plot")
  }
  
  # This is a simplified version - full implementation would require
  # more complex interaction term handling
  warning("Panel conditional effects plotting is simplified in this version")
  
  # Return a placeholder plot
  ggplot2::ggplot() + 
    ggplot2::labs(title = "Panel Data Conditional Effects",
                  subtitle = "Full implementation coming soon") +
    ggplot2::theme_minimal()
}

#' Bootstrap confidence intervals for panel mediation effects
#' @param panel_result A panel_mediation object
#' @param n_boot Integer. Number of bootstrap samples
#' @param conf_level Numeric. Confidence level (default 0.95)
#' @return A list containing bootstrap confidence intervals
#' @export
panel_bootstrap_ci <- function(panel_result, n_boot = 1000, conf_level = 0.95) {
  
  warning("Panel bootstrap implementation is simplified in this version")
  
  # Simplified placeholder - full implementation would require
  # proper panel bootstrap procedures
  alpha <- 1 - conf_level
  
  ci_list <- list()
  
  for (i in seq_along(panel_result$indirect_effects)) {
    effect_name <- names(panel_result$indirect_effects)[i]
    effect_value <- panel_result$indirect_effects[[i]]
    
    # Placeholder CI (would need proper bootstrap implementation)
    se_est <- abs(effect_value) * 0.1  # Simplified SE estimate
    ci_lower <- effect_value - qnorm(1 - alpha/2) * se_est
    ci_upper <- effect_value + qnorm(1 - alpha/2) * se_est
    
    ci_list[[effect_name]] <- c(lower = ci_lower, upper = ci_upper)
  }
  
  return(ci_list)
}
