library(testthat)

# S4 track classes ported from igvR, their payload builders (.trackPayload)
# and the loadTrack() sender. Builders run without a session; loadTrack runs
# against fake_session() and is compared with the data.frame loaders.

TRACKS_ELEMENT_ID <- "igvShiny_tracks"

tracks_bed_tbl <- function() {
  data.frame(
    chrom = c("chr1", "chr1", "chr1"),
    start = c(7432, 7561, 7300),
    end = c(7503, 7580, 7350),
    value = c(0.5, 0.9, 0.1),
    stringsAsFactors = FALSE
  )
}

tracks_gr <- function(...) {
  GenomicRanges::GRanges(
    c("chr1:101-200", "chr1:301-400", "chr2:11-20"),
    strand = c("+", "*", "-"),
    ...
  )
}

tracks_read_bed <- function(path) {
  utils::read.table(path, sep = "\t", header = FALSE,
                    stringsAsFactors = FALSE, comment.char = "")
}

test_that("Track() validates its arguments and resolves a random color", {
  track <- Track(trackType = "annotation", sourceType = "file",
                 fileFormat = "bed", trackName = "t", color = "random")
  expect_s4_class(track, "Track")
  expect_true(track@color %in% igvShiny:::randomColors)

  expect_error(Track(trackName = ""))
  expect_error(Track(trackName = "t", trackType = "nonsense"))
  expect_error(Track(trackName = "t", height = 0))
})

test_that("trackInfo and trackSize describe a track", {
  track <- DataFrameAnnotationTrack("df", tracks_bed_tbl())
  info <- trackInfo(track)
  expect_identical(info$trackType, "annotation")
  expect_identical(info$fileFormat, "bed")
  expect_identical(info$source, "file")
  expect_identical(info$class, "DataFrameAnnotationTrack")
  expect_identical(trackSize(track), 3L)

  expect_identical(trackSize(GRangesQuantitativeTrack("gr",
                                                      tracks_gr(v = 1:3))),
                   3L)
  expect_identical(trackSize(QuantitativeTrack("q")), NA_integer_)
})

test_that("annotation constructors keep igvR's defaults and reject bad input", {
  track <- DataFrameAnnotationTrack("df", tracks_bed_tbl())
  expect_s4_class(track, "igvAnnotationTrack")
  expect_identical(track@color, "")
  expect_identical(track@displayMode, "SQUISHED")
  expect_identical(track@height, 50)
  expect_identical(track@classTypeOfSuppliedObject, "data.frame")

  gtrack <- GRangesAnnotationTrack("gr", tracks_gr())
  expect_identical(gtrack@color, "darkGrey")

  expect_error(DataFrameAnnotationTrack("df", as.matrix(tracks_bed_tbl())))
  expect_error(DataFrameAnnotationTrack("df", tracks_bed_tbl(),
                                        displayMode = "squished"))
  expect_error(GRangesAnnotationTrack("gr", tracks_bed_tbl()))
})

test_that("quantitative constructors reject tables that are not bedGraph", {
  tbl <- tracks_bed_tbl()
  track <- DataFrameQuantitativeTrack("q", tbl, autoscale = FALSE,
                                      min = 0, max = 2)
  expect_s4_class(track, "QuantitativeTrack")
  expect_false(track@autoscale)

  tbl$value <- as.character(tbl$value)
  expect_error(DataFrameQuantitativeTrack("q", tbl, autoscale = TRUE))
  expect_error(DataFrameQuantitativeTrack("q", tbl[, c(1, 2, 3)],
                                          autoscale = TRUE))
  expect_error(GRangesQuantitativeTrack("q", tracks_bed_tbl()))
})

test_that("a DataFrameAnnotationTrack builds the payload loadBedTrack builds", {
  tbl <- tracks_bed_tbl()
  track <- DataFrameAnnotationTrack("df", tbl, color = "blue",
                                    trackHeight = 77)
  path <- tempfile(fileext = ".bed")
  expected_path <- tempfile(fileext = ".bed")
  on.exit(unlink(c(path, expected_path)))

  payload <- igvShiny:::.trackPayload(track, path = path)
  expected <- igvShiny:::.bedTrackPayload(
    "df", tbl, expected_path, color = "blue", trackHeight = 77,
    trackConfig = list(displayMode = "SQUISHED", expandedRowHeight = 30,
                       squishedRowHeight = 15, maxRows = 500,
                       searchable = FALSE, visibilityWindow = 100000)
  )

  expect_named(payload, c("config", "files"))
  expect_identical(payload$files, path)
  expect_identical(payload$config[names(payload$config) != "bedFilepath"],
                   expected$config[names(expected$config) != "bedFilepath"])
  expect_identical(payload$config$bedFilepath,
                   file.path("tracks", basename(path)))
  expect_identical(payload$config$displayMode, "SQUISHED")
  expect_identical(readLines(path), readLines(expected_path))
})

