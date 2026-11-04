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

# ---- stage 2: the remaining loaders ------------------------------------------

payload_junction_tbl <- function() {
  data.frame(
    chrom = c("chr1", "chr1"),
    start = c(100, 300),
    end = c(200, 400),
    motif = c("GT/AG", "CT/AC"),
    uniquely_mapped = c(12, 3),
    annotated_junction = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )
}

payload_gff3_tbl <- function() {
  f <- system.file(package = "igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
  utils::read.table(f, sep = "\t", header = FALSE, comment.char = "#",
                    quote = "", nrows = 20, stringsAsFactors = FALSE)
}

# Drop the key that carries a freshly drawn file name, so two payloads built
# from the same input compare equal.
without_key <- function(config, key) {
  config[setdiff(names(config), key)]
}

test_that(".segTrackPayload inlines the table as JSON", {
  tbl <- data.frame(chr = "chr1", start = 100, end = 200, value = 0.3,
                    stringsAsFactors = FALSE)
  payload <- igvShiny:::.segTrackPayload("seg", tbl)

  expect_named(payload, c("config", "files"))
  expect_identical(payload$files, character(0))
  expect_named(payload$config, c("trackName", "tbl"))
  expect_equal(jsonlite::fromJSON(payload$config$tbl), tbl)
  expect_error(igvShiny:::.segTrackPayload("seg", as.matrix(tbl)))
})

test_that(".segTrackPayload merges trackConfig onto the defaults", {
  tbl <- data.frame(chr = "chr1", start = 1, end = 2, value = 1)
  payload <- igvShiny:::.segTrackPayload(
    "seg", tbl, trackConfig = list(posColorScale = list(min = 0, max = 1))
  )
  expect_identical(names(payload$config),
                   c("trackName", "tbl", "posColorScale"))
})

test_that(".vcfTrackPayload writes the vcf to the given path", {
  skip_if_not_installed("VariantAnnotation")
  f <- system.file(package = "igvShiny", "extdata", "chr19-cebpaRegion.vcf.gz")
  vcf <- VariantAnnotation::readVcf(f)
  path <- tempfile(fileext = ".vcf")
  on.exit(unlink(path))

  payload <- igvShiny:::.vcfTrackPayload("vcf", vcf, path,
                                         trackConfig = list(height = 80))
  expect_identical(payload$files, path)
  expect_true(file.exists(path))
  expect_identical(payload$config,
                   list(trackName = "vcf",
                        vcfDataFilepath = file.path("tracks", basename(path)),
                        height = 80))
  expect_error(igvShiny:::.vcfTrackPayload("vcf", data.frame(), path))
})

test_that(".gwasTrackPayload writes the table with its header", {
  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))
  path <- tempfile(fileext = ".gwas")
  on.exit(unlink(path))

  payload <- igvShiny:::.gwasTrackPayload("gwas", tbl.gwas, path,
                                          ymin = 2, ymax = 12)
  expect_identical(payload$files, path)
  expect_identical(payload$config,
                   list(trackName = "gwas",
                        gwasDataFilepath = file.path("tracks", basename(path)),
                        color = "red", trackHeight = 200, autoscale = FALSE,
                        min = 2, max = 12))
  written <- utils::read.table(path, sep = "\t", header = TRUE, quote = "")
  expect_identical(colnames(written), colnames(tbl.gwas))
  expect_identical(NROW(written), NROW(tbl.gwas))
})

test_that(".gwasTrackPayload keeps its defaults over trackConfig", {
  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  path <- tempfile(fileext = ".gwas")
  on.exit(unlink(path))
  columns <- list(chromosome = 3, position = 4, value = 10)
  expect_warning(
    payload <- igvShiny:::.gwasTrackPayload(
      "gwas", get(load(f)), path,
      trackConfig = list(color = "blue", columns = columns)
    ),
    "conflict"
  )
  expect_identical(payload$config$color, "red")
  expect_identical(payload$config$columns, columns)
})

