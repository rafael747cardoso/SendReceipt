
# Load functions ----
lapply(list.files("funcs", pattern = "\\.R$", full.names = TRUE), source)

# Frontend ----
ui <- shiny::fluidPage(
  
  ## Theme ----
  theme = bslib::bs_theme(bootswatch = "darkly"),
  
  ## Custom CSS for mobile ----
  shiny::tags$head(shiny::tags$style(shiny::HTML("
    body { max-width: 500px; margin: auto; padding: 10px; }
    .btn-primary { width: 100%; margin-top: 15px; margin-bottom: 15px; font-size: 18px; padding: 12px; }
    #uploaded_photo img { width: 100% !important; height: auto !important; border-radius: 8px; }
    .inline-select .form-group { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
    .inline-select .control-label { white-space: nowrap; margin-bottom: 0; font-weight: bold; }
    .inline-select .form-group > div { flex: 1; width: 100% !important; }
    .inline-select .selectize-control { width: 100% !important; }
    .inline-select .selectize-input { width: 100% !important; }
    .inline-select .control-label { white-space: nowrap; margin-bottom: 0; font-weight: bold; min-width: 160px; }
    .title-panel { margin-bottom: 20px; }
  "))), 
  
  shiny::div(class = "title-panel", shiny::titlePanel("Receipt uploader")),
  
  ## Upload photo ----
  shiny::fileInput(
    inputId = "receipt_photo",
    accept = "image/*",
    capture = "environment",
    multiple = FALSE,
    width = "100%",
    label = NULL,
    buttonLabel = "Take photo",
    placeholder = "Nothing selected"
  ),
  
  ## Display photo ----
  shiny::imageOutput(outputId = "uploaded_photo", height = "auto"),
  shiny::tags$hr(),
  
  ## Dropdowns ----
  
  ### Date ----
  shiny::div(
    class = "inline-select",
    shinyWidgets::airDatepickerInput(
      inputId = "purchase_date",
      label = "Date:",
      placeholder = "Placeholder",
      addon = "none",
      value = Sys.Date(),
      width = "100%",
      autoClose = TRUE
    )
  ),
  shiny::tags$hr(),
  
  ### Establishment Type ----
  shiny::uiOutput(outputId = "establishment_type_ui"),
  shiny::tags$hr(),
  
  ### Establishment Name ----
  shiny::uiOutput(outputId = "establishment_name_ui"),
  shiny::tags$hr(),
  
  ### Purchase Type ----
  shiny::uiOutput(outputId = "purchase_type_ui"),
  shiny::tags$hr(),
  
  ### Purchase Content ----
  shiny::uiOutput(outputId = "purchase_content_ui"),
  shiny::tags$hr(),
  
  ## Button to send email ----
  shinyWidgets::actionBttn(
    inputId = "btn_send_email",
    label = "Send",
    color = "primary",
    style = "fill",
    block = TRUE,
    size = "lg"
  )
  
)

# Backend ----
server <- function(input, output, session) {
  
  ## Read categories from repo data ----
  r <- shiny::reactiveValues()
  r$opts_establishment_type <- data.table::fread("data/establishment_type.csv")$category
  r$opts_establishment_name <- data.table::fread("data/establishment_name.csv")$category
  r$opts_purchase_type      <- data.table::fread("data/purchase_type.csv")$category
  r$opts_purchase_content   <- data.table::fread("data/purchase_content.csv")$category
  
  ## Build dropdowns ----
  output$establishment_type_ui <- shiny::renderUI({
    fct_custom_select("Establishment Type", r)
  })
  output$establishment_name_ui <- shiny::renderUI({
    fct_custom_select("Establishment Name", r)
  })
  output$purchase_type_ui <- shiny::renderUI({
    fct_custom_select("Purchase Type", r)
  })
  output$purchase_content_ui <- shiny::renderUI({
    fct_custom_select("Purchase Content", r)
  })

  ## Update categories ----
  shiny::observeEvent(input$establishment_type, {
    fct_update_cats(input_cat = input$establishment_type, 
                    var_name = "establishment_type",
                    r = r, session = session)
  })
  shiny::observeEvent(input$establishment_name, {
    fct_update_cats(input_cat = input$establishment_name, 
                    var_name = "establishment_name",
                    r = r, session = session)
  })
  shiny::observeEvent(input$purchase_type, {
    fct_update_cats(input_cat = input$purchase_type, 
                    var_name = "purchase_type",
                    r = r, session = session)
  })
  shiny::observeEvent(input$purchase_content, {
    fct_update_cats(input_cat = input$purchase_content, 
                    var_name = "purchase_content",
                    r = r, session = session)
  })

  ## Display the photo for checking ----
  output$uploaded_photo <- shiny::renderImage({
    
    req(input$receipt_photo)
    
    list(
      src = input$receipt_photo$datapath,
      contentType = input$receipt_photo$type,
      width = 800,
      height = "auto"
    )
    
  }, deleteFile = FALSE)
  
  ## Send to email ----
  shiny::observeEvent(input$btn_send_email, {
    
    ### Validate required fields ----
    missing <- c()
    if (is.null(input$receipt_photo)) missing <- c(missing, "Photo")
    if (is.null(input$establishment_type) || trimws(input$establishment_type) == "") missing <- c(missing, "Establishment Type")
    if (is.null(input$establishment_name) || trimws(input$establishment_name) == "") missing <- c(missing, "Establishment Name")
    if (is.null(input$purchase_type) || trimws(input$purchase_type) == "") missing <- c(missing, "Purchase Type")
    
    if (length(missing) > 0) {
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Missing fields",
        text = paste("Please fill in:", paste(missing, collapse = ", ")),
        type = "warning"
      )
      return()
    }
    
    ### Build file name ----
    # "timestampe; purch-date; estab-type; estab-name; purch-type; purch-content"
    
    #### Timestamp ----
    photo_name <- format(Sys.time(), "%Y%m%d_%H%M%S")
    
    #### When: Purchase Date ----
    photo_name <- paste0(photo_name, "; ", input$purchase_date)
    
    #### Where: Establishment Type ----
    photo_name <- paste0(photo_name, "; ", input$establishment_type)
    
    #### Where: Establishment Name ----
    photo_name <- paste0(photo_name, "; ", input$establishment_name)
    
    #### What: Purchase Type ----
    photo_name <- paste0(photo_name, "; ", input$purchase_type)
    
    #### What: Purchase Content ----
    # to use when the receipt has no info on the content of the purchase
    if (!is.null(input$purchase_content)) {
      purchase_content <- trimws(input$purchase_content)
      if (purchase_content != "") {
        photo_name <- paste0(photo_name, "; ", purchase_content)
      }
    }

    ### TEST: save to PC ----
    file.copy(
      from = input$receipt_photo$datapath,
      to = paste0("dev_tests/", photo_name, ".jpeg")
    )
    
    ### Send email via Resend API ----
    
    
    
  })

}

# Run the application ----
shiny::shinyApp(ui = ui, server = server)
