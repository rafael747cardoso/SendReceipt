

# Fronend
ui <- shiny::fluidPage(
  
  # Theme
  theme = bslib::bs_theme(bootswatch = "solar"),
  shiny::titlePanel("Receipt uploader"),
  
  # first a test for uploading an image from PC
  shiny::fileInput(
    inputId = "receipt_photo",
    label = "Take photo",
    accept = "image/*",
    capture = "environment",
    multiple = FALSE,
    width = "100%",
    buttonLabel = "click here"#,
    # placeholder = "Nothing selected"
  ),
  
  htmltools::tags$div(
    id = "image-container",
    style = "display:flexbox"
  )
  
  
)

# Backend
server <- function(input, output) {

  # Display the photo for checking
  shiny::observeEvent(input$receipt_photo, {
    
    req(input$receipt_photo)
    
    # Get input photo
    photo <- input$receipt_photo
    b64 <- base64enc::dataURI(
      file = photo$datapath,
      mime = "image/*"
    )
    
    # Clear previous photo
    shiny::removeUI(
      selector = "#image-container img",
      immediate = TRUE
    )
    
    # Display new photo
    shiny::insertUI(
      selector = "#image-container",
      where = "afterBegin",
      ui = shiny::img(
        src = b64,
        width = "100%",
        style = "max-width: 600px"
      )
    )
    
  })

  
  
}

# Run the application 
shiny::shinyApp(ui = ui, server = server)
