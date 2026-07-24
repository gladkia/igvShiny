library(testthat)
library(igvShiny)

# The track loaders are thin wrappers: they validate and reshape their inputs,
# then hand a payload to igv.js over session$sendCustomMessage(). These tests
# pin down that payload - the R/JS contract is exactly what broke in #36, #105
# and #116, and until now nothing checked it outside a real browser.

ELEMENT_ID <- "igvShiny_0"

bed_tbl <- function() {
  data.frame(
    chr = c("chr1", "chr1", "chr1"),
    start = c(7432, 7561, 7300),
    end = c(7503, 7580, 7350),
    value = c(0.5, 0.9, 0.1),
    stringsAsFactors = FALSE
  )
}

test_that("loadBedTrack sends a bed file path and honours colour and height", {
  session <- fake_session()
  loadBedTrack(session, ELEMENT_ID, "bed", bed_tbl(),
               color = "blue", trackHeight = 77)

  msg <- last_message(session, "loadBedTrackFromFile")
  expect_equal(msg$elementID, ELEMENT_ID)
  expect_equal(msg$trackName, "bed")
  expect_equal(msg$color, "blue")
  expect_equal(msg$trackHeight, 77)
  expect_match(msg$bedFilepath, "^tracks/.*\\.bed$")
  expect_true(file.exists(file.path(get_tracks_dir(), basename(msg$bedFilepath))))
})

test_that("loadBedTrack deletes same-named tracks first, and can be told not to", {
  session <- fake_session()
  loadBedTrack(session, ELEMENT_ID, "bed", bed_tbl())
  expect_length(sent_messages(session, "removeTracksByName"), 1L)

  session <- fake_session()
  loadBedTrack(session, ELEMENT_ID, "bed", bed_tbl(),
               deleteTracksOfSameName = FALSE)
  expect_length(sent_messages(session, "removeTracksByName"), 0L)
})

test_that("loadBedTrack rejects a data.frame without chr/start/end", {
  session <- fake_session()
  tbl <- data.frame(a = "chr1", b = 1, c = 2, stringsAsFactors = FALSE)
  expect_error(loadBedTrack(session, ELEMENT_ID, "bad", tbl),
               "improper columns")
})

test_that("loadBedGraphTrack passes the autoscale settings through", {
  session <- fake_session()
  loadBedGraphTrack(session, ELEMENT_ID, "bedgraph", bed_tbl(),
                    autoscale = FALSE, min = 0, max = 10,
                    autoscaleGroup = 2)

  msg <- last_message(session, "loadBedGraphTrack")
  expect_false(msg$autoscale)
  expect_equal(msg$min, 0)
  expect_equal(msg$max, 10)
  expect_equal(msg$autoscaleGroup, 2)
})

test_that("loadBedGraphTrackFromURL forwards the url and autoscaleGroup (#105)", {
  session <- fake_session()
  url <- "https://example.org/data.bedGraph"
  loadBedGraphTrackFromURL(session, ELEMENT_ID, "remote", url,
                           autoscale = TRUE, autoscaleGroup = 1)

  msg <- last_message(session, "loadBedGraphTrackFromURL")
  expect_equal(msg$url, url)
  expect_true(msg$autoscale)
  expect_equal(msg$autoscaleGroup, 1)
})

test_that("loadSegTrack serialises the table as JSON", {
  session <- fake_session()
  tbl <- data.frame(
    chr = "chr1", start = 100, end = 200, value = 0.3,
    stringsAsFactors = FALSE
  )
  loadSegTrack(session, ELEMENT_ID, "seg", tbl)

  msg <- last_message(session, "loadSegTrack")
  expect_equal(msg$trackName, "seg")
  expect_match(as.character(msg$tbl), "chr1")
})

test_that("loadGwasTrack writes the table and sets the y-axis limits", {
  session <- fake_session()
  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))
  loadGwasTrack(session, ELEMENT_ID, "gwas", tbl.gwas, ymin = 1, ymax = 20)

  msg <- last_message(session, "loadGwasTrack")
  expect_match(msg$gwasDataFilepath, "^tracks/.*\\.gwas$")
  expect_equal(msg$min, 1)
  expect_equal(msg$max, 20)
  expect_false(msg$autoscale)
})

