library(testthat)
library(igvShiny)

test_that("Supported genomes can be retrieved correctly", {
    cg <- get_css_genomes()
    expect_true(length(cg) > 30)

    cg.minimal <- get_css_genomes(test=TRUE)
    expect_equal(cg.minimal, c("hg38", "hg19", "mm10", "tair10", "rhos", "custom", "dm6", "sacCer3"))
})

test_that("Cached (caas) genomes are retrieved quickly", {
    t1 <- system.time(caasg <- get_cas_genomes())
    expect_lt(t1[["elapsed"]], 0.1)
    expect_true(all(c("hg38", "hg19", "mm10", "tair10", "custom", "dm6", "sacCer3") %in% caasg))

    t2 <- system.time(cssg  <- get_css_genomes())
    expect_true(t2[["elapsed"]] > 0.01)

    # Parsing a cached genome spec should be fast
    t3 <- system.time(parseAndValidateGenomeSpec(genomeName="hg38",  initialLocus="NDUFS2",
                                                 stockGenome=TRUE, dataMode="stock"))
    expect_lt(t3[["elapsed"]], 0.1)

    # Parsing a non-cached genome spec is slower
    t4 <- system.time(parseAndValidateGenomeSpec(genomeName="macFas5",  initialLocus="all",
                                                 stockGenome=TRUE, dataMode="stock"))
    expect_true(t4[["elapsed"]] > 0.01)
})

test_that("Parsing and validation of stock genome specs works", {
    options <- parseAndValidateGenomeSpec(genomeName="hg38",  initialLocus="NDUFS2",
                                          stockGenome=TRUE, dataMode="stock",
                                          fasta=NA, fastaIndex=NA, genomeAnnotation=NA)

    expect_equal(sort(names(options)),
                c("annotation", "dataMode", "fasta", "fastaIndex", "genomeName",
                  "initialLocus", "stockGenome", "validated"))
    expect_equal(options[["genomeName"]], "hg38")
    expect_true(options[["validated"]])
    expect_true(options[["stockGenome"]])
    expect_true(all(is.na(options[c("fasta", "fastaIndex", "annotation")])))

    # Using a non-existent genome name should fail
    expect_error(
      suppressWarnings(
          parseAndValidateGenomeSpec(genomeName="fubar99",  initialLocus="all")
          )
      )
})

test_that("Parsing and validation of custom HTTP genome specs works", {
    base.url <- "https://gladki.pl/igvr/testFiles"
    fasta.file <- file.path(base.url, "ribosomal-RNA-gene.fasta")
    fastaIndex.file <- file.path(base.url, "ribosomal-RNA-gene.fasta.fai")
    annotation.file <- file.path(base.url, "ribosomal-RNA-gene.gff3")

    options <- parseAndValidateGenomeSpec(genomeName="ribo",
                                          initialLocus="all",
                                          stockGenome=FALSE,
                                          dataMode="http",
                                          fasta=fasta.file,
                                          fastaIndex=fastaIndex.file,
                                          genomeAnnotation=annotation.file)
    expect_true(options$validated)
    expect_false(options$stockGenome)
    expect_equal(options$dataMode, "http")

    # A bogus fasta file URL should fail
    expect_error({
       fasta.file.bogus <- sprintf("%s-bogus", fasta.file)
       parseAndValidateGenomeSpec(genomeName="ribo-willFail",
                                  initialLocus="all", stockGenome=FALSE, dataMode="http",
                                  fasta=fasta.file.bogus, fastaIndex=fastaIndex.file,
                                  genomeAnnotation=annotation.file)
    })
})

test_that("Parsing and validation of custom local file genome specs works", {
    data.directory <- system.file(package="igvShiny", "extdata")
    fasta.file <- file.path(data.directory, "ribosomal-RNA-gene.fasta")
    fastaIndex.file <- file.path(data.directory, "ribosomal-RNA-gene.fasta.fai")
    annotation.file <- file.path(data.directory, "ribosomal-RNA-gene.gff3")

    expect_true(file.exists(fasta.file))
    expect_true(file.exists(fastaIndex.file))
    expect_true(file.exists(annotation.file))

    options <- parseAndValidateGenomeSpec(genomeName="ribosome local files",
                                          initialLocus="all", stockGenome=FALSE,
                                          dataMode="localFiles", fasta=fasta.file,
                                          fastaIndex=fastaIndex.file,
                                          genomeAnnotation=annotation.file)
    expect_true(options$validated)
    expect_false(options$stockGenome)
    expect_equal(options$dataMode, "localFiles")

    # A bogus file path should fail
    expect_error({
       fasta.file.bogus <- sprintf("%s-bogus", fasta.file)
       parseAndValidateGenomeSpec(genomeName="ribo-willFail",
                                  initialLocus="all", stockGenome=FALSE, dataMode="http",
                                  fasta=fasta.file.bogus, fastaIndex=fastaIndex.file,
                                  genomeAnnotation=annotation.file)
    })
})

test_that("Parsing SARS genome with GFF3 from local files works", {
    data.directory <- system.file(package="igvShiny", "extdata", "sarsGenome")
    fasta.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.dna.toplevel.fa")
    fastaIndex.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai")
    annotation.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.101.gff3")

    expect_true(file.exists(fasta.file))

    title <- "SARS-CoV-2"
    options <- parseAndValidateGenomeSpec(genomeName=title,
                                          initialLocus="all", stockGenome=FALSE,
                                          dataMode="localFiles", fasta=fasta.file,
                                          fastaIndex=fastaIndex.file,
                                          genomeAnnotation=annotation.file)
    expect_true(options$validated)
    expect_equal(options$genomeName, title)
    expect_false(options$stockGenome)
})

