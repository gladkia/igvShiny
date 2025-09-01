library(testthat)
library(igvShiny)

test_that("get_tracks_dir returns a valid character string", {
    # The checkmate test is good, so we can keep it inside an expect_true call
    expect_true(checkmate::test_string(get_tracks_dir()))
})

