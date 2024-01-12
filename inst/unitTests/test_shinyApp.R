library(igvShiny)
library(RUnit)
library(shinytest2)

#--helper functions--------------------------------------------------------------------------------------------------

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
.test_click_and_check <-
  function(button_id,
           expected_html_label,
           app,
           selector = "#igvShiny_0",
           sleep_time = 2) {
    app$click(button_id)
    igv_html <- app$get_html(selector = selector)
    Sys.sleep(sleep_time)
    expect_true(grepl(expected_html_label, igv_html))
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
    checkTrue(.test_click_and_check("addBedGraphTrackButton", "title=\"wig/bedGraph/local\"", app))
    checkTrue(.test_click_and_check("addBedGraphTrackFromURLButton", "title=\"bedGraph/remote\"", app))
    checkTrue(.test_click_and_check("addBamViaHttpButton", "title=\"1kg.bam\"", app))
    checkTrue(.test_click_and_check("addCramViaHttpButton", "title=\"CRAM\"", app))
  })
  
} # test_shinyAppDemo
