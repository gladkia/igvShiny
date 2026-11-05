library(testthat)

# loadTrack(session, id, <list>) loads a plain igv.js track config (#111)

bigbed_config <- function() {
  list(name = "genes", type = "annotation", format = "bigBed",
       url = "https://example.org/genes.bb")
}

test_that(".configListTrackPayload passes a valid config through", {
  payload <- igvShiny:::.configListTrackPayload(bigbed_config())
  expect_identical(payload$config, bigbed_config())
  expect_identical(payload$files, character(0))
})

test_that(".configListTrackPayload drops keys igv.js does not read", {
  config <- c(bigbed_config(), list(bogus = 1, height = 40))
  expect_warning(payload <- igvShiny:::.configListTrackPayload(config),
                 "bogus")
  expect_identical(payload$config, c(bigbed_config(), list(height = 40)))
})

test_that(".configListTrackPayload maps the index and trackHeight aliases", {
  config <- list(name = "bam", format = "bam", url = "a.bam",
                 index = "a.bai", trackHeight = 70)
  payload <- igvShiny:::.configListTrackPayload(config)
  expect_identical(payload$config$indexURL, "a.bai")
  expect_identical(payload$config$height, 70)
  expect_false(any(c("index", "trackHeight") %in% names(payload$config)))
})

test_that(".configListTrackPayload requires name, url and type or format", {
  build <- igvShiny:::.configListTrackPayload
  cfg <- bigbed_config()
  expect_error(build(list()))
  expect_error(build(unname(cfg)))
  expect_error(build(cfg[setdiff(names(cfg), "name")]), "track\\$name")
  expect_error(build(cfg[setdiff(names(cfg), "url")]), "track\\$url")
  expect_error(build(c(cfg, list(url = "b.bb"))))
  no_kind <- cfg[setdiff(names(cfg), c("type", "format"))]
  expect_error(build(no_kind), "type or track\\$format")
  # a bad type is rejected even next to a valid format
  expect_error(build(c(no_kind, list(type = c("variant", "bed"),
                                     format = "vcf"))), "track\\$type")
  expect_error(build(c(no_kind, list(type = NA_character_,
                                     format = "vcf"))), "track\\$type")
  expect_error(build(c(no_kind, list(type = "variant",
                                     format = ""))), "track\\$format")
  expect_identical(build(c(no_kind, list(format = "bigBed")))$config$format,
                   "bigBed")
  expect_error(build(c(cfg[setdiff(names(cfg), "url")], list(url = 1))))
})

test_that("loadTrack sends a config list to the loadTrackConfig handler", {
  session <- fake_session()
  loadTrack(session, "igvShiny_0", bigbed_config())
  types <- vapply(sent_messages(session), `[[`, character(1), "type")
  expect_identical(types, c("removeTracksByName", "loadTrackConfig"))
  msg <- last_message(session, "loadTrackConfig")
  expect_identical(msg, c(list(elementID = "igvShiny_0"), bigbed_config()))

  loadTrack(session, "igvShiny_0", bigbed_config(),
            deleteTracksOfSameName = FALSE)
  expect_length(sent_messages(session, "removeTracksByName"), 1L)
  end_session(session)
})

test_that("a bad config list removes no track and sends nothing", {
  session <- fake_session()
  expect_error(loadTrack(session, "igvShiny_0", list(name = "genes")))
  expect_length(sent_messages(session), 0L)
  end_session(session)
})

test_that("the loadTrackConfig handler hands the config to igv.js", {
  skip_if_not(nzchar(Sys.which("node")), "Node.js not available")
  binding <- system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  harness <- test_path("helper-js-harness.js")
  out <- system2(Sys.which("node"),
                 args = c(shQuote(harness), shQuote(binding), "track-config"),
                 stdout = TRUE)
  configs <- jsonlite::fromJSON(paste(out, collapse = "\n"),
                                simplifyVector = FALSE)$trackConfig
  expect_length(configs, 2L)
  expect_identical(configs[[1]]$format, "bigBed")
  expect_identical(configs[[1]]$url, "https://example.org/a.bb")
  expect_false("elementID" %in% names(configs[[1]]))
  # a missing order is filled in, a given one is kept
  expect_gt(configs[[1]]$order, 1e300)
  expect_identical(configs[[2]]$order, 3L)
})

test_that("loadTrack ignores trackConfig for a config list", {
  session <- fake_session()
  logged <- utils::capture.output(
    loadTrack(session, "igvShiny_0", bigbed_config(),
              trackConfig = list(color = "red"), validateReference = FALSE)
  )
  expect_true(any(grepl("trackConfig is ignored", logged)))
  msg <- last_message(session, "loadTrackConfig")
  expect_identical(msg, c(list(elementID = "igvShiny_0"), bigbed_config()))
  end_session(session)
})
