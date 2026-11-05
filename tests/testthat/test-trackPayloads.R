library(testthat)

# Payload builders are the browser-free half of each track loader: they turn
# their input into list(config, files) and touch no session. These tests call
# them directly; test-loadTracks.R checks that the senders still put the same
# payload on the wire.

payload_bed_tbl <- function() {
  data.frame(
    chrom = c("chr1", "chr1", "chr1"),
    start = c(7432, 7561, 7300),
    end = c(7503, 7580, 7350),
    value = c(0.5, 0.9, 0.1),
    stringsAsFactors = FALSE
  )
}

test_that(".bedTrackPayload writes a sorted headerless bed to the given path", {
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))

  payload <- igvShiny:::.bedTrackPayload("bed", payload_bed_tbl(), path,
                                         color = "blue", trackHeight = 77)

  expect_named(payload, c("config", "files"))
  expect_identical(payload$files, path)
  expect_identical(payload$config$trackName, "bed")
  expect_identical(payload$config$bedFilepath,
                   file.path("tracks", basename(path)))
  expect_identical(payload$config$color, "blue")
  expect_identical(payload$config$trackHeight, 77)
  expect_false("elementID" %in% names(payload$config))

  written <- utils::read.table(path, sep = "\t", header = FALSE)
  expect_identical(NROW(written), 3L)
  expect_identical(written[[2]], c(7300L, 7432L, 7561L))
})

test_that(".bedTrackPayload merges trackConfig onto the defaults", {
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))

  expect_warning(
    payload <- igvShiny:::.bedTrackPayload(
      "bed", payload_bed_tbl(), path,
      trackConfig = list(displayMode = "SQUISHED", color = "red")
    ),
    "conflict"
  )
  # a default is never replaced by a user option, only added to
  expect_identical(payload$config$color, "")
  expect_identical(payload$config$displayMode, "SQUISHED")
  expect_identical(payload$config$trackHeight, 50)
})

test_that(".bedTrackPayload drops trackConfig keys igv.js does not read", {
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))

  expect_warning(
    payload <- igvShiny:::.bedTrackPayload(
      "bed", payload_bed_tbl(), path, trackConfig = list(notAnOption = 1)
    ),
    "invalid or unsupported"
  )
  expect_false("notAnOption" %in% names(payload$config))
})

test_that(".bedTrackPayload rejects malformed tables before writing", {
  path <- tempfile(fileext = ".bed")
  tbl <- data.frame(a = "chr1", b = 1, c = 2, stringsAsFactors = FALSE)
  expect_error(igvShiny:::.bedTrackPayload("bad", tbl, path),
               "improper columns")
  expect_false(file.exists(path))

  tbl <- payload_bed_tbl()
  tbl$start <- as.character(tbl$start)
  expect_error(igvShiny:::.bedTrackPayload("bad", tbl, path))
  expect_false(file.exists(path))
})

test_that(".bedTrackPayload resolves color = 'random' to a palette color", {
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))
  payload <- igvShiny:::.bedTrackPayload("bed", payload_bed_tbl(), path,
                                         color = "random")
  expect_true(payload$config$color %in% igvShiny:::randomColors)
})

test_that(".bedGraphTrackPayload inlines the sorted features as JSON", {
  payload <- igvShiny:::.bedGraphTrackPayload(
    "bg", payload_bed_tbl(), autoscale = FALSE, min = 0, max = 10,
    autoscaleGroup = 2
  )

  expect_named(payload, c("config", "files"))
  expect_identical(payload$files, character(0))
  expect_false(payload$config$autoscale)
  expect_identical(payload$config$min, 0)
  expect_identical(payload$config$max, 10)
  expect_identical(payload$config$autoscaleGroup, 2)
  expect_identical(payload$config$color, "gray")
  expect_identical(payload$config$trackHeight, 30)

  features <- jsonlite::fromJSON(payload$config$tbl)
  expect_named(features, c("chr", "start", "end", "value"))
  expect_identical(features$start, c(7300L, 7432L, 7561L))
})

