library(testthat)
library(shinytest2)
library(igvShiny)

# Helper function for clicking a UI element and checking the resulting HTML
.click_and_check <- function(app, button_id, expected_html_label, selector = "#igvShiny_0", sleep_time = 2) {
    app$click(button_id)
    Sys.sleep(sleep_time) # allow time for UI to update
    igv_html <- app$get_html(selector = selector)
    expect_true(grepl(expected_html_label, igv_html, fixed = TRUE))
}

test_that("igvShinyDemo loads tracks correctly", {
    # Increase timeout for potentially slow-loading remote resources
    options(chromote.timeout = 120)

    sf <- system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
    app <- AppDriver$new(
        app_dir = shiny::shinyAppFile(sf),
        name = "igv-shiny-demo-app",
        height = 695,
        width = 1235,
        load_timeout = 1e+6,
        timeout = 1e+6
    )

    # Wait for the app and genome to fully load
    app$wait_for_value(input = "igvReady")
    Sys.sleep(2)

    .click_and_check(app, "addBedGraphTrackButton", 'title="wig/bedGraph/local"')
    .click_and_check(app, "addBedGraphTrackFromURLButton", 'title="bedGraph/remote"')
    .click_and_check(app, "addBamViaHttpButton", 'title="1kg.bam"')
    .click_and_check(app, "addCramViaHttpButton", 'title="CRAM"')

    app$stop()
})

test_that("igvShinyDemo-GFF3 loads tracks correctly", {
    options(chromote.timeout = 120)

    sf <- system.file(package = "igvShiny", "demos", "igvShinyDemo-GFF3.R")
    app <- AppDriver$new(
      app_dir = shiny::shinyAppFile(sf),
      name = "test_app",
      height = 695,
      width = 1235,
      load_timeout = 1e+6,
      timeout = 1e+6
    )
    app$wait_for_value(input = "igvReady")
    Sys.sleep(2)

    .click_and_check(app, "addRemoteGFF3TrackButton", 'title="url gff3"')
    .click_and_check(app, "addRemoteGFF3TrackButtonWithBiotypeColors", 'title="url gff3 (colors)"')
    .click_and_check(app, "addLocalGFF3TrackButtonWithBiotypeColors", 'title="local gff3 (colors)"')

    app$stop()
})

