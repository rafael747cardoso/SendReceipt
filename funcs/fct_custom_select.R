
fct_custom_select <- function(var_name, r){
  
  clean_var_name <- gsub(x = tolower(var_name), pattern = " ", replacement = "_")
  
  shiny::div(
    class = "inline-select",
    shiny::selectizeInput(
      inputId = clean_var_name,
      label = paste0(var_name, ":"),
      choices = c("", r[[paste0("opts_", clean_var_name)]]),
      width = "100%",
      options = list(
        placeholder = "Search or create",
        create = TRUE
      )
    )
  )
  
}
