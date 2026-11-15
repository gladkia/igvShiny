library(testthat)
library(igvShiny)

test_that("Supported genomes can be retrieved correctly", {
  cg.minimal <- get_css_genomes(test = TRUE)
  expect_equal(cg.minimal,
               c(
                 "hg38",
                 "hg19",
                 "mm10",
                 "tair10",
                 "rhos",
                 "custom",
                 "dm6",
                 "sacCer3"
               ))

  cg <- get_css_genomes()

  # With igv.org unreachable get_css_genomes() falls back to the eight ids
  # above, so the two assertions below would fail on someone else's outage and
  # read as a code regression
  skip_if(identical(cg, get_basic_genomes()),
          "genome registry unreachable, fell back to the built-in list")

  expect_true(length(cg) > 30)

  # the list has to come from the registry the bundled igv.js reads, so that
  # every id it reports resolves by bare name; mm10, danRer11 and rn6 are the
  # genomes #107 was about
  expect_true(all(c("hg38", "mm10", "danRer11", "rn6") %in% cg))
})

test_that("Cached (caas) genomes are retrieved quickly", {
  t1 <- system.time(caasg <- get_cas_genomes())
  expect_lt(t1[["elapsed"]], 0.1)
  expect_true(all(
    c("hg38", "hg19", "mm10", "tair10", "custom", "dm6", "sacCer3") %in% caasg
  ))

  t2 <- system.time(cssg  <- get_css_genomes())
  # with the registry reachable the fetch takes real time; when it is not
  # (offline CI), get_css_genomes falls back to the built-in list instantly
  # and there is nothing to time
  skip_if(identical(cssg, get_basic_genomes()),
          "genome registry unreachable, fell back to the built-in list")
  expect_true(t2[["elapsed"]] > 0.01)

  # Parsing a cached genome spec should be fast
  t3 <- system.time(
    parseAndValidateGenomeSpec(
      genomeName = "hg38",
      initialLocus = "NDUFS2",
      stockGenome = TRUE,
      dataMode = "stock"
    )
  )
  expect_lt(t3[["elapsed"]], 0.1)

  # Parsing a non-cached genome spec is slower
  skip_if(identical(cssg, get_basic_genomes()),
          "genome registry unreachable, fell back to the built-in list")
  t4 <- system.time(
    parseAndValidateGenomeSpec(
      genomeName = "macFas5",
      initialLocus = "all",
      stockGenome = TRUE,
      dataMode = "stock"
    )
  )
  expect_true(t4[["elapsed"]] > 0.01)
})

test_that("get_css_genomes falls back when the registry connection fails", {
  # a refused proxy or DNS outage makes httr::http_error signal rather than
  # return TRUE; the fallback has to hold then too (#182)
  local_mocked_bindings(http_error = function(...) stop("connection refused"),
                        .package = "httr")
  expect_identical(get_css_genomes(), get_basic_genomes())
})

test_that("get_css_genomes falls back when the probe reports an HTTP error", {
  local_mocked_bindings(http_error = function(...) TRUE, .package = "httr")
  expect_identical(get_css_genomes(), get_basic_genomes())
})

test_that("get_css_genomes falls back when the fetch fails after a successful probe", {
  # the HEAD probe can succeed and the GET still die mid-transfer (#182);
  # only the fetch is guarded, so the fallback has to hold here too
  local_mocked_bindings(http_error = function(...) FALSE, .package = "httr")
  local_mocked_bindings(readLines = function(...) stop("GET connection reset"),
                        .package = "base")
  expect_identical(get_css_genomes(), get_basic_genomes())
})

test_that("get_css_genomes surfaces malformed registry content as an error", {
  # a registry that answers with broken content is not an outage: the parse
  # error must reach the caller rather than silently fall back (#182)
  local_mocked_bindings(http_error = function(...) FALSE, .package = "httr")
  local_mocked_bindings(readLines = function(...) "{not json", .package = "base")
  expect_error(get_css_genomes())
})

test_that("get_css_genomes returns the registry ids on a successful fetch", {
  local_mocked_bindings(http_error = function(...) FALSE, .package = "httr")
  local_mocked_bindings(
    readLines = function(...) '[{"id": "hg38"}, {"id": "mm10"}, {"id": "danRer11"}]',
    .package = "base")
  expect_identical(get_css_genomes(), c("hg38", "mm10", "danRer11"))
})

