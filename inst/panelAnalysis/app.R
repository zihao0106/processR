library(shiny)
library(shinyWidgets)
library(DT)
library(plotly)
library(processR)
library(plm)

ui <- fluidPage(
  titlePanel("processR: Panel Data Analysis"),
  
  tags$head(
    tags$style(HTML("
      .content-wrapper, .right-side {
        background-color: #f4f4f4;
      }
      .box {
        background: white;
        border-radius: 3px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
        margin-bottom: 20px;
        padding: 15px;
      }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      # Data Input Section
      div(class = "box",
        h4("📊 Data Input"),
        fileInput("file", "Upload CSV File",
                 accept = c(".csv", ".txt")),
        
        conditionalPanel(
          condition = "output.fileUploaded",
          
          h5("Panel Data Structure"),
          selectInput("id_var", "Individual ID Variable:", 
                     choices = NULL),
          selectInput("time_var", "Time Variable:", 
                     choices = NULL),
          
          h5("Analysis Variables"),
          selectInput("x_var", "Independent Variable (X):", 
                     choices = NULL),
          selectInput("m_vars", "Mediator Variable(s) (M):", 
                     choices = NULL, multiple = TRUE),
          selectInput("y_var", "Dependent Variable (Y):", 
                     choices = NULL),
          
          conditionalPanel(
            condition = "input.include_moderator",
            selectInput("w_vars", "Moderator Variable(s) (W):", 
                       choices = NULL, multiple = TRUE)
          ),
          
          checkboxInput("include_moderator", "Include Moderator", FALSE)
        )
      ),
      
      # Analysis Options
      div(class = "box",
        h4("⚙️ Analysis Options"),
        
        conditionalPanel(
          condition = "output.fileUploaded",
          
          selectInput("panel_model", "Panel Model Type:",
                     choices = list(
                       "Fixed Effects (within)" = "within",
                       "Random Effects (random)" = "random", 
                       "Pooled OLS (pooling)" = "pooling",
                       "Between Estimator (between)" = "between"
                     ),
                     selected = "within"),
          
          selectInput("panel_effect", "Effect Type:",
                     choices = list(
                       "Individual Effects" = "individual",
                       "Time Effects" = "time",
                       "Two-way Effects" = "twoways"
                     ),
                     selected = "individual"),
          
          checkboxInput("robust_se", "Robust Standard Errors", TRUE),
          
          numericInput("lag_periods", "Lag Periods (for dynamic models):",
                      value = 0, min = 0, max = 5, step = 1),
          
          br(),
          actionButton("run_analysis", "🚀 Run Panel Analysis", 
                      class = "btn-primary btn-block")
        )
      ),
      
      # Sample Data Option
      div(class = "box",
        h4("🔬 Try Sample Data"),
        p("No data file? Try our sample dataset:"),
        actionButton("load_sample", "Load Grunfeld Dataset", 
                    class = "btn-info btn-block"),
        br(),
        p(class = "text-muted", style = "font-size: 12px;",
          "The Grunfeld dataset contains investment data for 10 US firms from 1935-1954.")
      )
    ),
    
    mainPanel(
      width = 9,
      
      tabsetPanel(
        id = "main_tabs",
        
        # Data Overview Tab
        tabPanel("📈 Data Overview",
          br(),
          
          conditionalPanel(
            condition = "output.fileUploaded || output.sampleLoaded",
            
            fluidRow(
              column(6,
                div(class = "box",
                  h4("Panel Data Summary"),
                  verbatimTextOutput("data_summary")
                )
              ),
              column(6,
                div(class = "box",
                  h4("Panel Structure Check"),
                  verbatimTextOutput("panel_structure")
                )
              )
            ),
            
            div(class = "box",
              h4("Data Preview"),
              DT::dataTableOutput("data_preview")
            )
          ),
          
          conditionalPanel(
            condition = "!output.fileUploaded && !output.sampleLoaded",
            div(class = "box",
              h4("Welcome to processR Panel Data Analysis"),
              p("This application extends the processR package to support panel data analysis for mediation and moderation studies."),
              h5("Features:"),
              tags$ul(
                tags$li("Multiple panel model types (Fixed Effects, Random Effects, etc.)"),
                tags$li("Dynamic panel models with lagged variables"),
                tags$li("Robust standard errors for heteroscedasticity and serial correlation"),
                tags$li("Multiple mediators and moderators support"),
                tags$li("Interactive visualizations and downloadable results")
              ),
              h5("Getting Started:"),
              p("1. Upload your panel data CSV file, or try our sample dataset"),
              p("2. Specify your panel structure (ID and time variables)"),
              p("3. Select your analysis variables (X, M, Y, and optional moderators)"),
              p("4. Choose your panel model specifications"),
              p("5. Run the analysis and explore results!")
            )
          )
        ),
        
        # Analysis Results Tab
        tabPanel("📊 Analysis Results",
          br(),
          
          conditionalPanel(
            condition = "output.analysisComplete",
            
            fluidRow(
              column(6,
                div(class = "box",
                  h4("Indirect Effects"),
                  verbatimTextOutput("indirect_effects")
                )
              ),
              column(6,
                div(class = "box",
                  h4("Direct Effects"),
                  verbatimTextOutput("direct_effects")
                )
              )
            ),
            
            div(class = "box",
              h4("Detailed Model Results"),
              verbatimTextOutput("detailed_results")
            ),
            
            div(class = "box",
              h4("Model Information"),
              verbatimTextOutput("model_info")
            )
          ),
          
          conditionalPanel(
            condition = "!output.analysisComplete",
            div(class = "box",
              h4("No Analysis Results"),
              p("Please upload data, configure your analysis settings, and click 'Run Panel Analysis' to see results here.")
            )
          )
        ),
        
        # Visualization Tab
        tabPanel("📈 Visualizations",
          br(),
          
          conditionalPanel(
            condition = "output.analysisComplete",
            
            fluidRow(
              column(6,
                div(class = "box",
                  h4("Effect Sizes Comparison"),
                  plotlyOutput("effects_plot")
                )
              ),
              column(6,
                div(class = "box",
                  h4("Model Diagnostics"),
                  plotOutput("diagnostics_plot")
                )
              )
            ),
            
            conditionalPanel(
              condition = "input.include_moderator && length(input.w_vars) > 0",
              div(class = "box",
                h4("Conditional Effects Plot"),
                plotOutput("conditional_plot")
              )
            )
          ),
          
          conditionalPanel(
            condition = "!output.analysisComplete",
            div(class = "box",
              h4("No Visualizations Available"),
              p("Please complete your analysis first to view visualizations.")
            )
          )
        ),
        
        # Model Comparison Tab
        tabPanel("🔍 Model Comparison",
          br(),
          
          conditionalPanel(
            condition = "output.analysisComplete",
            
            div(class = "box",
              h4("Panel Model Comparison"),
              p("Compare results across different panel model specifications:"),
              
              fluidRow(
                column(4,
                  checkboxGroupInput("comparison_models", 
                                   "Select Models to Compare:",
                                   choices = list(
                                     "Pooled OLS" = "pooling",
                                     "Fixed Effects" = "within", 
                                     "Random Effects" = "random",
                                     "Between Estimator" = "between"
                                   ),
                                   selected = c("pooling", "within", "random"))
                ),
                column(8,
                  actionButton("run_comparison", "Compare Models", 
                              class = "btn-warning"),
                  br(), br(),
                  DT::dataTableOutput("comparison_table")
                )
              )
            ),
            
            conditionalPanel(
              condition = "output.comparisonComplete",
              div(class = "box",
                h4("Comparison Visualization"),
                plotlyOutput("comparison_plot")
              )
            )
          ),
          
          conditionalPanel(
            condition = "!output.analysisComplete",
            div(class = "box",
              h4("Model Comparison Not Available"),
              p("Please complete your main analysis first.")
            )
          )
        ),
        
        # Export Tab
        tabPanel("💾 Export Results",
          br(),
          
          conditionalPanel(
            condition = "output.analysisComplete",
            
            div(class = "box",
              h4("Download Analysis Results"),
              
              fluidRow(
                column(4,
                  h5("Report Format:"),
                  radioButtons("export_format", NULL,
                              choices = list(
                                "HTML Report" = "html",
                                "PDF Report" = "pdf", 
                                "Word Document" = "word",
                                "PowerPoint" = "pptx"
                              ),
                              selected = "html")
                ),
                column(4,
                  h5("Include Sections:"),
                  checkboxGroupInput("export_sections", NULL,
                                   choices = list(
                                     "Data Summary" = "data",
                                     "Analysis Results" = "results",
                                     "Visualizations" = "plots",
                                     "Model Comparison" = "comparison",
                                     "Technical Details" = "technical"
                                   ),
                                   selected = c("data", "results", "plots"))
                ),
                column(4,
                  br(),
                  downloadButton("download_report", "📥 Download Report", 
                               class = "btn-success btn-block"),
                  br(), br(),
                  downloadButton("download_data", "📥 Download Processed Data", 
                               class = "btn-info btn-block")
                )
              )
            )
          ),
          
          conditionalPanel(
            condition = "!output.analysisComplete",
            div(class = "box",
              h4("Export Not Available"),
              p("Please complete your analysis first to export results.")
            )
          )
        )
      )
    )
  )
)

# Server logic will be in a separate file for better organization
source("server.R", local = TRUE)

shinyApp(ui = ui, server = server)
