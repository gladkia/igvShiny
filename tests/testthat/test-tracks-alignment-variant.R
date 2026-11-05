library(testthat)

# M1 stage 4: the alignment, variant, GFF3 and bedpe Track classes ported
# from igvR, igvAnnotationTrack(), and loadTrack() for igvShiny's GWASTrack.
# Builders run without a session; loadTrack runs against fake_session() and
# is compared with the loader each class maps to.

STAGE4_ID <- "igvShiny_stage4"

stage4_bedpe_tbl <- function() {
  f <- system.file(package = "igvShiny", "extdata", "sixColumn-demo1.bedpe")
  utils::read.table(f, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
}

stage4_gff3_tbl <- function() {
  f <- system.file(package = "igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
  utils::read.table(f, sep = "\t", header = FALSE, quote = "",
                    comment.char = "#", stringsAsFactors = FALSE)
}

stage4_without <- function(msg, key) msg[names(msg) != key]

test_that("igvAnnotationTrack() picks the subclass that fits its input", {
  tbl <- data.frame(chrom = "chr1", start = 1, end = 10,
                    stringsAsFactors = FALSE)
  expect_s4_class(igvAnnotationTrack("df", tbl, color = "red"),
                  "DataFrameAnnotationTrack")
  gr <- GenomicRanges::GRanges("chr1:1-10")
  expect_s4_class(igvAnnotationTrack("gr", gr), "GRangesAnnotationTrack")
  expect_error(igvAnnotationTrack("x", "chr1:1-10"))
})

test_that("url alignment tracks keep their urls and validate them", {
  remote <- RemoteAlignmentTrack("bam", "https://example.org/a.bam",
                                 trackHeight = 80, color = "red")
  expect_s4_class(remote, "Track")
  expect_identical(remote@bamIndex, "https://example.org/a.bam.bai")
  expect_identical(trackInfo(remote)$fileFormat, "bam")
  expect_identical(trackInfo(remote)$source, "url")
  expect_identical(trackSize(remote), NA_integer_)

  cram <- CramTrack("cram", "https://example.org/a.cram",
                    "https://example.org/a.cram.crai")
  expect_identical(trackInfo(cram)$fileFormat, "cram")
  expect_identical(cram@visibilityWindow, 30000)

  expect_error(CramTrack("cram", "https://example.org/a.cram", ""))
  expect_error(RemoteAlignmentTrack("bam", NA_character_))
})

test_that("url alignment builders build what the url loaders build", {
  remote <- RemoteAlignmentTrack("bam", "https://example.org/a.bam",
                                 "https://example.org/a.bai",
                                 trackHeight = 80, color = "red",
                                 visibilityWindow = 5000)
  payload <- igvShiny:::.trackPayload(remote)
  expect_identical(payload$files, character(0))
  expect_identical(payload$config$bam, "https://example.org/a.bam")
  expect_identical(payload$config$index, "https://example.org/a.bai")
  expect_identical(payload$config$height, 80)
  expect_identical(payload$config$color, "red")
  expect_identical(payload$config$visibilityWindow, 5000)

  cram <- CramTrack("cram", "https://example.org/a.cram",
                    "https://example.org/a.crai", color = "blue")
  config <- igvShiny:::.trackPayload(cram)$config
  expect_identical(config$cram, "https://example.org/a.cram")
  expect_identical(config$index, "https://example.org/a.crai")
  expect_identical(config$color, "blue")
})

test_that("loadTrack sends url alignment tracks like the url loaders do", {
  session <- fake_session()
  loadTrack(session, STAGE4_ID,
            RemoteAlignmentTrack("bam", "https://example.org/a.bam",
                                 trackHeight = 80))
  loadBamTrackFromURL(session, STAGE4_ID, "bam", "https://example.org/a.bam",
                      "https://example.org/a.bam.bai", trackHeight = 80,
                      trackConfig = list(color = "gray",
                                         visibilityWindow = 30000))
  msgs <- sent_messages(session, "loadBamTrackFromURL")
  expect_length(msgs, 2L)
  expect_identical(msgs[[1]]$message, msgs[[2]]$message)

  loadTrack(session, STAGE4_ID,
            CramTrack("cram", "https://example.org/a.cram",
                      "https://example.org/a.crai"),
            deleteTracksOfSameName = FALSE,
            trackConfig = list(showCoverage = FALSE))
  msg <- last_message(session, "loadCramTrackFromURL")
  expect_identical(msg$elementID, STAGE4_ID)
  expect_false(msg$showCoverage)
  expect_length(sent_messages(session, "removeTracksByName"), 2L)
})

test_that("a GenomicAlignmentTrack writes a bam and is sent like local data", {
  skip_if_not_installed("GenomicAlignments")
  skip_if_not_installed("Rsamtools")
  skip_if_not_installed("rtracklayer")

  f <- system.file(package = "igvShiny", "extdata", "tumor.bam")
  ga <- GenomicAlignments::readGAlignments(f, use.names = TRUE)
  track <- GenomicAlignmentTrack("reads", ga, trackHeight = 120)
  expect_identical(trackSize(track), length(ga))
  expect_identical(trackInfo(track)$trackType, "genomicAlignment")
  expect_error(GenomicAlignmentTrack("reads", "not alignments"))
  expect_error(methods::new("GenomicAlignmentTrack", alignment = 1),
               "GAlignments")

  path <- tempfile(fileext = ".bam")
  on.exit(unlink(c(path, paste0(path, ".bai"))))
  payload <- igvShiny:::.trackPayload(track, path = path)
  expect_identical(payload$files, c(path, paste0(path, ".bai")))
  expect_true(all(file.exists(payload$files)))
  expect_identical(payload$config$height, 120)
  expect_identical(payload$config$color, "gray")

  session <- fake_session()
  loadTrack(session, STAGE4_ID, track, validateReference = FALSE)
  msg <- last_message(session, "loadBamTrackFromLocalData")
  served <- file.path(get_tracks_dir(), basename(msg$bamDataFilepath))
  expect_true(file.exists(served))
  expect_true(file.exists(paste0(served, ".bai")))
  # the bam and the index rtracklayer wrote next to it go at session end
  end_session(session)
  expect_false(file.exists(served))
  expect_false(file.exists(paste0(served, ".bai")))
})

test_that("a VariantTrack from a VCF is sent like loadVcfTrack, plus colors", {
  skip_if_not_installed("VariantAnnotation")

  f <- system.file(package = "igvShiny", "extdata", "chr19-cebpaRegion.vcf.gz")
  vcf <- VariantAnnotation::readVcf(f)
  track <- VariantTrack("variants", vcf, anchorColor = "red")
  expect_identical(track@anchorColor, "red")
  expect_identical(track@color, "red")
  expect_identical(trackSize(track), length(vcf))
  expect_identical(trackInfo(track)$source, "file")

  session <- fake_session()
  loadTrack(session, STAGE4_ID, track, validateReference = FALSE)
  loadVcfTrack(session, STAGE4_ID, "variants", vcf,
               trackConfig = list(color = "red",
                                  homvarColor = "rgb(17,248,254)",
                                  hetvarColor = "rgb(34,12,253)",
                                  homrefColor = "rgb(200,200,200)"),
               validateReference = FALSE)
  msgs <- sent_messages(session, "loadVcfTrack")
  expect_length(msgs, 2L)
  expect_identical(stage4_without(msgs[[1]]$message, "vcfDataFilepath"),
                   stage4_without(msgs[[2]]$message, "vcfDataFilepath"))
  expect_identical(msgs[[1]]$message$hetvarColor, "rgb(34,12,253)")
  served <- file.path(get_tracks_dir(),
                      basename(msgs[[1]]$message$vcfDataFilepath))
  expect_true(file.exists(served))
  end_session(session)
})

test_that("a url VariantTrack is stored but not sent", {
  track <- VariantTrack("remote", list(data = "https://example.org/a.vcf.gz",
                                       index = "https://example.org/a.tbi"))
  expect_null(track@vcf.obj)
  expect_identical(trackInfo(track)$source, "url")
  expect_identical(trackSize(track), NA_integer_)
  expect_error(VariantTrack("bad", list(data = "x")), "neither")
  expect_error(VariantTrack("bad", data.frame()), "neither")
  expect_error(methods::new("VariantTrack", vcf.obj = 1), "VCF")

  session <- fake_session()
  expect_error(loadTrack(session, STAGE4_ID, track), "url VariantTrack")
  expect_length(sent_messages(session), 0L)
})

test_that("GFF3Track validates its color table and keeps a default entry", {
  tbl <- stage4_gff3_tbl()
  track <- GFF3Track("gff3", tbl, colorByAttribute = "biotype",
                     colorTable = list(protein_coding = "blue",
                                       default = "gray"))
  expect_s4_class(track, "igvAnnotationTrack")
  expect_identical(names(track@colorTable), c("protein_coding", "*"))
  expect_identical(trackSize(track), NROW(tbl))
  expect_identical(trackInfo(track)$fileFormat, "gff3")

  # igvR errored on a color table without a default entry
  track <- GFF3Track("gff3", tbl, colorByAttribute = "biotype",
                     colorTable = list(protein_coding = "blue"))
  expect_identical(names(track@colorTable), "protein_coding")

  expect_error(GFF3Track("gff3", tbl, colorTable = list(a = "red")),
               "colorByAttribute")
  expect_error(GFF3Track("gff3"), "tbl.track or a url")
  expect_error(GFF3Track("gff3", tbl[, 1:8]), "9 GFF3 columns")
  expect_identical(trackSize(GFF3Track("u", url = "https://example.org/a")),
                   NA_integer_)
})

test_that("loadTrack sends a local GFF3Track like loadGFF3TrackFromLocalData", {
  tbl <- stage4_gff3_tbl()
  session <- fake_session()
  loadTrack(session, STAGE4_ID,
            GFF3Track("gff3", tbl, trackColor = "green",
                      displayMode = "SQUISHED", trackHeight = 90,
                      visibilityWindow = 5000))
  loadGFF3TrackFromLocalData(session, STAGE4_ID, "gff3", tbl,
                             color = "green", colorTable = list(),
                             colorByAttribute = "", displayMode = "SQUISHED",
                             trackHeight = 90, visibilityWindow = 5000)
  msgs <- sent_messages(session, "loadGFF3TrackFromLocalData")
  expect_length(msgs, 2L)
  expect_identical(stage4_without(msgs[[1]]$message, "filePath"),
                   stage4_without(msgs[[2]]$message, "filePath"))
  served <- file.path(get_tracks_dir(), basename(msgs[[1]]$message$filePath))
  expect_true(file.exists(served))
  end_session(session)
  expect_false(file.exists(served))
})

test_that("loadTrack sends a url GFF3Track like loadGFF3TrackFromURL", {
  session <- fake_session()
  loadTrack(session, STAGE4_ID,
            GFF3Track("gff3", url = "https://example.org/a.gff3"))
  loadGFF3TrackFromURL(session, STAGE4_ID, "gff3",
                       "https://example.org/a.gff3", "", color = "black",
                       colorTable = list(), colorByAttribute = "",
                       displayMode = "EXPANDED", trackHeight = 50,
                       visibilityWindow = 100000)
  msgs <- sent_messages(session, "loadGFF3TrackFromURL")
  expect_length(msgs, 2L)
  expect_identical(msgs[[1]]$message, msgs[[2]]$message)
  # the handler tests indexURL.length, so a missing index travels as ""
  expect_identical(msgs[[1]]$message$indexURL, "")
})

test_that("a BedpeInteractionsTrack writes sorted headerless bedpe", {
  tbl <- stage4_bedpe_tbl()
  track <- BedpeInteractionsTrack("loops", tbl[rev(seq_len(NROW(tbl))), ],
                                  trackHeight = 70)
  expect_s4_class(track, "DataFrameAnnotationTrack")
  expect_identical(trackInfo(track)$trackType, "pairedEndAnnotation")
  expect_identical(trackInfo(track)$fileFormat, "bedpe")
  expect_identical(trackSize(track), NROW(tbl))
  expect_error(BedpeInteractionsTrack("loops", tbl[, 1:5]))

  path <- tempfile(fileext = ".bedpe")
  on.exit(unlink(path))
  # arcType is not on the allowlist, so it is dropped with a warning
  expect_warning(
    payload <- igvShiny:::.trackPayload(track, path = path,
                                        trackConfig = list(arcType = "nested")),
    "arcType"
  )
  expect_identical(payload$files, path)
  written <- utils::read.table(path, sep = "\t", header = FALSE)
  expect_identical(NROW(written), NROW(tbl))
  expect_false(is.unsorted(written[[2]]))
  expect_identical(payload$config$color, "darkBlue")
  expect_identical(payload$config$trackHeight, 70)
  expect_match(payload$config$bedpeFilepath, "^tracks/")
  expect_null(payload$config$arcType)

  # both anchors are what the reference check sees
  ref <- igvShiny:::.trackReferenceData(track)
  expect_identical(NROW(ref), 2L * NROW(tbl))
  expect_identical(colnames(ref), c("chr", "start", "end"))
})

test_that("loadTrack sends a BedpeInteractionsTrack to its handler", {
  session <- fake_session()
  loadTrack(session, STAGE4_ID,
            BedpeInteractionsTrack("loops", stage4_bedpe_tbl()),
            validateReference = FALSE)
  msg <- last_message(session, "loadBedpeTrackFromFile")
  expect_identical(msg$elementID, STAGE4_ID)
  expect_identical(msg$trackName, "loops")
  served <- file.path(get_tracks_dir(), basename(msg$bedpeFilepath))
  expect_true(file.exists(served))
  end_session(session)
  expect_false(file.exists(served))
})

test_that("the bedpe handler loads an interact track in the browser stub", {
  skip_if_not(nzchar(Sys.which("node")), "Node.js not available")
  binding <- system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  harness <- test_path("helper-js-harness.js")
  out <- system2(Sys.which("node"),
                 args = c(shQuote(harness), shQuote(binding), "bedpe-handler"),
                 stdout = TRUE)
  config <- jsonlite::fromJSON(paste(out, collapse = "\n"))$bedpeHandler
  expect_identical(NROW(config), 1L)
  expect_identical(config$type, "interact")
  expect_identical(config$format, "bedpe")
  expect_identical(config$name, "loops")
  expect_identical(config$url, "http://127.0.0.1:1234/tracks/a.bedpe")
  expect_identical(config$color, "red")
  expect_identical(config$height, 70L)
})

test_that("loadTrack on a GWASTrack sends what display() sends", {
  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))
  track <- GWASTrack("gwas", tbl.gwas, chrom.col = 3, pos.col = 4,
                     pval.col = 10, chromosomeColorMap = list(chr1 = "red"))

  payload <- igvShiny:::.gwasTrackObjectPayload(track)
  expect_identical(payload$files, character(0))
  expect_match(payload$config$dataUrl, "^tracks/")
  expect_identical(payload$config$colorTable, list(chr1 = "red"))

  session <- fake_session()
  display(track, session, STAGE4_ID)
  loadTrack(session, STAGE4_ID, track)
  msgs <- sent_messages(session, "loadGwasTrackFlexibleSource")
  expect_length(msgs, 2L)
  expect_identical(msgs[[1]]$message, msgs[[2]]$message)
  expect_identical(names(msgs[[1]]$message)[1:2], c("elementID", "trackName"))

  loadTrack(session, STAGE4_ID, track, deleteTracksOfSameName = FALSE,
            trackConfig = list(color = "red"), validateReference = FALSE)
  expect_length(sent_messages(session, "removeTracksByName"), 2L)
})
