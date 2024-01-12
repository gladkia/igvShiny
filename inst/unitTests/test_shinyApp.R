library(igvShiny)
library(RUnit)
library(shinytest2)

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
  Sys.sleep(10)
  expect_true(grepl(expected_html_label, igv_html))
  print("good")
}
#----------------------------------------------------------------------------------------------------
runAppTests <- function()
{
  test_shinyAppDemo
} # runAppTests
#----------------------------------------------------------------------------------------------------
test_shinyAppDemo <- function()
{
  message(sprintf("--- test_shinyAppDemo"))
  options(chromote.timeout = 60)  
  
  
  test_that("{shinytest2} recording: test_app", {
    
    sf <- system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
    app <- AppDriver$new(
      app_dir = shiny::shinyAppFile(sf),
      name = "test_app",
      height = 695,
      width = 1235,
      load_timeout = 1e+6,
      timeout = 1e+6
    )
    Sys.sleep(20)
    test_click_and_check("addBedGraphTrackButton", "title=\"wig/bedGraph/local\"", app)
    test_click_and_check("addBedGraphTrackFromURLButton", "title=\"bedGraph/remote\"", app)
    test_click_and_check("addBamViaHttpButton", "title=\"1kg.bam\"", app)
    test_click_and_check("addCramViaHttpButton", "title=\"CRAM\"", app)
  })
  
} # test_shinyAppDemo
