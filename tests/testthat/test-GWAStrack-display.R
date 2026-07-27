library(testthat)
library(igvShiny)

# display() and show() are the two GWASTrack methods with no coverage: display()
# is the S4 counterpart of the loadTrack functions and sends the igv.js message,
# show() is the print method BiocCheck asks S4 classes to provide.

gwas_from_data_frame <- function() {
  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))
  GWASTrack("gwas", tbl.gwas, chrom.col = 3, pos.col = 4, pval.col = 10,
            trackHeight = 100)
}

test_that("display() sends the track and rewrites a local url into tracks/", {
  session <- fake_session()
  track <- gwas_from_data_frame()
  display(track, session, id = "igvShiny_0")

  msg <- last_message(session, "loadGwasTrackFlexibleSource")
  expect_equal(msg$trackName, "gwas")
  expect_equal(msg$dataMode, "local.url")
  # local.url data is rewritten to the shorthand resource path that the Shiny
  # web server exposes, not left as the absolute temp-dir path
  expect_match(msg$dataUrl, "^tracks/")
  expect_equal(msg$trackHeight, 100)
})

test_that("display() sends the column mapping igv.js needs", {
  session <- fake_session()
  display(gwas_from_data_frame(), session, id = "igvShiny_0")

  msg <- last_message(session, "loadGwasTrackFlexibleSource")
  # igv.js reads these 1-based, exactly as the constructor takes them; without
  # them it falls back to guessing the columns from the header names
  expect_equal(msg$columns, list(chromosome = 3, position = 4, value = 10))
})

test_that("display() sends a chromosome color map only when there is one", {
  session <- fake_session()
  display(gwas_from_data_frame(), session, id = "igvShiny_0")
  msg <- last_message(session, "loadGwasTrackFlexibleSource")
  # an empty colorTable would replace the igv.js palette with nothing
  expect_null(msg$colorTable)

  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))
  colors <- list("1" = "red", "*" = "gray")
  track <- GWASTrack("gwas", tbl.gwas, chrom.col = 3, pos.col = 4,
                     pval.col = 10, chromosomeColorMap = colors)
  session <- fake_session()
  display(track, session, id = "igvShiny_0")

  msg <- last_message(session, "loadGwasTrackFlexibleSource")
  expect_equal(msg$colorTable, colors)
})

test_that("display() removes same-named tracks unless told otherwise", {
  session <- fake_session()
  display(gwas_from_data_frame(), session, id = "igvShiny_0")
  expect_length(sent_messages(session, "removeTracksByName"), 1L)

  session <- fake_session()
  display(gwas_from_data_frame(), session, id = "igvShiny_0",
          deleteTracksOfSameName = FALSE)
  expect_length(sent_messages(session, "removeTracksByName"), 0L)
})

test_that("display() keeps a remote url untouched", {
  port <- local_server()
  url <- local_url(port, "gwas-5k.tsv.gz")
  track <- GWASTrack("remote gwas", url, chrom.col = 3, pos.col = 4,
                     pval.col = 10)
  session <- fake_session()
  display(track, session, id = "igvShiny_0")

  msg <- last_message(session, "loadGwasTrackFlexibleSource")
  expect_equal(msg$dataMode, "remote.url")
  expect_equal(msg$dataUrl, url)
})

test_that("show() prints the track summary", {
  out <- capture.output(show(gwas_from_data_frame()))
  expect_match(paste(out, collapse = "\n"), "GWASTrack object")
  expect_match(paste(out, collapse = "\n"), "trackName:  gwas")
  expect_match(paste(out, collapse = "\n"), "chrom=3")
  # the color line is printed only for a track that carries a map
  expect_false(any(grepl("colors:", out)))

  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))
  track <- GWASTrack("gwas", tbl.gwas, chrom.col = 3, pos.col = 4,
                     pval.col = 10,
                     chromosomeColorMap = list("1" = "red", "*" = "gray"))
  expect_match(paste(capture.output(show(track)), collapse = "\n"),
               "colors:     2 chromosomes")
})
