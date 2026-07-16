fct_update_cats <- function(input_cat, var_name, r, session) {
  
  val <- tools::toTitleCase(trimws(input_cat))
  req(val != "")
  
  if (!(tolower(val) %in% tolower(r[[paste0("opts_", var_name)]]))) {
    
    ### Update options ----
    r[[paste0("opts_", var_name)]] <- sort(c(r[[paste0("opts_", var_name)]], val))
    
    ### Append the new row to the Google Sheet ----
    ### (never rewrite the tab: MoneyBlueprint owns it and pushes canonical
    ### rows; a rewrite from this session's stale snapshot would revert them)
    googlesheets4::sheet_append(
      ss    = Sys.getenv("GS_SHEET_ID"),
      data  = data.table::data.table(category = val),
      sheet = var_name
    )
    
    ### Update selected ----
    shiny::updateSelectizeInput(
      session = session,
      inputId = var_name,
      choices = r[[paste0("opts_", var_name)]],
      selected = val
    )
  }    
  
}