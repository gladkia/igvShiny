library(testthat)
library(igvShiny)

# The widget constructor itself: building an htmlwidget needs no browser, so the
# genome plumbing, the startup `tracks` sanitisation (#36) and the Shiny
# output/render wrappers can all be checked here.
#
# igvShiny() reads the module namespace off the current reactive domain
# (`shiny::getDefaultReactiveDomain()$ns("")`); a MockShinySession provides one
# without starting an app. Outside a session the namespace is "" (#128).

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

local_ribo_opts <- function() {
  data.dir <- system.file(package = "igvShiny", "extdata")
  parseAndValidateGenomeSpec(
    genomeName = "ribo",
    initialLocus = "all",
    stockGenome = FALSE,
    dataMode = "localFiles",
    fasta = file.path(data.dir, "ribosomal-RNA-gene.fasta"),
    fastaIndex = file.path(data.dir, "ribosomal-RNA-gene.fasta.fai"),
    genomeAnnotation = file.path(data.dir, "ribosomal-RNA-gene.gff3")
  )
}

test_that("igvShiny serves a local fasta through the Range handler (#183)", {
  session <- fake_session()
  session$ns <- function(id) id
  widget <- shiny::withReactiveDomain(session, igvShiny(local_ribo_opts()))

  # the "tracks" resource path ignores Range, so the indexed fasta must not go
  # there: igv.js would download the whole genome for every sequence read
  expect_match(widget$x$fasta, "^session/.*/dataobj/")
  expect_match(widget$x$fastaIndex, "^session/.*/dataobj/")
  expect_match(widget$x$annotation, "^tracks/")

  fasta <- Filter(function(o) grepl("\\.fasta$", o$name),
                  session$registeredDataObjs)[[1]]
  res <- fasta$filterFunc(fasta$data, list(HTTP_RANGE = "bytes=0-9"))
  expect_equal(res$status, 206L)
  expect_length(res$content, 10L)
})

test_that("igvShiny copies local genome files into tracks without a session", {
  expect_null(shiny::getDefaultReactiveDomain())
  widget <- igvShiny(local_ribo_opts())

  expect_match(widget$x$fasta, "^tracks/")
  expect_match(widget$x$fastaIndex, "^tracks/")
  expect_true(file.exists(file.path(get_tracks_dir(),
                                    basename(widget$x$fasta))))
})

test_that("igvShiny builds outside a reactive domain (#128)", {
  expect_null(shiny::getDefaultReactiveDomain())

  opts <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "all")
  widget <- igvShiny(opts)

  expect_s3_class(widget, "htmlwidget")
  # the JS side concatenates moduleNS with the event name, so no module means ""
  expect_identical(widget$x$moduleNS, "")
})

test_that("igvShinyOutput and renderIgvShiny return Shiny bindings", {
  out <- igvShinyOutput("igv")
  expect_s3_class(out, "shiny.tag.list")

  opts <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "all")
  renderer <- renderIgvShiny(with_domain(igvShiny(opts)))
  expect_type(renderer, "closure")
})
