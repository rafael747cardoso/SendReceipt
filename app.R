
# Load functions ----
lapply(list.files("funcs", pattern = "\\.R$", full.names = TRUE), source)

test_mode <- TRUE

# Frontend ----
ui <- shiny::fluidPage(
  
  ## Theme ----
  theme = bslib::bs_theme(bootswatch = "darkly"),
  
  ## Custom CSS/JS for mobile ----
  shiny::tags$head(
    shiny::tags$link(rel = "stylesheet", href = "styles.css"),
    shiny::tags$script(src = "app.js")
  ),
  
  shiny::div(
    class = "title-panel", 
    shiny::titlePanel(paste0("Receipt uploader", ifelse(test_mode, " - TEST", "")))
  ),
  
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
  r$opts_establishment_name <- data.table::fread("data/establishment_name.csv")
  r$opts_purchase_type      <- data.table::fread("data/purchase_type.csv")
  r$opts_purchase_content   <- data.table::fread("data/purchase_content.csv")$category
  
  ## Build dropdowns ----
  
  output$establishment_type_ui <- shiny::renderUI({
    fct_custom_select("Establishment Type", r)
  })
  
  output$establishment_name_ui <- shiny::renderUI({
    shiny::div(
      class = "inline-select",
      shiny::selectizeInput(
        inputId = "establishment_name",
        label = "Establishment Name:",
        choices = c(""),
        width = "100%",
        options = list(placeholder = "Select type first", create = TRUE)
      )
    )
  })
  
  output$purchase_type_ui <- shiny::renderUI({
    shiny::div(
      class = "inline-select",
      shiny::selectizeInput(
        inputId = "purchase_type",
        label = "Purchase Type:",
        choices = c(""),
        width = "100%",
        options = list(placeholder = "Select estab. type first", create = TRUE)
      )
    )
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
    
    val <- tools::toTitleCase(trimws(input$establishment_name))
    req(val != "")
    
    current_type <- input$establishment_type
    req(!is.null(current_type) && current_type != "")
    
    ## Check if combo already exists ----
    existing <- r$opts_establishment_name
    already_exists <- any(tolower(existing$name) == tolower(val) & 
                          tolower(existing$type) == tolower(current_type))
    
    if (!already_exists) {
      
      ## Add new row ----
      new_row <- data.table::data.table(name = val, 
                                        type = current_type)
      r$opts_establishment_name <- rbind(r$opts_establishment_name, new_row)
      r$opts_establishment_name <- r$opts_establishment_name[order(name)]
      
      ## Append CSV ----
      data.table::fwrite(
        x = r$opts_establishment_name,
        file = "data/establishment_name.csv",
        quote = TRUE
      )
      
      ## Update dropdown with filtered names ----
      filtered <- r$opts_establishment_name[type == current_type]$name
      shiny::updateSelectizeInput(
        session = session,
        inputId = "establishment_name",
        choices = c("", filtered),
        selected = val
      )
    }
    
  })
  
  shiny::observeEvent(input$purchase_type, {
    
    val <- tools::toTitleCase(trimws(input$purchase_type))
    req(val != "")
    
    current_type <- input$establishment_type
    req(!is.null(current_type) && current_type != "")
    
    ## Check if combo already exists ----
    existing <- r$opts_purchase_type
    already_exists <- any(tolower(existing$purchase) == tolower(val) & 
                            tolower(existing$type) == tolower(current_type))
    
    if (!already_exists) {
      
      ## Add new row ----
      new_row <- data.table::data.table(purchase = val, type = current_type)
      r$opts_purchase_type <- rbind(r$opts_purchase_type, new_row)
      r$opts_purchase_type <- r$opts_purchase_type[order(purchase)]
      
      ## Append CSV ----
      data.table::fwrite(
        x = r$opts_purchase_type,
        file = "data/purchase_type.csv",
        quote = TRUE
      )
      
      filtered <- r$opts_purchase_type[type == current_type]$purchase
      shiny::updateSelectizeInput(
        session = session,
        inputId = "purchase_type",
        choices = c("", filtered),
        selected = val
      )
    }
    
  })
  
  shiny::observeEvent(input$purchase_content, {
    fct_update_cats(input_cat = input$purchase_content, 
                    var_name = "purchase_content",
                    r = r, session = session)
  })

  ## Filters in dropdowns ----
  shiny::observeEvent(input$establishment_type, {
    
    ## Filter establishment names by selected establishment type ----
    all_names <- r$opts_establishment_name
    
    if (!is.null(input$establishment_type) && input$establishment_type != "") {
      filtered <- all_names[type == input$establishment_type]$name
    } else {
      filtered <- all_names$name
    }
    
    shiny::updateSelectizeInput(
      session = session,
      inputId = "establishment_name",
      choices = c("", filtered),
      selected = "",
      options = list(placeholder = "Search or create", create = TRUE)
    )
    
    # Filter purchase types by selected establishment type
    all_purchases <- r$opts_purchase_type
    
    if (!is.null(input$establishment_type) && input$establishment_type != "") {
      filtered_purchases <- all_purchases[type == input$establishment_type]$purchase
    } else {
      filtered_purchases <- all_purchases$purchase
    }
    
    shiny::updateSelectizeInput(
      session = session,
      inputId = "purchase_type",
      choices = c("", filtered_purchases),
      selected = "",
      options = list(placeholder = "Search or create", create = TRUE)
    )
    
  }, ignoreInit = TRUE)
  
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

    ### Send email via Resend API ----
    
    #### Photo data ----
    photo_path <- input$receipt_photo$datapath
    photo_b64  <- base64enc::base64encode(photo_path)
    
    cat("=== DEBUG ===\n")
    cat("KEY length:", nchar(Sys.getenv("RESEND_API_KEY")), "\n")
    cat("TO value:", Sys.getenv("RESEND_TO_EMAIL"), "\n")
    cat("TO length:", nchar(Sys.getenv("RESEND_TO_EMAIL")), "\n")
    
    #### API request ----
    body <- list(
      from    = "onboarding@resend.dev",
      to = list(Sys.getenv("RESEND_TO_EMAIL")),
      subject = paste0(ifelse(test_mode, "[TEST] ", "[RECEIPT] "), photo_name),
      text    = photo_name,
      attachments = list(
        list(
          filename     = paste0(photo_name, ".jpeg"),
          content      = photo_b64,
          content_type = "image/jpeg"
        )
      )
    )
    
    resp <- tryCatch(
      httr2::request("https://api.resend.com/emails") |>
        httr2::req_headers(
          Authorization = paste("Bearer", Sys.getenv("RESEND_API_KEY")),
          `Content-Type` = "application/json"
        ) |>
        httr2::req_body_json(body) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform(),
      error = function(e) e
    )
    
    cat("Status:", httr2::resp_status(resp), "\n")
    cat("Body:", httr2::resp_body_string(resp), "\n")
    
    #### Response status ----
    if (httr2::resp_status(resp) == 200) {
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Sent!",
        text = "Receipt emailed successfully.",
        type = "success"
      )
    } else {
      shinyWidgets::sendSweetAlert(
        session = session,
        title = "Error",
        text = paste("Failed to send. Status:", httr2::resp_status(resp)),
        type = "error"
      )
    }

  })

}

# Run the application ----
shiny::shinyApp(ui = ui, server = server)
