library(testthat)
library(igvShiny)

# The widget constructor itself: building an htmlwidget needs no browser, so the
# genome plumbing, the startup `tracks` sanitisation (#36) and the Shiny
# output/render wrappers can all be checked here.
#
# igvShiny() reads the module namespace off the current reactive domain
# (`shiny::getDefaultReactiveDomain()$ns("")`), so it has to be called inside
# one - a MockShinySession provides that without starting an app.

with_domain <- function(code) {
  shiny::withReactiveDomain(shiny::MockShinySession$new(), code)
}

test_that("igvShiny builds a widget for a stock genome", {
  opts <- parseAndValidateGenomeSpec(genomeName = "hg38",
                                     initialLocus = "MEF2C")
  widget <- with_domain(igvShiny(opts))

  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$x$genomeName, "hg38")
  expect_equal(widget$x$initialLocus, "MEF2C")
})

test_that("igvShiny sanitises the startup tracks and keeps the valid ones (#36)", {
  opts <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "all")
  tracks <- list(
    list(name = "genes", type = "annotation", format = "gff3",
         url = "https://example.org/genes.gff3"),
    list(name = "dropped", type = "annotation")          # no url
  )
  expect_warning(widget <- with_domain(igvShiny(opts, tracks = tracks)),
                 "no valid 'url'")

  expect_length(widget$x$tracks, 1L)
  expect_equal(widget$x$tracks[[1]]$name, "genes")
})

test_that("igvShiny defaults to no startup tracks", {
  opts <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "all")
  widget <- with_domain(igvShiny(opts))
  expect_length(widget$x$tracks, 0L)
})

test_that("igvShiny refuses a genome spec that was not validated", {
  opts <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "all")
  opts$validated <- FALSE
  expect_error(with_domain(igvShiny(opts)))

  expect_error(with_domain(igvShiny(list(genomeName = "hg38"))))
})

test_that("igvShiny copies local genome files into the tracks directory", {
  data.dir <- system.file(package = "igvShiny", "extdata")
  opts <- parseAndValidateGenomeSpec(
    genomeName = "ribo",
    initialLocus = "all",
    stockGenome = FALSE,
    dataMode = "localFiles",
    fasta = file.path(data.dir, "ribosomal-RNA-gene.fasta"),
    fastaIndex = file.path(data.dir, "ribosomal-RNA-gene.fasta.fai"),
    genomeAnnotation = file.path(data.dir, "ribosomal-RNA-gene.gff3")
  )
  widget <- with_domain(igvShiny(opts))

  # the paths handed to igv.js are rewritten to the served "tracks" directory
  expect_match(widget$x$fasta, "^tracks/")
  expect_match(widget$x$fastaIndex, "^tracks/")
  expect_true(file.exists(file.path(get_tracks_dir(),
                                    basename(widget$x$fasta))))
})

test_that("igvShinyOutput and renderIgvShiny return Shiny bindings", {
  out <- igvShinyOutput("igv")
  expect_s3_class(out, "shiny.tag.list")

  opts <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "all")
  renderer <- renderIgvShiny(with_domain(igvShiny(opts)))
  expect_type(renderer, "closure")
})