test_that("Parsing and validation of stock genome specs works", {
  options <- parseAndValidateGenomeSpec(
    genomeName = "hg38",
    initialLocus = "NDUFS2",
    stockGenome = TRUE,
    dataMode = "stock",
    fasta = NA,
    fastaIndex = NA,
    genomeAnnotation = NA
  )

  expect_equal(
    sort(names(options)),
    c(
      "annotation",
      "dataMode",
      "fasta",
      "fastaIndex",
      "genomeName",
      "initialLocus",
      "stockGenome",
      "validated"
    )
  )
  expect_equal(options[["genomeName"]], "hg38")
  expect_true(options[["validated"]])
  expect_true(options[["stockGenome"]])
  expect_true(all(is.na(options[c("fasta", "fastaIndex", "annotation")])))

  # Using a non-existent genome name should fail
  expect_error(suppressWarnings(
    parseAndValidateGenomeSpec(genomeName = "fubar99", initialLocus = "all")
  ))
})

test_that("Parsing and validation of custom HTTP genome specs works", {
  # Served from 127.0.0.1 rather than gladki.pl: the http code path is still
  # exercised for real, but CI no longer depends on a third-party host.
  port <- local_server()
  fasta.file <- local_url(port, "ribosomal-RNA-gene.fasta")
  fastaIndex.file <- local_url(port, "ribosomal-RNA-gene.fasta.fai")
  annotation.file <- local_url(port, "ribosomal-RNA-gene.gff3")

  options <- parseAndValidateGenomeSpec(
    genomeName = "ribo",
    initialLocus = "all",
    stockGenome = FALSE,
    dataMode = "http",
    fasta = fasta.file,
    fastaIndex = fastaIndex.file,
    genomeAnnotation = annotation.file
  )
  expect_true(options$validated)
  expect_false(options$stockGenome)
  expect_equal(options$dataMode, "http")

  # A bogus fasta file URL should fail
  expect_error({
    fasta.file.bogus <- sprintf("%s-bogus", fasta.file)
    parseAndValidateGenomeSpec(
      genomeName = "ribo-willFail",
      initialLocus = "all",
      stockGenome = FALSE,
      dataMode = "http",
      fasta = fasta.file.bogus,
      fastaIndex = fastaIndex.file,
      genomeAnnotation = annotation.file
    )
  })
})

test_that("Parsing and validation of custom local file genome specs works", {
  data.directory <- system.file(package = "igvShiny", "extdata")
  fasta.file <- file.path(data.directory, "ribosomal-RNA-gene.fasta")
  fastaIndex.file <- file.path(data.directory, "ribosomal-RNA-gene.fasta.fai")
  annotation.file <- file.path(data.directory, "ribosomal-RNA-gene.gff3")

  expect_true(file.exists(fasta.file))
  expect_true(file.exists(fastaIndex.file))
  expect_true(file.exists(annotation.file))

  options <- parseAndValidateGenomeSpec(
    genomeName = "ribosome local files",
    initialLocus = "all",
    stockGenome = FALSE,
    dataMode = "localFiles",
    fasta = fasta.file,
    fastaIndex = fastaIndex.file,
    genomeAnnotation = annotation.file
  )
  expect_true(options$validated)
  expect_false(options$stockGenome)
  expect_equal(options$dataMode, "localFiles")

  # A bogus file path should fail
  expect_error({
    fasta.file.bogus <- sprintf("%s-bogus", fasta.file)
    parseAndValidateGenomeSpec(
      genomeName = "ribo-willFail",
      initialLocus = "all",
      stockGenome = FALSE,
      dataMode = "localFiles",
      fasta = fasta.file.bogus,
      fastaIndex = fastaIndex.file,
      genomeAnnotation = annotation.file
    )
  })
})

test_that("Parsing SARS genome with GFF3 from local files works", {
  data.directory <- system.file(package = "igvShiny", "extdata", "sarsGenome")
  fasta.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.dna.toplevel.fa")
  fastaIndex.file <- file.path(data.directory,
                               "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai")
  annotation.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.101.gff3")

  expect_true(file.exists(fasta.file))

  title <- "SARS-CoV-2"
  options <- parseAndValidateGenomeSpec(
    genomeName = title,
    initialLocus = "all",
    stockGenome = FALSE,
    dataMode = "localFiles",
    fasta = fasta.file,
    fastaIndex = fastaIndex.file,
    genomeAnnotation = annotation.file
  )
  expect_true(options$validated)
  expect_equal(options$genomeName, title)
  expect_false(options$stockGenome)
})