test_that("loadBamTrackFromURL sends both the bam and the index url", {
  session <- fake_session()
  loadBamTrackFromURL(session, ELEMENT_ID, "bam",
                      bamURL = "https://example.org/x.bam",
                      indexURL = "https://example.org/x.bam.bai",
                      displayMode = "SQUISHED", showAllBases = TRUE)

  msg <- last_message(session, "loadBamTrackFromURL")
  expect_equal(msg$bam, "https://example.org/x.bam")
  expect_equal(msg$index, "https://example.org/x.bam.bai")
  expect_equal(msg$displayMode, "SQUISHED")
  expect_true(msg$showAllBases)
})

test_that("loadCramTrackFromURL sends both the cram and the index url", {
  session <- fake_session()
  loadCramTrackFromURL(session, ELEMENT_ID, "cram",
                       cramURL = "https://example.org/x.cram",
                       indexURL = "https://example.org/x.cram.crai")

  msg <- last_message(session, "loadCramTrackFromURL")
  expect_equal(msg$cram, "https://example.org/x.cram")
  expect_equal(msg$index, "https://example.org/x.cram.crai")
})

test_that("loadGFF3TrackFromURL forwards the colour mapping", {
  session <- fake_session()
  colorTable <- list(protein_coding = "red", lncRNA = "blue")
  loadGFF3TrackFromURL(session, ELEMENT_ID, "gff3",
                       gff3URL = "https://example.org/x.gff3",
                       indexURL = "https://example.org/x.gff3.tbi",
                       colorTable = colorTable,
                       colorByAttribute = "biotype",
                       displayMode = "EXPANDED",
                       visibilityWindow = 1000000)

  msg <- last_message(session, "loadGFF3TrackFromURL")
  expect_equal(msg$dataURL, "https://example.org/x.gff3")
  expect_equal(msg$indexURL, "https://example.org/x.gff3.tbi")
  expect_equal(msg$colorByAttribute, "biotype")
  expect_equal(msg$colorTable$protein_coding, "red")
  expect_equal(msg$visibilityWindow, 1000000)
})

test_that("loadGFF3TrackFromLocalData writes the file into the tracks dir", {
  session <- fake_session()
  f <- system.file(package = "igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
  tbl.gff3 <- read.table(f, sep = "\t", header = FALSE, comment.char = "#",
                         quote = "", nrows = 50, stringsAsFactors = FALSE)
  loadGFF3TrackFromLocalData(session, ELEMENT_ID, "local gff3", tbl.gff3,
                             colorTable = list(exon = "red"),
                             colorByAttribute = "biotype",
                             displayMode = "EXPANDED",
                             visibilityWindow = 5000)

  msg <- last_message(session, "loadGFF3TrackFromLocalData")
  expect_match(msg$filePath, "^tracks/.*\\.gff3$")
  expect_true(file.exists(file.path(get_tracks_dir(), basename(msg$filePath))))
})

test_that("loadVcfTrack writes a vcf and points igv.js at it", {
  skip_if_not_installed("VariantAnnotation")
  session <- fake_session()
  f <- system.file(package = "igvShiny", "extdata", "chr19-cebpaRegion.vcf.gz")
  vcf <- VariantAnnotation::readVcf(f)
  loadVcfTrack(session, ELEMENT_ID, "vcf", vcf)

  msg <- last_message(session, "loadVcfTrack")
  expect_match(msg$vcfDataFilepath, "^tracks/.*\\.vcf$")
})

test_that("loadBamTrackFromLocalData exports the alignments to the tracks dir", {
  skip_if_not_installed("GenomicAlignments")
  skip_if_not_installed("Rsamtools")
  skip_if_not_installed("rtracklayer")
  session <- fake_session()
  f <- system.file(package = "igvShiny", "extdata", "tumor.bam")
  ga <- GenomicAlignments::readGAlignments(f, use.names = TRUE)
  loadBamTrackFromLocalData(session, ELEMENT_ID, "local bam", ga)

  msg <- last_message(session, "loadBamTrackFromLocalData")
  expect_match(msg$bamDataFilepath, "^tracks/.*\\.bam$")
})

test_that("the navigation and removal helpers send their own messages", {
  session <- fake_session()
  showGenomicRegion(session, ELEMENT_ID, "chr1:1-1000")
  expect_equal(last_message(session, "showGenomicRegion")$region, "chr1:1-1000")

  getGenomicRegion(session, ELEMENT_ID)
  expect_equal(last_message(session, "getGenomicRegion")$elementID, ELEMENT_ID)

  removeTracksByName(session, ELEMENT_ID, c("a", "b"))
  expect_equal(last_message(session, "removeTracksByName")$trackNames, c("a", "b"))

  removeUserAddedTracks(session, ELEMENT_ID)
  expect_gt(length(sent_messages(session, "removeTracksByName")), 1L)
})
