library(igvShiny)
library(RUnit)
library(shinytest2)
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
