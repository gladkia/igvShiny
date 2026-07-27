library(testthat)
library(igvShiny)

test_that("GWASTrack constructor works with a data.frame", {
  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))

  gwasTrack <- GWASTrack(
    "data.frame gwas",
    tbl.gwas,
    chrom.col = 3,
    pos.col = 4,
    pval.col = 10,
    trackHeight = 100
  )
  url <- getUrl(gwasTrack)
  expect_true(grepl("tracks.*\\.gwas", url))
})

test_that("GWASTrack constructor works with a remote URL", {
  # Local static server instead of gladki.pl - same http code path (the
  # constructor runs httr::http_error on the url), no third-party dependency.
  port <- local_server()
  url <- local_url(port, "gwas-5k.tsv.gz")
  gwasTrack <- GWASTrack(
    "remote url gwas",
    url,
    chrom.col = 3,
    pos.col = 4,
    pval.col = 10,
    trackHeight = 100
  )
  url.retrieved <- getUrl(gwasTrack)
  expect_equal(url, url.retrieved)
})

test_that("GWASTrack constructor rejects impossible column numbers", {
  f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
  tbl.gwas <- get(load(f))

  expect_error(
    GWASTrack("bad col", tbl.gwas, chrom.col = 3, pos.col = 4, pval.col = 0),
    "at least 1"
  )
  expect_error(
    GWASTrack("bad col", tbl.gwas, chrom.col = c(3, 4), pos.col = 4,
              pval.col = 10),
    "single column number"
  )
  # a column past the end of the table would otherwise yield an empty track
  expect_error(
    GWASTrack("bad col", tbl.gwas, chrom.col = 3, pos.col = 4,
              pval.col = NCOL(tbl.gwas) + 1),
    sprintf("beyond the %d columns", NCOL(tbl.gwas))
  )
  # all three share one check, so the message has to name the guilty one
  expect_error(
    GWASTrack("bad col", tbl.gwas, chrom.col = NCOL(tbl.gwas) + 1, pos.col = 4,
              pval.col = 10),
    "chrom.col beyond"
  )
})

sanitizeColorMap <- igvShiny:::.sanitizeChromosomeColorMap

test_that("chromosomeColorMap keeps only named, single-string colors", {
  expect_equal(sanitizeColorMap(NULL), list())
  expect_equal(sanitizeColorMap(list()), list())
  expect_equal(sanitizeColorMap(c("1" = "red")), list("1" = "red"))
  expect_error(sanitizeColorMap(list("red", "blue")),
               "needs a chromosome name")
  expect_error(sanitizeColorMap(list("1" = "red", "blue")),
               "needs a chromosome name")
  expect_error(sanitizeColorMap(list("1" = c("red", "blue"))),
               "single strings")
  expect_error(sanitizeColorMap(list("1" = 42)), "single strings")
  expect_error(sanitizeColorMap(42), "named list or character")
  # JSON keeps one value per key, so a repeated chromosome loses a color
  expect_error(sanitizeColorMap(list("1" = "red", "1" = "blue")),
               "one chromosome twice")
})

test_that("GWASTrack constructor fails with illegal arguments", {
  # A url the server answers with 404, so the http-error path is tested
  # without reaching out to a real external host.
  port <- local_server()
  expect_error(
    GWASTrack(
      "bogus url",
      data = local_url(port, "does-not-exist.gwas"),
      chrom.col = 3,
      pos.col = 4,
      pval.col = 10,
      color = "darkgreen",
      trackHeight = 100
    )
  )

  expect_error(
    GWASTrack(
      "bogus data type",
      data = 42,
      chrom.col = 3,
      pos.col = 4,
      pval.col = 10,
      color = "darkgreen",
      trackHeight = 100
    )
  )
})
