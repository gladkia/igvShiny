#' get_tracks_dir
#
#' Get the directory where tracks are stored. The directory can be defined with environmental variable.
#' If not defined the default is a directory called "tracks" in the temp directory.
#
#' We need a local directory to write files - for instance, a vcf file representing a genomic
#' region of interest. We then tell shiny about that directory, so that shiny's built-in http server
#' can serve up files we write there, ultimately consumed by igv.js
#'
#' @param env_var The name of the environmental variable to use.
#'
#' @return string with the path to the tracks directory.
#' 
#' @export
get_tracks_dir <- function(env_var = "TRACKS_DIR") {
  
  checkmate::assert_string(env_var)
  default_dir <- file.path(tempdir(), "tracks")
  tracks_dir <- Sys.getenv(env_var, default_dir)
  
  checkmate::assert_access(dirname(tracks_dir), "rw")
  
  if (!dir.exists(tracks_dir)) {
    dir.create(tracks_dir, recursive = TRUE)
  }
  tracks_dir
} # get_tracks_dir
#----------------------------------------------------------------------------------------------------
#' @title test_click_and_check
#' @description a helper function for clicking the button and checking if
#' second parameter exist in html code
#' 
#' @param button_id string of button which will be clicked in the test
#' @param expected_html_label string which attendance will be expected in html
#' @param app AppDriver shinyApp using for test
#'
#' @rdname test_click_and_check
#'
#' @export
#'
test_click_and_check <- function(button_id, expected_html_label, app) {
  app$click(button_id)
  igv_html <- app$get_html(selector = "#igvShiny_0")
  Sys.sleep(1)
  expect_true(grepl(expected_html_label, igv_html))
} # test_click_and_check
