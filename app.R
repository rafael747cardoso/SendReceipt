
# Frontend ----
ui <- shiny::fluidPage(
  
  ## Theme ----
  theme = bslib::bs_theme(bootswatch = "darkly"),
  shiny::titlePanel("Receipt uploader"),
  
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

  ## Dropdowns ----
  
  ### Date ----
  shinyWidgets::airDatepickerInput(
    inputId = "purchase_date",
    label = "Date",
    placeholder = "Placeholder",
    addon = "none",
    value = Sys.Date()
  ),
  
  ### Establishment Type ----
  shiny::uiOutput(outputId = "establishment_type_ui"),

  ### Establishment Name ----
  
  ### Purchase Type ----
  
  ### Purchase Content ----
  
  
  ## Button to send email ----
  shinyWidgets::actionBttn(
    inputId = "btn_send_email",
    label = "Send",
    color = "primary"
  ),
  
  ## Display photo ----
  shiny::imageOutput(outputId = "uploaded_photo"),
  
)


# Backend ----
server <- function(input, output, session) {
  
  ## Read categories from repo data ----
  r <- shiny::reactiveValues()
  r$opts_establishment_type <- data.table::fread("data/establishment_type.csv")$category
  
  ## Build dropdowns ----
  
  ### Establishment Type ----
  output$establishment_type_ui <- shiny::renderUI({
    shiny::selectizeInput(
      inputId = "establishment_type",
      label = "Establishment Type",
      choices = r$opts_establishment_type,
      options = list(
        placeholder = "Search or create",
        create = TRUE
      )
    )
  })

  ## Update categories ----
  shiny::observeEvent(input$establishment_type, {
    fct_update_cats(input_cat = input$establishment_type, 
                    var_name = "establishment_type",
                    r = r,
                    session = session)
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
    
    req(
      input$receipt_photo,
      input$establishment_type
    )

    ### Build file name ----
    # "timestampe; purch-date; estab-type; estab-name; purch-type; purch-content"
    
    #### Timestamp ----
    photo_name <- format(Sys.time(), "%Y%m%d_%H%M%S")
    
    #### When: Purchase Date ----
    photo_name <- paste0(photo_name, "; ", input$purchase_date)
    
    #### Where: Establishment Type ----
    photo_name <- paste0(photo_name, "; ", input$establishment_type)
    
    #### Where: Establishment Name ----
    
    #### What: Purchase Type ----
    
    #### What: Purchase Content ----
    # to use when the receipt has no info on the content purchased
    
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
