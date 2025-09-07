#' Panel Data Analysis Examples for processR
#' 
#' This document demonstrates how to use the extended processR package
#' for panel data mediation and moderation analysis.

#' @title Panel Data Mediation Analysis Examples
#' @name panel_examples
#' @examples
#' \dontrun{
#' # Load required libraries
#' library(processR)
#' library(plm)
#' 
#' # Example 1: Basic Panel Mediation Analysis
#' # Using built-in dataset from plm package
#' data(Grunfeld, package = "plm")
#' 
#' # Add a mediator variable for demonstration
#' set.seed(123)
#' Grunfeld$efficiency <- 0.3 * Grunfeld$inv + 0.2 * Grunfeld$capital + rnorm(nrow(Grunfeld), 0, 50)
#' 
#' # Basic panel mediation: investment -> efficiency -> firm value
#' panel_result <- multipleMediation(
#'   X = "inv",           # Independent variable
#'   M = "efficiency",    # Mediator variable  
#'   Y = "value",         # Dependent variable
#'   data = Grunfeld,
#'   panel = TRUE,        # Enable panel analysis
#'   id = "firm",         # Individual identifier
#'   time = "year",       # Time identifier
#'   panel_model = "within",  # Fixed effects model
#'   robust_se = TRUE     # Use robust standard errors
#' )
#' 
#' # View results
#' print(panel_result)
#' summary(panel_result)
#' 
#' # Example 2: Dynamic Panel Mediation with Lags
#' panel_dynamic <- multipleMediation(
#'   X = "inv",
#'   M = "efficiency", 
#'   Y = "value",
#'   data = Grunfeld,
#'   panel = TRUE,
#'   id = "firm",
#'   time = "year", 
#'   panel_model = "within",
#'   lag = 1,             # Include one-period lags
#'   robust_se = TRUE
#' )
#' 
#' # Example 3: Random Effects Panel Mediation
#' panel_random <- multipleMediation(
#'   X = "inv",
#'   M = "efficiency",
#'   Y = "value", 
#'   data = Grunfeld,
#'   panel = TRUE,
#'   id = "firm",
#'   time = "year",
#'   panel_model = "random",    # Random effects model
#'   panel_effect = "twoways",  # Include both individual and time effects
#'   robust_se = TRUE
#' )
#' 
#' # Example 4: Multiple Mediators in Panel Data
#' # Add another mediator
#' Grunfeld$innovation <- 0.2 * Grunfeld$inv + 0.1 * Grunfeld$capital + rnorm(nrow(Grunfeld), 0, 30)
#' 
#' panel_multiple <- multipleMediation(
#'   X = "inv",
#'   M = c("efficiency", "innovation"),  # Multiple mediators
#'   Y = "value",
#'   data = Grunfeld,
#'   panel = TRUE,
#'   id = "firm", 
#'   time = "year",
#'   panel_model = "within",
#'   robust_se = TRUE
#' )
#' 
#' # Example 5: Panel Data with Time-Varying Moderators
#' # Add a time-varying moderator
#' Grunfeld$market_condition <- rep(c(rep(1, 10), rep(0, 10)), 10)  # Alternating conditions
#' 
#' # Define moderator for panel analysis
#' moderator_panel <- list(
#'   name = "market_condition",
#'   site = list(c("a", "c"))  # Moderates both a and c paths
#' )
#' 
#' panel_moderated <- multipleMediation(
#'   X = "inv",
#'   M = "efficiency", 
#'   Y = "value",
#'   data = Grunfeld,
#'   moderator = moderator_panel,
#'   panel = TRUE,
#'   id = "firm",
#'   time = "year",
#'   panel_model = "within",
#'   robust_se = TRUE
#' )
#' 
#' # Bootstrap confidence intervals for panel mediation effects
#' boot_ci <- panel_bootstrap_ci(panel_result, n_boot = 500, conf_level = 0.95)
#' print(boot_ci)
#' 
#' # Compare different panel model specifications
#' models_comparison <- list(
#'   "Pooled" = multipleMediation(X = "inv", M = "efficiency", Y = "value", 
#'                               data = Grunfeld, panel = TRUE, id = "firm", time = "year",
#'                               panel_model = "pooling"),
#'   "Fixed Effects" = multipleMediation(X = "inv", M = "efficiency", Y = "value",
#'                                      data = Grunfeld, panel = TRUE, id = "firm", time = "year", 
#'                                      panel_model = "within"),
#'   "Random Effects" = multipleMediation(X = "inv", M = "efficiency", Y = "value",
#'                                       data = Grunfeld, panel = TRUE, id = "firm", time = "year",
#'                                       panel_model = "random")
#' )
#' 
#' # Extract and compare indirect effects
#' sapply(models_comparison, function(x) x$indirect_effects$indirect_efficiency)
#' }
#' 
#' @section Panel Data Requirements:
#' 
#' For panel data analysis, your dataset should have:
#' \itemize{
#'   \item An individual/entity identifier variable (e.g., firm ID, country ID)
#'   \item A time identifier variable (e.g., year, quarter)  
#'   \item Multiple observations per individual across time periods
#'   \item Variables measured consistently across time
#' }
#' 
#' @section Panel Model Types:
#' 
#' The package supports several panel model specifications:
#' \describe{
#'   \item{within}{Fixed effects model - controls for time-invariant unobserved heterogeneity}
#'   \item{random}{Random effects model - assumes individual effects are uncorrelated with regressors}
#'   \item{pooling}{Pooled OLS - ignores panel structure (generally not recommended)}
#'   \item{between}{Between estimator - uses cross-sectional variation only}
#' }
#' 
#' @section Advantages of Panel Data Analysis:
#' 
#' \itemize{
#'   \item Controls for unobserved heterogeneity
#'   \item Increased statistical power through more observations
#'   \item Ability to study dynamics and causal relationships over time
#'   \item Reduced omitted variable bias
#'   \item Can incorporate lagged variables and dynamic effects
#' }
#' 
#' @section Key Considerations:
#' 
#' \itemize{
#'   \item Choose appropriate panel model based on your research question
#'   \item Consider using robust standard errors for heteroscedasticity and serial correlation
#'   \item Test for fixed vs random effects using Hausman test
#'   \item Be aware of potential endogeneity issues in dynamic models
#'   \item Consider balance vs unbalanced panels
#' }
#' 
NULL