test_that("an annotation track's slots win over trackConfig, which only adds", {
  track <- DataFrameAnnotationTrack("df", tracks_bed_tbl(),
                                    displayMode = "EXPANDED")
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))

  expect_warning(
    payload <- igvShiny:::.trackPayload(
      track, path = path,
      trackConfig = list(displayMode = "COLLAPSED", graphType = "points")
    ),
    "conflict"
  )
  expect_identical(payload$config$displayMode, "EXPANDED")
  expect_identical(payload$config$graphType, "points")
})

test_that("a GRangesAnnotationTrack writes 0-based bed with name and score", {
  track <- GRangesAnnotationTrack("gr", tracks_gr(name = c("a", "b", "c"),
                                                  score = c(1, 2, 3)))
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))

  payload <- igvShiny:::.trackPayload(track, path = path)
  expect_identical(payload$config$color, "darkGrey")

  written <- tracks_read_bed(path)
  expect_identical(NCOL(written), 6L)
  # the builder sorts by start only
  expect_identical(written[[1]], c("chr2", "chr1", "chr1"))
  expect_identical(written[[2]], c(10L, 100L, 300L))
  expect_identical(written[[3]], c(20L, 200L, 400L))
  expect_identical(written[[4]], c("c", "a", "b"))
  expect_identical(written[[6]], c("-", "+", "."))
})

test_that("a GRanges without name or score gets bed placeholders", {
  tbl <- igvShiny:::.trackTable(GRangesAnnotationTrack("gr", tracks_gr()))
  expect_identical(colnames(tbl),
                   c("chr", "start", "end", "name", "score", "strand"))
  expect_identical(tbl$name, rep(".", 3))
  expect_identical(tbl$score, rep(0, 3))
})

test_that("quantitative tracks build the payload loadBedGraphTrack builds", {
  tbl <- tracks_bed_tbl()
  track <- DataFrameQuantitativeTrack("q", tbl, color = "red",
                                      trackHeight = 40, autoscale = FALSE,
                                      min = 0, max = 2)

  payload <- igvShiny:::.trackPayload(track)
  expected <- igvShiny:::.bedGraphTrackPayload(
    "q", tbl, color = "red", trackHeight = 40, autoscale = FALSE,
    min = 0, max = 2, trackConfig = list(visibilityWindow = 100000)
  )
  expect_identical(payload, expected)
  expect_identical(payload$files, character(0))
})

test_that("a GRangesQuantitativeTrack sends 0-based starts and its scores", {
  track <- GRangesQuantitativeTrack("gq", tracks_gr(score = c(0.5, 1, 2)))
  payload <- igvShiny:::.trackPayload(track)

  features <- jsonlite::fromJSON(payload$config$tbl)
  expect_identical(colnames(features), c("chr", "start", "end", "value"))
  expect_identical(features$start, c(10L, 100L, 300L))
  expect_identical(features$value, c(2, 0.5, 1))
  expect_true(payload$config$autoscale)
  expect_identical(payload$config$color, "blue")
})

test_that("a quantitative GRanges needs exactly one numeric metadata column", {
  expect_error(
    igvShiny:::.trackPayload(GRangesQuantitativeTrack("gq", tracks_gr())),
    "exactly one"
  )
  expect_error(
    igvShiny:::.trackPayload(
      GRangesQuantitativeTrack("gq", tracks_gr(a = 1:3, b = 1:3))
    ),
    "exactly one"
  )
  expect_error(
    igvShiny:::.trackPayload(
      GRangesQuantitativeTrack("gq", tracks_gr(a = letters[1:3]))
    ),
    "numeric"
  )
})

test_that("tracks without data have no builder and no loadTrack", {
  session <- fake_session()
  expect_error(igvShiny:::.trackPayload(QuantitativeTrack("q")),
               "no feature table")
  expect_error(loadTrack(session, TRACKS_ELEMENT_ID, QuantitativeTrack("q")),
               "no feature table")
  expect_error(
    loadTrack(session, TRACKS_ELEMENT_ID,
              Track(trackName = "t", fileFormat = "bed")),
    "no method"
  )
  expect_length(sent_messages(session), 0L)
})

