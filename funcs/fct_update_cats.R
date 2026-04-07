
fct_update_cats <- function(input_cat, var_name, r, session) {
  
  val <- tools::toTitleCase(trimws(input_cat))
  req(val != "")
  
  if (!(tolower(val) %in% tolower(r[[paste0("opts_", var_name)]]))) {
    
    ### Update options ----
    r[[paste0("opts_", var_name)]] <- sort(c(r[[paste0("opts_", var_name)]], val))
    
    ### Append CSV with new option ----
    data.table::fwrite(
      x = data.table::data.table(category = r[[paste0("opts_", var_name)]]),
      file = paste0("data/", var_name, ".csv"),
      quote = TRUE
    )      
    
    ### Update selected ----
    shiny::updateSelectizeInput(
      session = session,
      inputId = "establishment_type",
      choices = r[[paste0("opts_", var_name)]],
      selected = val
    )
  }    
  
}