test_that(".bedGraphTrackPayload renames the score column to value", {
  tbl <- payload_bed_tbl()
  colnames(tbl)[4] <- "score"
  payload <- igvShiny:::.bedGraphTrackPayload("bg", tbl, autoscale = TRUE)
  expect_true("value" %in% names(jsonlite::fromJSON(payload$config$tbl)))
})

test_that(".bedGraphTrackPayload rejects non-numeric values and short tables", {
  tbl <- payload_bed_tbl()
  tbl$value <- as.character(tbl$value)
  expect_error(igvShiny:::.bedGraphTrackPayload("bg", tbl, autoscale = TRUE))
  expect_error(
    igvShiny:::.bedGraphTrackPayload("bg", tbl[, c(1, 2, 3)], autoscale = TRUE)
  )
})

test_that(".bedGraphTrackPayload merges trackConfig onto the defaults", {
  expect_warning(
    payload <- igvShiny:::.bedGraphTrackPayload(
      "bg", payload_bed_tbl(), autoscale = TRUE,
      trackConfig = list(graphType = "points", trackHeight = 99)
    ),
    "conflict"
  )
  expect_identical(payload$config$graphType, "points")
  # trackHeight is an explicit argument, so the alias cannot override it
  expect_identical(payload$config$trackHeight, 30)
})

test_that(".bedGraphUrlTrackPayload forwards the url and scaling settings", {
  url <- "https://example.org/data.bedGraph"
  payload <- igvShiny:::.bedGraphUrlTrackPayload("remote", url,
                                                 autoscaleGroup = 1)

  expect_identical(payload$files, character(0))
  expect_identical(payload$config$url, url)
  expect_true(payload$config$autoscale)
  expect_identical(payload$config$min, 0)
  expect_identical(payload$config$max, 1)
  expect_identical(payload$config$autoscaleGroup, 1)
  expect_false("elementID" %in% names(payload$config))
})

test_that("senders put builder output on the wire behind the element id", {
  session <- fake_session()
  loadBedGraphTrack(session, "igvShiny_0", "bg", payload_bed_tbl(),
                    autoscale = TRUE, validateReference = FALSE)
  msg <- last_message(session, "loadBedGraphTrack")
  expected <- igvShiny:::.bedGraphTrackPayload("bg", payload_bed_tbl(),
                                               autoscale = TRUE)$config
  expect_identical(names(msg), c("elementID", names(expected)))
  expect_identical(msg[-1], expected)

  url <- "https://example.org/data.bedGraph"
  loadBedGraphTrackFromURL(session, "igvShiny_0", "remote", url)
  msg <- last_message(session, "loadBedGraphTrackFromURL")
  expect_identical(msg[-1],
                   igvShiny:::.bedGraphUrlTrackPayload("remote", url)$config)
})

# Literal key lists, copied from the loaders before the builder/sender split:
# the test above compares a sender with its own builder, so only these catch a
# reordered or renamed key on the wire
test_that("senders keep the pre-split message keys and their order", {
  bg_keys <- c("elementID", "trackName", "tbl", "color", "trackHeight",
               "autoscale", "min", "max", "autoscaleGroup")
  url_keys <- c("elementID", "trackName", "url", "color", "trackHeight",
                "autoscale", "min", "max", "autoscaleGroup")
  bed_keys <- c("elementID", "trackName", "bedFilepath", "color",
                "trackHeight")

  session <- fake_session()
  loadBedTrack(session, "igvShiny_0", "bed", payload_bed_tbl(),
               validateReference = FALSE)
  expect_identical(names(last_message(session, "loadBedTrackFromFile")),
                   bed_keys)

  loadBedGraphTrack(session, "igvShiny_0", "bg", payload_bed_tbl(),
                    autoscale = TRUE, validateReference = FALSE)
  expect_identical(names(last_message(session, "loadBedGraphTrack")), bg_keys)

  loadBedGraphTrackFromURL(session, "igvShiny_0", "remote",
                           "https://example.org/data.bedGraph")
  expect_identical(names(last_message(session, "loadBedGraphTrackFromURL")),
                   url_keys)
  end_session(session)
})
