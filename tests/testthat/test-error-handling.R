test_that("igv.createBrowser has .catch handler and emits igvError", {
  binding <- system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  expect_true(file.exists(binding))
  js <- paste(readLines(binding, warn = FALSE), collapse = "\n")

  # createBrowser must not leave unhandled promise rejections on network/host outages (#182)
  expect_match(js, "igv.createBrowser(igvDiv, fullOptions)", fixed = TRUE)
  expect_match(js, ".catch(function (error)", fixed = TRUE)
  expect_match(js, "igvshiny-error-banner", fixed = TRUE)
  expect_match(js, 'Shiny.setInputValue("igvError"', fixed = TRUE)
  expect_match(js, 'moduleNamespace(options.moduleNS, "igvError")', fixed = TRUE)
})

test_that("showcase demo defines offline mode using bundled sarsGenome", {
  demo_file <- system.file("showcase", "igvShinyDemo.R", package = "igvShiny")
  expect_true(file.exists(demo_file))
  demo_code <- paste(readLines(demo_file, warn = FALSE), collapse = "\n")

  expect_match(demo_code, 'checkboxInput("offlineMode"', fixed = TRUE)
  expect_match(demo_code, 'observeEvent(input$igvError', fixed = TRUE)
  expect_match(demo_code, "sarsGenome", fixed = TRUE)
})
