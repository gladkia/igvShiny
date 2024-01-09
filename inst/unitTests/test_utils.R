library(igvShiny)
library(RUnit)
#----------------------------------------------------------------------------------------------------
runTests <- function()
{
    test_get_tracks_dir()

} # runTests
#----------------------------------------------------------------------------------------------------
test_get_tracks_dir <- function()
{
    message(sprintf("--- test_get_tracks_dir"))
    checkTrue(checkmate::test_string(get_tracks_dir()))

} # test_get_tracks_dir
#----------------------------------------------------------------------------------------------------
