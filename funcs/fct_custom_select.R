
fct_custom_select <- function(var_name, r){
  
  clean_var_name <- gsub(x = tolower(var_name), pattern = " ", replacement = "_")
  
  shiny::selectizeInput(
    inputId = clean_var_name,
    label = var_name,
    choices = c("" , r[[paste0("opts_", clean_var_name)]]),
    options = list(
      placeholder = "Search or create",
      create = TRUE
    )
  )
  
}