test_that("UCSCData tracks build bed and bedGraph payloads", {
  skip_if_not_installed("rtracklayer")

  bed <- methods::new("UCSCData", tracks_gr(name = c("a", "b", "c")))
  track <- UCSCBedAnnotationTrack("ucsc", bed)
  expect_identical(track@coreObject@trackLine@name, "ucsc")
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))
  igvShiny:::.trackPayload(track, path = path)
  expect_identical(tracks_read_bed(path)[[4]], c("c", "a", "b"))

  bedGraph <- methods::new("UCSCData", tracks_gr(score = c(1, 2, 3)))
  qtrack <- UCSCBedGraphQuantitativeTrack("ucscq", bedGraph,
                                          trackHeight = 70)
  payload <- igvShiny:::.trackPayload(qtrack)
  expect_identical(payload$config$trackHeight, 70)
  expect_equal(jsonlite::fromJSON(payload$config$tbl)$value, c(3, 1, 2))

  expect_error(UCSCBedAnnotationTrack("ucsc", tracks_gr()))
  expect_error(methods::new("UCSCBedAnnotationTrack", coreObject = tracks_gr()),
               "UCSCData")
})

test_that("loadTrack sends an annotation track like loadBedTrack does", {
  tbl <- tracks_bed_tbl()
  session <- fake_session()
  loadTrack(session, TRACKS_ELEMENT_ID,
            DataFrameAnnotationTrack("df", tbl, color = "blue",
                                     trackHeight = 77),
            validateReference = FALSE)
  loadBedTrack(session, TRACKS_ELEMENT_ID, "df", tbl, color = "blue",
               trackHeight = 77,
               trackConfig = list(displayMode = "SQUISHED",
                                  expandedRowHeight = 30,
                                  squishedRowHeight = 15, maxRows = 500,
                                  searchable = FALSE,
                                  visibilityWindow = 100000),
               validateReference = FALSE)

  msgs <- sent_messages(session, "loadBedTrackFromFile")
  expect_length(msgs, 2L)
  from_track <- msgs[[1]]$message
  from_loader <- msgs[[2]]$message
  expect_identical(from_track$elementID, TRACKS_ELEMENT_ID)
  expect_identical(from_track[names(from_track) != "bedFilepath"],
                   from_loader[names(from_loader) != "bedFilepath"])
  served <- file.path(get_tracks_dir(), basename(from_track$bedFilepath))
  expect_true(file.exists(served))
  expect_length(sent_messages(session, "removeTracksByName"), 2L)

  # the file is registered for removal when the session ends
  end_session(session)
  expect_false(file.exists(served))
})

test_that("loadTrack sends a quantitative track like loadBedGraphTrack does", {
  tbl <- tracks_bed_tbl()
  session <- fake_session()
  loadTrack(session, TRACKS_ELEMENT_ID,
            DataFrameQuantitativeTrack("q", tbl, color = "red",
                                       trackHeight = 40, autoscale = FALSE,
                                       min = 0, max = 2),
            deleteTracksOfSameName = FALSE, validateReference = FALSE)
  loadBedGraphTrack(session, TRACKS_ELEMENT_ID, "q", tbl, color = "red",
                    trackHeight = 40, autoscale = FALSE, min = 0, max = 2,
                    trackConfig = list(visibilityWindow = 100000),
                    deleteTracksOfSameName = FALSE, validateReference = FALSE)

  msgs <- sent_messages(session, "loadBedGraphTrack")
  expect_length(msgs, 2L)
  expect_identical(msgs[[1]]$message, msgs[[2]]$message)
  expect_length(sent_messages(session, "removeTracksByName"), 0L)
})

test_that("loadTrack passes trackConfig through and fails before sending", {
  session <- fake_session()
  loadTrack(session, TRACKS_ELEMENT_ID,
            GRangesQuantitativeTrack("gq", tracks_gr(score = 1:3)),
            trackConfig = list(graphType = "points"),
            validateReference = FALSE)
  expect_identical(last_message(session, "loadBedGraphTrack")$graphType,
                   "points")

  session <- fake_session()
  expect_error(
    loadTrack(session, TRACKS_ELEMENT_ID,
              GRangesQuantitativeTrack("gq", tracks_gr()),
              validateReference = FALSE),
    "exactly one"
  )
  expect_length(sent_messages(session), 0L)

  track <- DataFrameAnnotationTrack("df", tracks_bed_tbl())
  expect_error(loadTrack(session, 1, track))
})

test_that("annotation trackConfig is sanitized once, as on loadBedTrack", {
  track <- DataFrameAnnotationTrack("df", tracks_bed_tbl())
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))

  # trackHeight conflicts with the builder's argument and is dropped, not
  # silently rewritten to height
  expect_warning(
    payload <- igvShiny:::.trackPayload(track, path = path,
                                        trackConfig = list(trackHeight = 200)),
    "conflict"
  )
  expect_false("height" %in% names(payload$config))
  expect_identical(payload$config$trackHeight, 50)
  expect_identical(payload$config$displayMode, "SQUISHED")

  expect_warning(
    payload <- igvShiny:::.trackPayload(track, path = path,
                                        trackConfig = list(notAnOption = 1)),
    "invalid or unsupported"
  )
  expect_false("notAnOption" %in% names(payload$config))
})

