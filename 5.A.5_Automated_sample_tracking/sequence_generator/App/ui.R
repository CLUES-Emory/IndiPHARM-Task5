
##########################################################################################################
#### UI SECTION 
##########################################################################################################

ui <- fluidPage(
  useShinyjs(),
  titlePanel("LC 384-well plate sequence generator - Walker Lab"), 
  tabsetPanel(
    id = "tabs",
    
    # First tab - File Upload
    tabPanel(
      "1. Upload Plate Scans",
      sidebarLayout(
        sidebarPanel(
          tags$div(
            style = "padding: 10px; background-color: #e8f4f8; border: 1px solid #d1e0e0; border-radius: 5px; margin-bottom: 15px;",
            tags$p(tags$strong("Note:"), "Upload 1-4 plate files.")
          ),
          fileInput("plate1", "Upload Plate 1 CSV (optional)", accept = ".csv"),
          uiOutput("plate1_type_ui"),
          fileInput("plate2", "Upload Plate 2 CSV (optional)", accept = ".csv"),
          uiOutput("plate2_type_ui"),
          fileInput("plate3", "Upload Plate 3 CSV (optional)", accept = ".csv"),
          uiOutput("plate3_type_ui"),
          fileInput("plate4", "Upload Plate 4 CSV (optional)", accept = ".csv"),
          uiOutput("plate4_type_ui"),
          actionButton("process", "Process Files", class = "btn-primary")
        ),
        mainPanel(
          fluidRow(
            column(12,
                   br(),
                   br(),
                   h4("Purpose:"),
                   p(".csv plate scans + study inventory + user input = LC sequence list!"),
                   br(),
                   br(),
                   br(),
                   h4("Instructions:"),
                   p("1. Upload the Micronic RackData .csv files for each plate. Specify sample/QAQC plate."),
                   p("2. I will order the Matrix IDs into a 384-well plate. Check for accuracy."),
                   p("3. I will search the study inventory and label QAQC samples and check Matrix IDs. Check for accuracy."),
                   p("4. Add LC Run Info and I will generate a sequence list."),
                   br(),
                   br(),
                   h4("Progress Console:"),
                   br()
            )
          ),
          verbatimTextOutput("debug_output") %>%
            tagAppendAttributes(style = "height: 200px; background-color: #f8f9fa; border: 1px solid #ddd; padding: 8px; overflow-y: auto;")
        )
      )
    ), # end first tab
    
    tabPanel(
      "2. Check Layout",
      fluidRow(
        column(6,
               tableOutput("result_table1")
        ),
        column(6,
               h4("96-Well Matrix Rack Layouts"),
               plotOutput("plate1"),
               br(),
               plotOutput("plate2"),
               br(),
               plotOutput("plate3"),
               br(),
               plotOutput("plate4")
        )
      )
    ), # end second tab
    
    tabPanel(
      "3. Connect to inventory",
      fluidRow(
        column(12,
               div(style = "display: flex; align-items: center; margin-bottom: 10px;",
                   div(style = "flex-grow: 1",
                       br(),
                       h4("Click below to match Matrix IDs from study inventory. Check for accuracy. Then update database."),
                       actionButton("match_samples", "Step 1: Match IDs to inventory", class = "btn-primary"),
                       actionButton("add_matrix_ids", "Step 2: Update inventory", class = "btn-info"),
                       br(), br(), 
                       div(
                         style = "
                            border: 1px solid #ccc;
                            border-radius: 5px;
                            padding: 15px;
                            margin-bottom: 15px;
                            background-color: #f9f9f9;
                            margin-right: 20px; /* space between boxes */
                          ",
                         
                         h4("Injection Order Settings", style = "margin-top: 0;"),
                         
                         # Manual override
                         tags$b("Manually set injection order"),
                         radioButtons(
                           "order_by", NULL,
                           choices = c(
                             "Order by column (A1, C1, E1 ...)" = "Col_order_by_plate", 
                             "Order by row (A1, A3, A5 ...)" = "Row_order_by_plate"
                           ),
                           selected = "Col_order_by_plate",
                           inline = TRUE
                         )
                       ), # END BOX FOR ORDER MESSAGES AND SELECTION
                       br(),
                       br(),
                   ),
                   uiOutput("matchstatus")
               )
        ) #end top row
      ),
      # NEXT ROW - Fixed the structure here
      fluidRow(
        column(6, 
               tableOutput("result_table2")
        ),
        column(6,
               h4("QAQC Plate Layout with Sample IDs"),
               uiOutput("qaqc_plate_container")
        )
      )
    ), # end third tab
    
    tabPanel(
      "4. Generate sequence list",
      fluidRow(
        column(12, 
               h3("Enter Run Info"),
               uiOutput("run_info")
        )

      ),
      
      # Filepath selection panel
      fluidRow(
        column(12,
               div(style = "background-color: #e6f4e6; padding: 15px; border: 1px solid #c3e6cb; border-radius: 5px; margin-top: 30px;",
                   h3("Check the filepaths and EDIT/PASTE if needed."),
                   fluidRow(
                     column(12,
                            textInput("project_path", "1. Project filepath (where .RAW files go)", value = NULL, width = "100%")
                     )
                   ),
                   
                   # fluidRow(
                   #   column(12,
                   #          textInput("method_folder", "2. Method Folder", value = NULL, width = "100%")
                   #   )
                   # ), 
                   
                   
                   # fluidRow(
                   #   column(6,
                   #          actionButton("btn_local", "I am on an instrument computer (C:/ on this machine)",
                   #                       style = "width: 100%; background-color: #4CAF50; color: white;") # green button
                   #   ),
                   #   column(6,
                   #          actionButton("btn_remote", "Assign method filepaths remotely (C:/ not on this machine)",
                   #                       style = "width: 100%; background-color: #6C757D; color: white;") # gray button
                   #   )
                   # ), #removed 10/27
                   
                   br(),
                   
                   fluidRow(
                     column(12,
                            textInput("output_path", "2. Output filepath (where this sequence file will go)", value = NULL, width = "100%")
                     )
                   ),
                   fluidRow(
                     column(12,
                            actionButton("confirm_paths", "Confirm Paths *MUST CLICK*", 
                                         style = "margin-top: 10px; width: 100%; background-color: #007BFF; color: white;")
                     )
                   )
               )
        )
      ),
      
      fluidRow(
        column(12,
               h3("Generate Sequence List"),
               uiOutput("generate_list")
        )
      ),
      
      # Add the debug console container below
      fluidRow(
        column(12,
               h3("Progress/Debug Console", style = "margin-top: 30px;"),
               div(
                 style = "position: relative;",
                 actionButton("clear_debug", "Clear Console", 
                              style = "position: absolute; right: 10px; top: 0;"),
                 verbatimTextOutput("debug_console") %>%
                   tagAppendAttributes(style = "height: 300px; overflow-y: auto; background-color: #f8f9fa; 
                                        border: 1px solid #ddd; padding: 8px; 
                                        font-family: monospace; white-space: pre;
                                        margin-top: 35px; font-size: 12px;")
               )
        )
      )
    ) # end fourth tab
  ) # end tabset panel
) # end ui
