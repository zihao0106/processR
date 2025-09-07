#' Run panel data analysis shiny app
#' @description Launch an interactive Shiny application for panel data mediation and moderation analysis
#' @importFrom utils install.packages
#' @export
#' @examples
#' \dontrun{
#' # Launch the panel data analysis app
#' runPanelApp()
#' }
runPanelApp <- function() {
  
  # Check and install required packages
  required_packages <- c("shiny", "shinyWidgets", "DT", "plotly")
  
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message(paste("Installing required package:", pkg))
      install.packages(pkg)
    }
  }
  
  # Check if plm is available
  if (!requireNamespace("plm", quietly = TRUE)) {
    message("Installing plm package for panel data analysis...")
    install.packages("plm")
  }
  
  # Launch the app
  app_dir <- system.file('panelAnalysis', package = 'processR')
  
  if (app_dir == "") {
    stop("Could not find the panel analysis app. Please reinstall the processR package.")
  }
  
  message("Launching processR Panel Data Analysis App...")
  message("This app provides interactive analysis for panel data mediation and moderation.")
  
  shiny::runApp(app_dir, launch.browser = TRUE)
}
