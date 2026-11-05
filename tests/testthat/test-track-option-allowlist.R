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

  # Substring matching is not enough: "negColor" sits inside "negColorScale"
  # and "autoScaleGroup" inside the internal "autoScaleGroupColorHash", so both
  # would look alive while being read by nothing.
  reads <- function(option) {
    pattern <- sprintf("(?<![A-Za-z0-9_$])%s(?![A-Za-z0-9_$])", option)
    grepl(pattern, src, perl = TRUE, useBytes = TRUE)
  }

  options <- c(igvShiny:::.validIgvTrackOptions,
               igvShiny:::.variantTrackOptions)
  found <- vapply(options, reads, logical(1))
  expect_equal(options[!found], character(0))

  # The check above passes just as well when the search is broken and finds
  # everything, so pin some names igv.js 3.8.4 does not read. These are the
  # ones #159 removed, and they are what the search has to be able to reject.
  removed <- c("negColor", "posColor", "autoScaleGroup", "barChart",
               "noStroke", "noFill", "showLabels", "fontStyle", "fontWeight",
               "colorByAttribute", "hideEmptyTracks", "maxPanelHeight",
               "separateBam")
  expect_equal(removed[vapply(removed, reads, logical(1))], character(0))
})

test_that("genotype colors are allowed on variant tracks only", {
  tbl <- data.frame(chrom = "chr1", start = 100, end = 200,
                    stringsAsFactors = FALSE)
  session <- fake_session()
  expect_warning(
    loadBedTrack(session, "igvShiny_0", "bed", tbl,
                 trackConfig = list(homvarColor = "red"),
                 validateReference = FALSE),
    "homvarColor"
  )
  msg <- last_message(session, "loadBedTrackFromFile")
  expect_false("homvarColor" %in% names(msg))
  end_session(session)

  config <- list(name = "v", type = "variant", format = "vcf",
                 url = "https://example.org/a.vcf.gz", homvarColor = "red")
  payload <- igvShiny:::.configListTrackPayload(config)
  expect_identical(payload$config$homvarColor, "red")
  config$type <- "annotation"
  expect_warning(payload <- igvShiny:::.configListTrackPayload(config),
                 "homvarColor")
  expect_false("homvarColor" %in% names(payload$config))

  tracks <- list(list(name = "v", type = "variant", url = "a.vcf.gz",
                      hetvarColor = "blue"),
                 list(name = "b", type = "annotation", url = "a.bed",
                      hetvarColor = "blue"))
  expect_warning(out <- igvShiny:::.sanitizeTracks(tracks), "hetvarColor")
  expect_identical(out[[1]]$hetvarColor, "blue")
  expect_null(out[[2]]$hetvarColor)
})
