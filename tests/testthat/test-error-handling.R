test_that("igv.createBrowser has .catch handler, cleans shadowRoot, and emits igvError", {
  # Read from source tree if running in development, or installed package
  src_binding <- file.path("..", "..", "inst", "htmlwidgets", "igvShiny.js")
  binding <- if (file.exists(src_binding)) {
    src_binding
  } else {
    system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  }
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
  expect_match(demo_code, "observeEvent(input$igvError", fixed = TRUE)
  expect_match(demo_code, "sarsGenome", fixed = TRUE)
})

test_that("widget runtime handles re-render, error banner escaping, and queue lifecycle in Node (#189)", {
  skip_if_not(nzchar(Sys.which("node")), "Node.js not available")

  src_binding <- file.path("..", "..", "inst", "htmlwidgets", "igvShiny.js")
  binding <- if (file.exists(src_binding)) {
    src_binding
  } else {
    system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  }
  expect_true(file.exists(binding))

  src_harness <- file.path("helper-js-harness.js")
  harness <- if (file.exists(src_harness)) {
    src_harness
  } else if (file.exists(file.path("tests", "testthat", "helper-js-harness.js"))) {
    file.path("tests", "testthat", "helper-js-harness.js")
  } else {
    file.path("..", "..", "tests", "testthat", "helper-js-harness.js")
  }
  expect_true(file.exists(harness))

  out <- system2(Sys.which("node"), args = c(shQuote(harness), shQuote(binding)), stdout = TRUE, stderr = FALSE)
  json_str <- paste(out, collapse = "\n")
  res <- jsonlite::fromJSON(json_str)

  # 1. Stale render disposal
  expect_equal(res$staleRender$removed, "a")
  expect_equal(res$staleRender$activeBrowser, "b")

  # 2. Re-render drops superseded queued calls, keeps current (#189 finding 1)
  expect_equal(res$queueRerender$loaded, "mm10:forMm10")

  # 3. Failed createBrowser drops calls immediately without zombie queuing (#189 finding 2)
  expect_equal(res$queueFail$pendingAfterFail, 0)
  expect_equal(length(res$queueFail$loaded), 0)

  # 4. Early startup message is preserved and flushed on first render (#185 non-regression)
  expect_equal(res$queueStartup$loaded, "ribo:earlyStartup")

  # Pending results belong to an element instance, not only its output ID.
  expect_equal(res$staleRejection$status, "ready")
  expect_equal(res$staleRejection$activeBrowser, "mm10")
  expect_equal(res$staleRejection$loaded, "mm10:afterOldError")
  expect_false(res$staleRejection$hasBanner)
  expect_length(res$staleRejection$errorEvents, 0)
  expect_equal(NROW(res$widgetReplacement), 4L)
  for (i in seq_len(NROW(res$widgetReplacement))) {
    replacement <- res$widgetReplacement[i, ]
    expect_equal(replacement$status, "ready")
    expect_equal(replacement$activeBrowser, "mm10")
    expect_equal(replacement$loaded[[1]],
                 c("mm10:replacementStartup", "mm10:forMm10", "mm10:afterOld"))
    expect_equal(replacement$removed[[1]],
                 if (replacement$outcome == "resolve") "hg38" else character())
    expect_false(replacement$hasBanner)
    expect_equal(replacement$readyEvents[[1]], rep("replacement", 2))
    expect_length(replacement$errorEvents[[1]], 0)
  }
  expect_equal(res$startupWithoutContainer$loaded, "ribo:beforeContainer")

  # 5. Error banner escaping and event emission (#189 finding 4)
  expect_true(res$bannerEscaping$hasBanner)
  expect_false(grepl("<script>", res$bannerEscaping$templateHTML, fixed = TRUE))
  expect_false(grepl("<img", res$bannerEscaping$templateHTML, fixed = TRUE))
  expect_equal(res$bannerEscaping$genomeText, "<script>alert('genome')</script>")
  expect_equal(res$bannerEscaping$detailText, "<img src=x onerror=alert('err')>")
  expect_true(length(res$bannerEscaping$errorEvents) >= 1)
})
