library(testthat)

# Local-file track urls are built from the app's base url, not from
# window.location.href: a session opened with a query string ("?x=1",
# bookmarking, Connect routing) produced "http://host/?x=1tracks/...",
# which serves the app's HTML instead of the file and igv.js loads
# nothing. Fixed for bed in #88; the same build now serves every loader.

test_that("local-file urls drop the query string in every loader (#88)", {
  skip_if_not(nzchar(Sys.which("node")), "Node.js not available")
  binding <- system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  harness <- test_path("helper-js-harness.js")
  out <- system2(Sys.which("node"),
                 args = c(shQuote(harness), shQuote(binding), "local-urls"),
                 stdout = TRUE)
  res <- jsonlite::fromJSON(paste(out, collapse = "\n"),
                            simplifyVector = FALSE)$localUrls

  base <- "http://127.0.0.1:1234/"
  # custom local genome: fasta, index and annotation track
  ref <- res$reference
  expect_identical(ref$fastaURL, paste0(base, "tracks/genome.fa"))
  expect_identical(ref$indexURL, paste0(base, "tracks/genome.fa.fai"))
  expect_identical(ref$tracks[[1]]$url, paste0(base, "tracks/genes.gff3"))

  # every loader that serves a file from the tracks directory
  expected <- c("gff3 track" = "tracks/a.gff3",
                bed = "tracks/a.bed",
                bedpe = "tracks/a.bedpe",
                vcf = "tracks/a.vcf",
                gwas = "tracks/a.gwas",
                gwasLocal = "tracks/a.gwas",
                bam = "tracks/a.bam",
                gff3 = "tracks/a.gff3")
  urls <- vapply(res$tracks, `[[`, character(1), "url")
  names(urls) <- vapply(res$tracks, `[[`, character(1), "name")
  expect_identical(unname(urls[names(expected)]), paste0(base, unname(expected)))

  # only the page query is dropped: a resource path keeps its own query
  expect_identical(urls[["bedSession"]],
                   paste0(base, "session/tok/dataobj/a.bed?w=1&nonce=abc"))

  # a remote url is left untouched
  remote <- Filter(function(t) identical(t$name, "gwasRemote"), res$tracks)[[1]]
  expect_identical(remote$url, "https://example.org/a.gwas")
})
