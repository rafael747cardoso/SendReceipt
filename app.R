
# Load functions ----
lapply(list.files("funcs", pattern = "\\.R$", full.names = TRUE), source)


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
  shiny::uiOutput(outputId = "establishment_name_ui"),
  
  ### Purchase Type ----
  shiny::uiOutput(outputId = "purchase_type_ui"),
  
  ### Purchase Content ----
  shiny::uiOutput(outputId = "purchase_content_ui"),

  ## Button to send email ----
  shinyWidgets::actionBttn(
    inputId = "btn_send_email",
    label = "Send",
    color = "primary"
  ),
  
  ## Display photo ----
  shiny::imageOutput(outputId = "uploaded_photo")
  
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
    browser()
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
    
    req(
      input$receipt_photo,
      input$establishment_type,
      input$establishment_name,
      input$purchase_type
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