test_that(".bamUrlTrackPayload sends the urls and leaves out unset keys", {
  payload <- igvShiny:::.bamUrlTrackPayload("bam", "https://example.org/a.bam",
                                            "https://example.org/a.bam.bai")
  expect_identical(payload$files, character(0))
  expect_identical(payload$config,
                   list(trackName = "bam",
                        bam = "https://example.org/a.bam",
                        index = "https://example.org/a.bam.bai",
                        displayMode = "EXPANDED",
                        showAllBases = FALSE))

  payload <- igvShiny:::.bamUrlTrackPayload("bam", "a.bam", "a.bai",
                                            showAllBases = NULL,
                                            trackHeight = 120)
  expect_identical(names(payload$config),
                   c("trackName", "bam", "index", "displayMode", "height"))
  expect_identical(payload$config$height, 120)

  expect_error(igvShiny:::.bamUrlTrackPayload("bam", "a.bam", "a.bai",
                                              trackHeight = 0))
  expect_error(igvShiny:::.bamUrlTrackPayload("bam", NULL, "a.bai"))
})

test_that(".bamLocalDataTrackPayload exports a bam and its index", {
  skip_if_not_installed("GenomicAlignments")
  skip_if_not_installed("Rsamtools")
  skip_if_not_installed("rtracklayer")
  f <- system.file(package = "igvShiny", "extdata", "tumor.bam")
  ga <- GenomicAlignments::readGAlignments(f, use.names = TRUE)
  path <- tempfile(fileext = ".bam")
  on.exit(unlink(c(path, paste0(path, ".bai"))))

  payload <- igvShiny:::.bamLocalDataTrackPayload("local bam", ga, path,
                                                  displayMode = "SQUISHED",
                                                  trackHeight = 90)
  expect_identical(payload$files, c(path, paste0(path, ".bai")))
  expect_true(file.exists(path))
  expect_identical(payload$config,
                   list(trackName = "local bam",
                        bamDataFilepath = file.path("tracks", basename(path)),
                        displayMode = "SQUISHED",
                        height = 90))
})

test_that(".cramUrlTrackPayload sends the urls and an optional height", {
  payload <- igvShiny:::.cramUrlTrackPayload("cram", "a.cram", "a.crai")
  expect_identical(payload$files, character(0))
  expect_identical(payload$config,
                   list(trackName = "cram", cram = "a.cram", index = "a.crai"))

  sort <- list(option = "BASE")
  payload <- igvShiny:::.cramUrlTrackPayload("cram", "a.cram", "a.crai",
                                             trackHeight = 70,
                                             trackConfig = list(sort = sort))
  expect_identical(names(payload$config),
                   c("trackName", "cram", "index", "height", "sort"))
})

test_that(".gff3UrlTrackPayload forwards the colour and window settings", {
  payload <- igvShiny:::.gff3UrlTrackPayload(
    "gff3", "https://example.org/x.gff3", "https://example.org/x.gff3.tbi",
    colorTable = list(exon = "red"), colorByAttribute = "biotype",
    displayMode = "EXPANDED", visibilityWindow = 5000
  )
  expect_identical(payload$files, character(0))
  expect_identical(
    names(payload$config),
    c("trackName", "dataURL", "indexURL", "color", "colorTable",
      "colorByAttribute", "displayMode", "trackHeight", "visibilityWindow")
  )
  expect_identical(payload$config$color, "gray")
  expect_identical(payload$config$trackHeight, 50)
  # like the loader, the builder has no default for these
  expect_error(igvShiny:::.gff3UrlTrackPayload("gff3", "x.gff3", "x.tbi"))
})

