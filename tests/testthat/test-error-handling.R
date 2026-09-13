test_that("igv.createBrowser has .catch handler, cleans shadowRoot, and emits igvError", {
  # Read from source tree if running in development, or installed package
  src_binding <- file.path("..", "..", "inst", "htmlwidgets", "igvShiny.js")
  binding <- if (file.exists(src_binding)) src_binding else system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  expect_true(file.exists(binding))
  js <- paste(readLines(binding, warn = FALSE), collapse = "\n")

  # createBrowser must not leave unhandled promise rejections on network/host outages (#182)
  expect_match(js, "igv.createBrowser(el, fullOptions)", fixed = TRUE)
  expect_match(js, ".catch(function (error)", fixed = TRUE)
  expect_match(js, "igvshiny-error-banner", fixed = TRUE)
  expect_match(js, 'Shiny.setInputValue("igvError"', fixed = TRUE)
  expect_match(js, 'moduleNamespace(options.moduleNS, "igvError")', fixed = TRUE)

  # Teardown & shadowRoot cleanup to prevent stacked duplicate viewers
  expect_match(js, "igv.removeBrowser(igvWidget)", fixed = TRUE)
  expect_match(js, "el.shadowRoot", fixed = TRUE)
  expect_match(js, "currentRenderId", fixed = TRUE)
  expect_match(js, "renderId !== currentRenderId", fixed = TRUE)
})

test_that("showcase demo defines offline mode using bundled sarsGenome", {
  src_demo <- file.path("..", "..", "inst", "showcase", "igvShinyDemo.R")
  demo_file <- if (file.exists(src_demo)) src_demo else system.file("showcase", "igvShinyDemo.R", package = "igvShiny")
  expect_true(file.exists(demo_file))
  demo_code <- paste(readLines(demo_file, warn = FALSE), collapse = "\n")

  expect_match(demo_code, 'checkboxInput("offlineMode"', fixed = TRUE)
  expect_match(demo_code, 'observeEvent(input$igvError', fixed = TRUE)
  expect_match(demo_code, "sarsGenome", fixed = TRUE)
})
