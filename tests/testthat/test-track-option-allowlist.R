test_that("every allowlisted track option is one igv.js reads", {
  # A name igv.js does not know passes .sanitizeAndMergeOptions, reaches the
  # browser and is ignored there, so nothing warns on either side. The bundled
  # build is a sufficient oracle: a minifier renames local variables but cannot
  # rename property names, which are reached by string. So a whole-identifier
  # hit in the minified file means igv.js reads that name off an object.
  libDir <- system.file("htmlwidgets", "lib", package = "igvShiny")
  bundled <- Sys.glob(file.path(libDir, "igv-*.min.js"))
  expect_length(bundled, 1L)

  # Read the bytes rather than the lines. readLines() has to decide on an
  # encoding, and on a minified bundle that decision goes differently per
  # platform: on Windows it came back short enough that every option looked
  # missing, which reads as 60-odd dead options rather than as a bad read.
  size <- file.size(bundled)
  src <- rawToChar(readBin(bundled, "raw", n = size))
  expect_equal(nchar(src, type = "bytes"), size)

  options <- igvShiny:::.validIgvTrackOptions

  # Substring matching is not enough: "negColor" sits inside "negColorScale"
  # and "autoScaleGroup" inside the internal "autoScaleGroupColorHash", so both
  # would look alive while being read by nothing.
  found <- vapply(options, function(option) {
    pattern <- sprintf("(?<![A-Za-z0-9_$])%s(?![A-Za-z0-9_$])", option)
    grepl(pattern, src, perl = TRUE, useBytes = TRUE)
  }, logical(1))

  expect_equal(options[!found], character(0))
})