test_that(".gff3TrackPayload writes the table to the given path", {
  path <- tempfile(fileext = ".gff3")
  on.exit(unlink(path))
  tbl <- payload_gff3_tbl()
  payload <- igvShiny:::.gff3TrackPayload(
    "gff3", tbl, path, colorTable = list(exon = "red"),
    colorByAttribute = "biotype", displayMode = "EXPANDED",
    visibilityWindow = 5000
  )
  expect_identical(payload$files, path)
  expect_identical(payload$config$filePath,
                   file.path("tracks", basename(path)))
  expect_identical(NROW(readLines(path)), NROW(tbl) + 1L)
  expect_error(igvShiny:::.gff3TrackPayload("gff3", "not a table", path,
                                            colorTable = list(),
                                            colorByAttribute = "",
                                            displayMode = "EXPANDED",
                                            visibilityWindow = 1))
})

test_that(".spliceJunctionUrlTrackPayload replaces an unusable indexURL", {
  payload <- igvShiny:::.spliceJunctionUrlTrackPayload("sj", "x.bed")
  expect_identical(payload$files, character(0))
  expect_identical(payload$config,
                   list(trackName = "sj", url = "x.bed", indexURL = "",
                        trackHeight = 100, displayMode = "COLLAPSED"))

  expect_warning(
    payload <- igvShiny:::.spliceJunctionUrlTrackPayload(
      "sj", "x.bed", indexURL = c("a", "b")
    ),
    "single character string"
  )
  expect_identical(payload$config$indexURL, "")
  payload <- igvShiny:::.spliceJunctionUrlTrackPayload("sj", "x.bed",
                                                       indexURL = NULL)
  expect_identical(payload$config$indexURL, "")
})

test_that(".spliceJunctionTrackPayload writes a six-column junction bed", {
  path <- tempfile(fileext = ".bed")
  on.exit(unlink(path))
  payload <- igvShiny:::.spliceJunctionTrackPayload(
    "sj", payload_junction_tbl(), path,
    trackConfig = list(minTotalReads = 5)
  )
  expect_identical(payload$files, path)
  expect_identical(payload$config$url, file.path("tracks", basename(path)))
  expect_identical(payload$config$indexURL, "")
  expect_identical(payload$config$minTotalReads, 5)

  bed <- utils::read.table(path, sep = "\t", header = FALSE, quote = "")
  expect_identical(NCOL(bed), 6L)
  expect_identical(bed[[5]], c(12L, 3L))
  expect_match(bed[[4]][2], "annotated_junction=false", fixed = TRUE)
})

test_that(".spliceJunctionTrackPayload rejects a table without chr/start/end", {
  path <- tempfile(fileext = ".bed")
  tbl <- data.frame(a = "chr1", b = 1, c = 2, stringsAsFactors = FALSE)
  expect_error(igvShiny:::.spliceJunctionTrackPayload("sj", tbl, path),
               "improper columns")
  expect_false(file.exists(path))
})

test_that("stage 2 senders put builder output on the wire unchanged", {
  session <- fake_session()
  id <- "igvShiny_0"

  seg <- data.frame(chr = "chr1", start = 1, end = 2, value = 1)
  loadSegTrack(session, id, "seg", seg)
  msg <- last_message(session, "loadSegTrack")
  expected <- igvShiny:::.segTrackPayload("seg", seg)$config
  expect_identical(msg, c(list(elementID = id), expected))

  loadBamTrackFromURL(session, id, "bam", "a.bam", "a.bai", trackHeight = 50)
  msg <- last_message(session, "loadBamTrackFromURL")
  expected <- igvShiny:::.bamUrlTrackPayload("bam", "a.bam", "a.bai",
                                             trackHeight = 50)$config
  expect_identical(msg, c(list(elementID = id), expected))

  loadCramTrackFromURL(session, id, "cram", "a.cram", "a.crai")
  msg <- last_message(session, "loadCramTrackFromURL")
  expected <- igvShiny:::.cramUrlTrackPayload("cram", "a.cram", "a.crai")$config
  expect_identical(msg, c(list(elementID = id), expected))

  loadGFF3TrackFromURL(session, id, "gff3", "x.gff3", "x.tbi",
                       colorTable = list(), colorByAttribute = "biotype",
                       displayMode = "EXPANDED", visibilityWindow = 10)
  msg <- last_message(session, "loadGFF3TrackFromURL")
  expected <- igvShiny:::.gff3UrlTrackPayload(
    "gff3", "x.gff3", "x.tbi", colorTable = list(),
    colorByAttribute = "biotype", displayMode = "EXPANDED",
    visibilityWindow = 10
  )$config
  expect_identical(msg, c(list(elementID = id), expected))

  loadSpliceJunctionTrackFromURL(session, id, "sj", "x.bed")
  msg <- last_message(session, "loadSpliceJunctionTrackFromURL")
  expected <- igvShiny:::.spliceJunctionUrlTrackPayload("sj", "x.bed")$config
  expect_identical(msg, c(list(elementID = id), expected))
  end_session(session)
})

