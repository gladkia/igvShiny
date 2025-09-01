library(testthat)
library(igvShiny)

test_that("GWASTrack constructor works with a data.frame", {
    f <- system.file(package="igvShiny", "extdata", "gwas.RData")
    tbl.gwas <- get(load(f))

    gwasTrack <- GWASTrack("data.frame gwas",
                           tbl.gwas,
                           chrom.col=3,
                           pos.col=4,
                           pval.col=10,
                           trackHeight=100)
    url <- getUrl(gwasTrack)
    expect_true(grepl("tracks.*\\.gwas", url))
})

test_that("GWASTrack constructor works with a remote URL", {
    url <- "https://gladki.pl/igvShiny/gwas_sample.tsv.gz"
    gwasTrack <- GWASTrack("remote url gwas",
                           url,
                           chrom.col=3,
                           pos.col=4,
                           pval.col=10,
                           trackHeight=100)
    url.retrieved <- getUrl(gwasTrack)
    expect_equal(url, url.retrieved)
})

test_that("GWASTrack constructor fails with illegal arguments", {
    expect_error(
        GWASTrack("bogus url",
                  data="https://bogus.org/nonexistent.gwas",
                  chrom.col=3,
                  pos.col=4,
                  pval.col=10,
                  color="darkgreen",
                  trackHeight=100)
    )

    expect_error(
        GWASTrack("bogus data type",
                  data=42,
                  chrom.col=3,
                  pos.col=4,
                  pval.col=10,
                  color="darkgreen",
                  trackHeight=100)
    )
})