test_that("annotation and quantitative slots reach the track options", {
  track <- DataFrameAnnotationTrack("df", tracks_bed_tbl(),
                                    displayMode = "COLLAPSED",
                                    expandedRowHeight = 31,
                                    squishedRowHeight = 11, maxRows = 7,
                                    searchable = TRUE,
                                    visibilityWindow = 5000)
  session <- fake_session()
  expect_warning(
    loadTrack(session, TRACKS_ELEMENT_ID, track,
              trackConfig = list(maxRows = 2, graphType = "points"),
              validateReference = FALSE),
    "conflict"
  )
  msg <- last_message(session, "loadBedTrackFromFile")
  expect_identical(msg[c("displayMode", "expandedRowHeight",
                         "squishedRowHeight", "maxRows", "searchable",
                         "visibilityWindow")],
                   list(displayMode = "COLLAPSED", expandedRowHeight = 31,
                        squishedRowHeight = 11, maxRows = 7,
                        searchable = TRUE, visibilityWindow = 5000))
  expect_identical(msg$graphType, "points")
  expect_true(all(names(msg) %in% c(igvShiny:::.validIgvTrackOptions,
                                    "elementID", "trackName", "bedFilepath",
                                    "trackHeight")))

  # an NA visibilityWindow is not sent
  quant <- DataFrameQuantitativeTrack("q", tracks_bed_tbl(), autoscale = TRUE,
                                      visibilityWindow = NA_real_)
  loadTrack(session, TRACKS_ELEMENT_ID, quant, validateReference = FALSE)
  expect_false("visibilityWindow" %in%
                 names(last_message(session, "loadBedGraphTrack")))
  quant <- DataFrameQuantitativeTrack("q", tracks_bed_tbl(), autoscale = TRUE,
                                      visibilityWindow = 7000)
  loadTrack(session, TRACKS_ELEMENT_ID, quant, validateReference = FALSE)
  expect_identical(last_message(session, "loadBedGraphTrack")$visibilityWindow,
                   7000)
})

test_that("igv.js receives the annotation slots in the browser stub", {
  skip_if_not(nzchar(Sys.which("node")), "Node.js not available")
  binding <- system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  harness <- test_path("helper-js-harness.js")
  out <- system2(Sys.which("node"),
                 args = c(shQuote(harness), shQuote(binding),
                          "annotation-slots"),
                 stdout = TRUE)
  configs <- jsonlite::fromJSON(paste(out, collapse = "\n"),
                                simplifyVector = FALSE)$annotationSlots
  expect_length(configs, 3L)
  slots <- configs[[1]]
  expect_identical(slots$name, "slots")
  # COLLAPSED in, COLLAPSED out
  expect_identical(slots$displayMode, "COLLAPSED")
  expect_identical(slots$expandedRowHeight, 31L)
  expect_identical(slots$squishedRowHeight, 11L)
  expect_identical(slots$maxRows, 7L)
  expect_true(slots$searchable)
  expect_identical(slots$visibilityWindow, 5000L)
  expect_identical(slots$url, "http://127.0.0.1:1234/tracks/a.bed")
  # no displayMode sent: the bed handler keeps its EXPANDED default
  expect_identical(configs[[2]]$displayMode, "EXPANDED")
  expect_null(configs[[2]]$maxRows)
  expect_identical(configs[[3]]$visibilityWindow, 7000L)
})

test_that("a BED12 GRanges keeps its exon structure on disk", {
  skip_if_not_installed("rtracklayer")
  src <- tempfile(fileext = ".bed")
  writeLines(paste("chr1", 100, 300, "gene", 0, "+", 120, 280,
                   "255,0,0", 2, "50,50", "0,150", sep = "\t"), src)
  gr <- rtracklayer::import(src, format = "bed")

  out <- tempfile(fileext = ".bed")
  igvShiny:::.trackPayload(GRangesAnnotationTrack("gene", gr), path = out)
  expect_identical(readLines(out), readLines(src))
})

test_that("a GRanges without BED12 columns still writes six columns", {
  out <- tempfile(fileext = ".bed")
  igvShiny:::.trackPayload(GRangesAnnotationTrack("g", tracks_gr()),
                           path = out)
  expect_identical(NCOL(tracks_read_bed(out)), 6L)
})
