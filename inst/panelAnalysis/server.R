server <- function(input, output, session) {
  
  # Reactive values to store data and results
  values <- reactiveValues(
    data = NULL,
    panel_result = NULL,
    comparison_results = NULL,
    is_panel = FALSE
  )
  
  # File upload handling
  observeEvent(input$file, {
    req(input$file)
    
    tryCatch({
      # Read the uploaded file
      if (tools::file_ext(input$file$datapath) == "csv") {
        values$data <- read.csv(input$file$datapath, stringsAsFactors = FALSE)
      } else {
        values$data <- read.table(input$file$datapath, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
      }
      
      # Update variable choices
      var_choices <- names(values$data)
      updateSelectInput(session, "id_var", choices = var_choices)
      updateSelectInput(session, "time_var", choices = var_choices)
      updateSelectInput(session, "x_var", choices = var_choices)
      updateSelectInput(session, "m_vars", choices = var_choices)
      updateSelectInput(session, "y_var", choices = var_choices)
      updateSelectInput(session, "w_vars", choices = var_choices)
      
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message), type = "error")
    })
  })
  
  # Sample data loading
  observeEvent(input$load_sample, {
    data(Grunfeld, package = "plm", envir = environment())
    
    # Add synthetic mediator for demonstration
    set.seed(123)
    Grunfeld$efficiency <- 0.3 * Grunfeld$inv + 0.2 * Grunfeld$capital + 
                          rnorm(nrow(Grunfeld), 0, 50)
    Grunfeld$market_condition <- rep(c(1, 0), length.out = nrow(Grunfeld))
    
    values$data <- Grunfeld
    
    # Set default variable selections
    var_choices <- names(values$data)
    updateSelectInput(session, "id_var", choices = var_choices, selected = "firm")
    updateSelectInput(session, "time_var", choices = var_choices, selected = "year")
    updateSelectInput(session, "x_var", choices = var_choices, selected = "inv")
    updateSelectInput(session, "m_vars", choices = var_choices, selected = "efficiency")
    updateSelectInput(session, "y_var", choices = var_choices, selected = "value")
    updateSelectInput(session, "w_vars", choices = var_choices)
    
    showNotification("Sample data loaded successfully!", type = "message")
  })
  
  # Check if file is uploaded or sample data is loaded
  output$fileUploaded <- reactive({
    return(!is.null(values$data))
  })
  outputOptions(output, "fileUploaded", suspendWhenHidden = FALSE)
  
  output$sampleLoaded <- reactive({
    return(!is.null(values$data))
  })
  outputOptions(output, "sampleLoaded", suspendWhenHidden = FALSE)
  
  # Data summary output
  output$data_summary <- renderText({
    req(values$data)
    
    paste(
      "Dataset Dimensions:", nrow(values$data), "rows x", ncol(values$data), "columns",
      "\nVariable Names:", paste(names(values$data), collapse = ", "),
      "\nMissing Values:", sum(is.na(values$data))
    )
  })
  
  # Panel structure check
  output$panel_structure <- renderText({
    req(values$data, input$id_var, input$time_var)
    
    if (input$id_var != "" && input$time_var != "") {
      values$is_panel <- is_panel_data(values$data, input$id_var, input$time_var)
      
      if (values$is_panel) {
        n_individuals <- length(unique(values$data[[input$id_var]]))
        n_time_periods <- length(unique(values$data[[input$time_var]]))
        
        paste(
          "✅ Panel Data Structure Detected",
          paste("\nNumber of individuals:", n_individuals),
          paste("\nNumber of time periods:", n_time_periods),
          paste("\nBalance check:", ifelse(nrow(values$data) == n_individuals * n_time_periods, "Balanced", "Unbalanced"))
        )
      } else {
        "❌ Panel Data Structure NOT Detected\nPlease check your ID and time variables."
      }
    } else {
      "Please select ID and time variables to check panel structure."
    }
  })
  
  # Data preview
  output$data_preview <- DT::renderDataTable({
    req(values$data)
    DT::datatable(values$data, options = list(scrollX = TRUE, pageLength = 10))
  })
  
  # Run panel analysis
  observeEvent(input$run_analysis, {
    req(values$data, input$id_var, input$time_var, input$x_var, input$m_vars, input$y_var)
    
    if (!values$is_panel) {
      showNotification("Cannot run panel analysis: Data structure is not panel data.", type = "error")
      return()
    }
    
    tryCatch({
      # Prepare moderator list if specified
      moderator_list <- list()
      if (input$include_moderator && length(input$w_vars) > 0) {
        moderator_list <- list(
          name = input$w_vars,
          site = replicate(length(input$w_vars), c("a", "c"), simplify = FALSE)
        )
      }
      
      # Run panel mediation analysis
      values$panel_result <- multipleMediation(
        X = input$x_var,
        M = input$m_vars,
        Y = input$y_var,
        data = values$data,
        moderator = moderator_list,
        panel = TRUE,
        id = input$id_var,
        time = input$time_var,
        panel_model = input$panel_model,
        panel_effect = input$panel_effect,
        robust_se = input$robust_se,
        lag = input$lag_periods
      )
      
      showNotification("Panel analysis completed successfully!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Analysis error:", e$message), type = "error")
    })
  })
  
  # Check if analysis is complete
  output$analysisComplete <- reactive({
    return(!is.null(values$panel_result))
  })
  outputOptions(output, "analysisComplete", suspendWhenHidden = FALSE)
  
  # Display analysis results
  output$indirect_effects <- renderText({
    req(values$panel_result)
    
    effects <- values$panel_result$indirect_effects
    if (length(effects) > 0) {
      effect_text <- mapply(function(name, value) {
        paste(name, ":", sprintf("%.4f", value))
      }, names(effects), effects)
      paste(effect_text, collapse = "\n")
    } else {
      "No indirect effects calculated."
    }
  })
  
  output$direct_effects <- renderText({
    req(values$panel_result)
    
    effects <- values$panel_result$direct_effects
    if (length(effects) > 0) {
      effect_text <- mapply(function(name, value) {
        paste(name, ":", sprintf("%.4f", value))
      }, names(effects), effects)
      paste(effect_text, collapse = "\n")
    } else {
      "No direct effects calculated."
    }
  })
  
  output$detailed_results <- renderPrint({
    req(values$panel_result)
    summary(values$panel_result)
  })
  
  output$model_info <- renderText({
    req(values$panel_result)
    
    info <- values$panel_result$panel_info
    paste(
      "Panel Model Type:", info$model,
      "\nEffect Type:", info$effect,
      "\nRobust Standard Errors:", info$robust,
      "\nLag Periods:", info$lag,
      "\nNumber of Individuals:", info$n_individuals,
      "\nNumber of Time Periods:", info$n_time_periods,
      "\nTotal Observations:", info$n_obs
    )
  })
  
  # Effects comparison plot
  output$effects_plot <- renderPlotly({
    req(values$panel_result)
    
    # Prepare data for plotting
    indirect <- values$panel_result$indirect_effects
    direct <- values$panel_result$direct_effects
    total <- values$panel_result$total_effects
    
    # Create data frame for plotting
    plot_data <- data.frame(
      Effect = c(names(indirect), names(direct), names(total)),
      Value = c(unlist(indirect), unlist(direct), unlist(total)),
      Type = c(rep("Indirect", length(indirect)), 
               rep("Direct", length(direct)),
               rep("Total", length(total)))
    )
    
    p <- plotly::plot_ly(plot_data, x = ~Effect, y = ~Value, color = ~Type, type = "bar") %>%
      plotly::layout(
        title = "Effect Sizes Comparison",
        xaxis = list(title = "Effects"),
        yaxis = list(title = "Effect Size"),
        barmode = "group"
      )
    
    return(p)
  })
  
  # Diagnostics plot (placeholder)
  output$diagnostics_plot <- renderPlot({
    req(values$panel_result)
    
    # Simple residuals plot for the Y model
    y_model <- values$panel_result$y_model
    if (!is.null(y_model)) {
      plot(fitted(y_model), residuals(y_model),
           main = "Residuals vs Fitted Values",
           xlab = "Fitted Values", ylab = "Residuals")
      abline(h = 0, col = "red", lty = 2)
    }
  })
  
  # Model comparison
  observeEvent(input$run_comparison, {
    req(values$data, input$comparison_models, values$is_panel)
    
    tryCatch({
      comparison_results <- list()
      
      for (model_type in input$comparison_models) {
        moderator_list <- list()
        if (input$include_moderator && length(input$w_vars) > 0) {
          moderator_list <- list(
            name = input$w_vars,
            site = replicate(length(input$w_vars), c("a", "c"), simplify = FALSE)
          )
        }
        
        result <- multipleMediation(
          X = input$x_var,
          M = input$m_vars,
          Y = input$y_var,
          data = values$data,
          moderator = moderator_list,
          panel = TRUE,
          id = input$id_var,
          time = input$time_var,
          panel_model = model_type,
          panel_effect = input$panel_effect,
          robust_se = FALSE,  # Disable for speed in comparison
          lag = input$lag_periods
        )
        
        comparison_results[[model_type]] <- result
      }
      
      values$comparison_results <- comparison_results
      showNotification("Model comparison completed!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Comparison error:", e$message), type = "error")
    })
  })
  
  # Check if comparison is complete
  output$comparisonComplete <- reactive({
    return(!is.null(values$comparison_results))
  })
  outputOptions(output, "comparisonComplete", suspendWhenHidden = FALSE)
  
  # Comparison table
  output$comparison_table <- DT::renderDataTable({
    req(values$comparison_results)
    
    # Extract comparison data
    comparison_data <- data.frame(
      Model = names(values$comparison_results),
      stringsAsFactors = FALSE
    )
    
    # Add indirect effects
    for (i in seq_along(values$comparison_results)) {
      model_name <- names(values$comparison_results)[i]
      indirect_effects <- values$comparison_results[[i]]$indirect_effects
      
      if (length(indirect_effects) > 0) {
        comparison_data[i, "Indirect_Effect"] <- sprintf("%.4f", indirect_effects[[1]])
      }
    }
    
    DT::datatable(comparison_data, options = list(pageLength = 10))
  })
  
  # Comparison visualization
  output$comparison_plot <- renderPlotly({
    req(values$comparison_results)
    
    # Extract indirect effects for plotting
    model_names <- names(values$comparison_results)
    indirect_values <- sapply(values$comparison_results, function(x) {
      if (length(x$indirect_effects) > 0) {
        return(x$indirect_effects[[1]])
      } else {
        return(0)
      }
    })
    
    plot_data <- data.frame(
      Model = model_names,
      Indirect_Effect = indirect_values
    )
    
    p <- plotly::plot_ly(plot_data, x = ~Model, y = ~Indirect_Effect, type = "bar") %>%
      plotly::layout(
        title = "Indirect Effects Across Panel Models",
        xaxis = list(title = "Panel Model Type"),
        yaxis = list(title = "Indirect Effect Size")
      )
    
    return(p)
  })
  
  # Download handlers (simplified)
  output$download_report <- downloadHandler(
    filename = function() {
      paste("panel_analysis_report.", input$export_format, sep = "")
    },
    content = function(file) {
      # This would generate a comprehensive report
      # For now, we'll create a simple text summary
      
      report_content <- paste(
        "Panel Data Analysis Report",
        "========================",
        "",
        "Analysis Settings:",
        paste("- Panel Model:", input$panel_model),
        paste("- Effect Type:", input$panel_effect),
        paste("- Robust SE:", input$robust_se),
        "",
        "Results Summary:",
        "Indirect Effects:",
        paste(names(values$panel_result$indirect_effects), "=", 
              sprintf("%.4f", unlist(values$panel_result$indirect_effects)), 
              collapse = "\n"),
        "",
        "Direct Effects:",
        paste(names(values$panel_result$direct_effects), "=", 
              sprintf("%.4f", unlist(values$panel_result$direct_effects)), 
              collapse = "\n"),
        sep = "\n"
      )
      
      writeLines(report_content, file)
    }
  )
  
  output$download_data <- downloadHandler(
    filename = function() {
      "processed_panel_data.csv"
    },
    content = function(file) {
      write.csv(values$data, file, row.names = FALSE)
    }
  )
}
