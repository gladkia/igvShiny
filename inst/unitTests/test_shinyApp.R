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
  
  test_that("{shinytest2} recording: test_app", {
  
    sf <- system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
    app <- shinytest2::    AppDriver$new(
      app_dir = shiny::shinyAppFile(sf),
      name = "test_app",
      height = 695,
      width = 1235,
      load_timeout = 1e+5,
      timeout = 1e+5
    )
    app$set_inputs(igvReady = "igvShiny_0", allow_no_input_binding_ = TRUE, priority_ = "event")
    app$set_inputs(igvReady = "igvShiny_0", allow_no_input_binding_ = TRUE, priority_ = "event")
    Sys.sleep(15)
    app$expect_values()
    app$click("addBedGraphTrackButton")
    app$set_inputs(currentGenomicRegion.igvShiny_0 = "chr1:7426230-7453241", allow_no_input_binding_ = TRUE, 
                   priority_ = "event")
    app$expect_values()
    app$click("addGwasTrackButton")
    app$set_inputs(currentGenomicRegion.igvShiny_0 = "chr19:45248107-45564645", allow_no_input_binding_ = TRUE, 
                   priority_ = "event")
    app$expect_values()
  })
  
} # test_shinyAppDemo
