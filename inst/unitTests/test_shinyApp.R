library(igvShiny)
library(RUnit)
library(shinytest2)
#----------------------------------------------------------------------------------------------------
runAppTests <- function()
{
  test_shinyApp
} # runAppTests
#----------------------------------------------------------------------------------------------------
test_shinyApp <- function()
{
  message(sprintf("--- test_shinyApp"))
  
  shinytest2::load_app_env()
  
  #test_that("{shinytest2} recording: test_app", {
    
    app <- AppDriver$new(app_dir = system.file("app", package = "igvShiny"), name = "test_app", height = 695, width = 1235)
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
  #})
  
} # test_shinyApp