test_that("stage 2 file-writing senders match their builders", {
  session <- fake_session()
  id <- "igvShiny_0"
  scratch <- tempfile(fileext = ".tmp")
  on.exit(unlink(scratch))

  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))
  loadGwasTrack(session, id, "gwas", tbl.gwas, ymin = 1, ymax = 9)
  msg <- last_message(session, "loadGwasTrack")
  expected <- igvShiny:::.gwasTrackPayload("gwas", tbl.gwas, scratch,
                                           ymin = 1, ymax = 9)$config
  expect_identical(names(msg), c("elementID", names(expected)))
  expect_identical(without_key(msg[-1], "gwasDataFilepath"),
                   without_key(expected, "gwasDataFilepath"))

  loadGFF3TrackFromLocalData(session, id, "gff3", payload_gff3_tbl(),
                             colorTable = list(), colorByAttribute = "biotype",
                             displayMode = "EXPANDED", visibilityWindow = 10)
  msg <- last_message(session, "loadGFF3TrackFromLocalData")
  expected <- igvShiny:::.gff3TrackPayload(
    "gff3", payload_gff3_tbl(), scratch, colorTable = list(),
    colorByAttribute = "biotype", displayMode = "EXPANDED",
    visibilityWindow = 10
  )$config
  expect_identical(names(msg), c("elementID", names(expected)))
  expect_identical(without_key(msg[-1], "filePath"),
                   without_key(expected, "filePath"))

  loadSpliceJunctionTrackFromLocalData(session, id, "sj",
                                       payload_junction_tbl())
  msg <- last_message(session, "loadSpliceJunctionTrackFromURL")
  expected <- igvShiny:::.spliceJunctionTrackPayload(
    "sj", payload_junction_tbl(), scratch
  )$config
  expect_identical(names(msg), c("elementID", names(expected)))
  expect_identical(without_key(msg[-1], "url"), without_key(expected, "url"))
  expect_identical(readLines(file.path(get_tracks_dir(), basename(msg$url))),
                   readLines(scratch))
  end_session(session)
})

test_that("local bam and cram senders reuse the url builders", {
  session <- fake_session()
  id <- "igvShiny_0"
  bam <- system.file(package = "igvShiny", "extdata", "tumor.bam")
  loadBamTrackFromLocalFile(session, id, "bam", bam, validateReference = FALSE)
  msg <- last_message(session, "loadBamTrackFromURL")
  # the local-file loader has never sent showAllBases
  expect_identical(names(msg),
                   c("elementID", "trackName", "bam", "index", "displayMode"))

  cram <- tempfile(fileext = ".cram")
  writeBin(charToRaw("CRAM"), cram)
  writeBin(charToRaw("CRAI"), paste0(cram, ".crai"))
  on.exit(unlink(c(cram, paste0(cram, ".crai"))))
  loadCramTrackFromLocalData(session, id, "cram", cram, trackHeight = 60,
                             validateReference = FALSE)
  msg <- last_message(session, "loadCramTrackFromURL")
  expected <- igvShiny:::.cramUrlTrackPayload("cram", msg$cram, msg$index,
                                              trackHeight = 60)$config
  expect_identical(msg, c(list(elementID = id), expected))
  end_session(session)
})
