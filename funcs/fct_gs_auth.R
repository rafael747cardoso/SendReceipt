
fct_gs_auth <- function() {
  
  gs_key <- jsonlite::fromJSON(Sys.getenv("GS_SERVICE_KEY"), simplifyVector = FALSE)
  tmp <- tempfile(fileext = ".json")
  jsonlite::write_json(gs_key, tmp, auto_unbox = TRUE)
  googlesheets4::gs4_auth(path = tmp)

}
