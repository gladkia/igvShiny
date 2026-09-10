testthat::test_that(
  "checkReferenceCompatibility accurately identifies BAM contig and assembly compatibility and mismatches", {
  bam_file <- system.file(package = "igvShiny", "extdata", "tumor.bam")
  testthat::skip_if_not(file.exists(bam_file))

  # tumor.bam in inst/extdata has contigs chr1..chr22, chrX, chrY aligned to GRCh38 (chr1 = 248,956,422 bp)
  # 1. Check against hg38: should be compatible!
  res_hg38 <- checkReferenceCompatibility(bam_file, genomeName = "hg38")
  testthat::expect_true(res_hg38$compatible)
  testthat::expect_false(res_hg38$details$namingMismatch)
  testthat::expect_length(res_hg38$details$lengthMismatches, 0L)
  testthat::expect_equal(res_hg38$targetAssembly, "GRCh38/hg38")

  # 2. Check against hg19: assembly mismatch (248,956,422 vs 249,250,621 for chr1)
  res_hg19 <- checkReferenceCompatibility(bam_file, genomeName = "hg19")
  testthat::expect_false(res_hg19$compatible)
  testthat::expect_gt(length(res_hg19$details$lengthMismatches), 0L)
  testthat::expect_match(res_hg19$mismatches[1], "Genome assembly mismatch")
})

testthat::test_that("checkReferenceCompatibility parses CRAM header contigs cleanly", {
  rhtslib_cram <- system.file("testdata", "range.cram", package = "Rhtslib")
  testthat::skip_if(rhtslib_cram == "" || !file.exists(rhtslib_cram),
                    "Rhtslib testdata range.cram not found")

  ti <- igvShiny:::.extractCramContigs(rhtslib_cram)
  testthat::expect_type(ti, "list")
  testthat::expect_true("CHROMOSOME_I" %in% names(ti$contigs))
  testthat::expect_equal(ti$contigs[["CHROMOSOME_I"]], 1009800L)

  # Check against hg38: non-standard C. elegans chromosome names should not crash
  res <- checkReferenceCompatibility(rhtslib_cram, genomeName = "hg38")
  testthat::expect_type(res$compatible, "logical")
})

testthat::test_that("checkReferenceCompatibility detects VCF contig mismatches", {
  vcf_file <- system.file(package = "igvShiny", "extdata", "chr19-cebpaRegion.vcf.gz")
  testthat::skip_if_not(file.exists(vcf_file))

  # chr19-cebpaRegion.vcf.gz is aligned to hs37d5 (GRCh37), bare chroms (1, 2, ..., 19)
  # Against hg38: both naming mismatch (bare vs chr) and length mismatch (b37 vs hg38)
  res_hg38 <- checkReferenceCompatibility(vcf_file, genomeName = "hg38")
  testthat::expect_false(res_hg38$compatible)
  testthat::expect_true(res_hg38$details$namingMismatch)
  testthat::expect_gt(length(res_hg38$details$lengthMismatches), 0L)

  # Against hg19: assembly matches, but naming differs (bare 1 vs chr1)
  res_hg19 <- checkReferenceCompatibility(vcf_file, genomeName = "hg19")
  testthat::expect_false(res_hg19$compatible)
  testthat::expect_true(res_hg19$details$namingMismatch)
  testthat::expect_equal(length(res_hg19$details$lengthMismatches), 0L)

  foreign_vcf <- tempfile(fileext = ".vcf")
  writeLines(c(
    "##fileformat=VCFv4.2",
    "##contig=<ID=chr1,length=248956422>",
    "##contig=<ID=chrExtra,length=50000>",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr1\t100\t.\tA\tT\t.\t.\t.",
    "chrExtra\t100\t.\tA\tT\t.\t.\t."
  ), foreign_vcf)
  on.exit(unlink(foreign_vcf), add = TRUE)

  foreign_res <- checkReferenceCompatibility(foreign_vcf, genomeName = "hg38")
  testthat::expect_false(foreign_res$compatible)
  testthat::expect_equal(foreign_res$details$missingContigs, "chrExtra")
})

testthat::test_that("checkReferenceCompatibility validates BED and bedGraph data frames", {
  # Compatible BED table
  bed_ok <- data.frame(
    chr = c("chr1", "chr2"),
    start = c(100L, 200L),
    end = c(1000L, 2000L),
    stringsAsFactors = FALSE
  )
  res_ok <- checkReferenceCompatibility(bed_ok, genomeName = "hg38")
  testthat::expect_true(res_ok$compatible)
  testthat::expect_length(res_ok$mismatches, 0L)

  # Naming mismatch: bare contigs on hg38
  bed_bare <- data.frame(
    chr = c("1", "2"),
    start = c(100L, 200L),
    end = c(1000L, 2000L),
    stringsAsFactors = FALSE
  )
  res_bare <- checkReferenceCompatibility(bed_bare, genomeName = "hg38")
  testthat::expect_false(res_bare$compatible)
  testthat::expect_true(res_bare$details$namingMismatch)
  testthat::expect_match(res_bare$mismatches[1], "Contig naming mismatch")

  # Coordinate out of bounds: chr21 length in hg38 is 46,709,983
  bed_oob <- data.frame(
    chr = c("chr21"),
    start = c(47000000L),
    end = c(47500000L),
    stringsAsFactors = FALSE
  )
  res_oob <- checkReferenceCompatibility(bed_oob, genomeName = "hg38")
  testthat::expect_false(res_oob$compatible)
  testthat::expect_gt(length(res_oob$details$outOfBounds), 0L)
  testthat::expect_match(res_oob$mismatches[1], "Coordinate out-of-bounds")
})

testthat::test_that("checkReferenceCompatibility supports custom genomes with fastaIndex", {
  temp_fai <- tempfile(fileext = ".fai")
  writeLines(
    c("chrTest1\t10000\t0\t50\t51",
      "chrTest2\t20000\t10000\t50\t51"),
    temp_fai
  )
  on.exit(unlink(temp_fai), add = TRUE)

  custom_spec <- list(
    genomeName = "customMock",
    stockGenome = FALSE,
    dataMode = "localFiles",
    fasta = "customMock.fa",
    fastaIndex = temp_fai,
    annotation = NA_character_,
    validated = TRUE
  )

  # Matching BED
  bed_custom_ok <- data.frame(
    chr = "chrTest1",
    start = 50L,
    end = 500L,
    stringsAsFactors = FALSE
  )
  res1 <- checkReferenceCompatibility(bed_custom_ok, genomeSpec = custom_spec)
  testthat::expect_true(res1$compatible)

  # OOB BED on custom genome (>10000 on chrTest1)
  bed_custom_oob <- data.frame(
    chr = "chrTest1",
    start = 12000L,
    end = 15000L,
    stringsAsFactors = FALSE
  )
  res2 <- checkReferenceCompatibility(bed_custom_oob, genomeSpec = custom_spec)
  testthat::expect_false(res2$compatible)
  testthat::expect_match(res2$mismatches[1], "Coordinate out-of-bounds")

  custom_alignments <- GenomicRanges::GRanges(
    c("chrTest1", "chrExtra"), IRanges::IRanges(c(1L, 1L), width = 100L)
  )
  GenomeInfoDb::seqlengths(custom_alignments) <- c(
    chrTest1 = 10000L, chrExtra = 5000L
  )
  res3 <- checkReferenceCompatibility(custom_alignments, genomeSpec = custom_spec)
  testthat::expect_false(res3$compatible)
  testthat::expect_equal(res3$details$missingContigs, "chrExtra")
})

testthat::test_that(
  "loadBedTrack emits warning and UI toast on reference mismatch, silenced by validateReference=FALSE", {
  session <- fake_session()
  on.exit(end_session(session), add = TRUE)

  # Register hg38 genome for session
  igvShiny:::.registerGenomeSpec(session, "igvTest", list(genomeName = "hg38", stockGenome = TRUE))

  # BED with bare '1' on hg38 reference
  bed_mismatch <- data.frame(
    chr = "1",
    start = 100L,
    end = 500L,
    stringsAsFactors = FALSE
  )

  # 1. With validateReference = TRUE (default): warning + notification
  testthat::expect_warning(
    loadBedTrack(session, "igvTest", "Test Bed Mismatch", bed_mismatch),
    "Reference incompatibility detected"
  )
  testthat::expect_gt(length(sent_notifications(session)), 0L)
  last_notif <- last_notification(session)
  testthat::expect_equal(last_notif$message$type, "warning")
  testthat::expect_match(last_notif$message$html, "Contig naming mismatch")

  # 2. With validateReference = FALSE: no warning, no new notification
  notif_count_before <- length(sent_notifications(session))
  testthat::expect_no_warning(
    loadBedTrack(session, "igvTest", "Test Bed Silenced", bed_mismatch,
                 validateReference = FALSE)
  )
  testthat::expect_equal(length(sent_notifications(session)), notif_count_before)
})

testthat::test_that("loadBedGraphTrack respects validateReference flag", {
  session <- fake_session()
  on.exit(end_session(session), add = TRUE)

  igvShiny:::.registerGenomeSpec(session, "igvTest", list(genomeName = "hg38", stockGenome = TRUE))

  # OOB bedGraph
  bg_oob <- data.frame(
    chr = "chr21",
    start = 47000000L,
    end = 47500000L,
    score = 12.5,
    stringsAsFactors = FALSE
  )

  testthat::expect_warning(
    loadBedGraphTrack(session, "igvTest", "OOB BedGraph", bg_oob, autoscale = TRUE),
    "Coordinate out-of-bounds"
  )

  testthat::expect_no_warning(
    loadBedGraphTrack(session, "igvTest", "OOB BedGraph Silenced", bg_oob,
                      autoscale = TRUE, validateReference = FALSE)
  )
})

testthat::test_that(
  "loadBamTrackFromLocalFile emits warning on assembly mismatch, silenced by validateReference=FALSE", {
  bam_file <- system.file(package = "igvShiny", "extdata", "tumor.bam")
  bai_file <- system.file(package = "igvShiny", "extdata", "tumor.bam.bai")
  testthat::skip_if_not(file.exists(bam_file) && file.exists(bai_file))

  session <- fake_session()
  on.exit(end_session(session), add = TRUE)

  # Active reference is hg19, while tumor.bam is hg38
  igvShiny:::.registerGenomeSpec(session, "igvTest", list(genomeName = "hg19", stockGenome = TRUE))

  # 1. validateReference = TRUE: warns on tumor.bam (GRCh38 on hg19)
  testthat::expect_warning(
    loadBamTrackFromLocalFile(session, "igvTest", "Tumor Reads",
                              bamFile = bam_file, indexFile = bai_file),
    "Genome assembly mismatch"
  )

  # 2. validateReference = FALSE: silenced
  testthat::expect_no_warning(
    loadBamTrackFromLocalFile(session, "igvTest", "Tumor Reads Silenced",
                              bamFile = bam_file, indexFile = bai_file,
                              validateReference = FALSE)
  )
})

testthat::test_that("igvShiny registers the on-disk custom genome spec, not the served paths", {
  d <- system.file(package = "igvShiny", "extdata", "sarsGenome")
  testthat::skip_if_not(dir.exists(d))

  spec <- parseAndValidateGenomeSpec(
    "sarsGenome", "NC_045512.2:1-100",
    stockGenome = FALSE, dataMode = "localFiles",
    fasta = file.path(d, "Sars_cov_2.ASM985889v3.dna.toplevel.fa"),
    fastaIndex = file.path(d, "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai"),
    genomeAnnotation = file.path(d, "Sars_cov_2.ASM985889v3.101.gff3")
  )
  invisible(igvShiny(spec))

  # igvShiny() rewrites fastaIndex to a served path; the registered spec must
  # still carry the readable one, or the check silently passes everything
  registered <- igvShiny:::.getGenomeSpec(NULL)
  testthat::expect_gt(length(igvShiny:::.getReferenceContigs(registered)), 0L)

  human_bed <- data.frame(chr = "chr1", start = 1e6, end = 2e6,
                          stringsAsFactors = FALSE)
  res <- checkReferenceCompatibility(human_bed, genomeSpec = registered)
  testthat::expect_false(res$compatible)
})

testthat::test_that("genome spec is keyed on the output id the track loaders use", {
  opts <- parseAndValidateGenomeSpec("hg38", "chr1:1-1000")

  shiny::testServer(function(input, output, session) {
    output$igvShiny_0 <- renderIgvShiny(igvShiny(opts))
  }, {
    invisible(output$igvShiny_0)
    testthat::expect_true("igvShiny_0" %in% ls(session$userData$igvShinyGenomeSpecs))
  })

  shiny::testServer(function(id) {
    shiny::moduleServer(id, function(input, output, session) {
      output$igv <- renderIgvShiny(igvShiny(opts))
    })
  }, args = list(id = "mod1"), {
    invisible(output$igv)
    testthat::expect_true("mod1-igv" %in% ls(session$userData$igvShinyGenomeSpecs))
  })
})

testthat::test_that("unresolvable widget id skips the check instead of guessing a genome", {
  session <- fake_session()
  on.exit(end_session(session), add = TRUE)

  igvShiny:::.registerGenomeSpec(session, NULL, list(genomeName = "hg38", stockGenome = TRUE))
  igvShiny:::.registerGenomeSpec(session, NULL, list(genomeName = "mm10", stockGenome = TRUE))

  # chr2:189-190 Mb is in bounds on hg38 and out of bounds on mm10; guessing
  # the last spec would raise a mismatch for a track that is fine
  testthat::expect_null(igvShiny:::.getGenomeSpec(session, "igvShiny_0"))

  bed <- data.frame(chr = "chr2", start = 189e6, end = 190e6, stringsAsFactors = FALSE)
  testthat::expect_no_warning(loadBedTrack(session, "igvShiny_0", "ambiguous", bed))

  # one genome only: the fallback still applies
  single <- fake_session()
  on.exit(end_session(single), add = TRUE)
  igvShiny:::.registerGenomeSpec(single, NULL, list(genomeName = "hg38", stockGenome = TRUE))
  testthat::expect_equal(igvShiny:::.getGenomeSpec(single, "igvShiny_0")$genomeName, "hg38")
})

testthat::test_that("compatibility rejects absent and inconsistently named contigs", {
  missing <- data.frame(chr = "chr99", start = 1L, end = 100L)
  missing_res <- checkReferenceCompatibility(missing, genomeName = "hg38")
  testthat::expect_true(missing_res$checked)
  testthat::expect_false(missing_res$compatible)
  testthat::expect_equal(missing_res$details$missingContigs, "chr99")

  mixed <- data.frame(
    chr = c("chr1", "2"),
    start = c(1L, 1L),
    end = c(100L, 100L)
  )
  mixed_res <- checkReferenceCompatibility(mixed, genomeName = "hg38")
  testthat::expect_false(mixed_res$compatible)
  testthat::expect_true(mixed_res$details$namingMismatch)

  chr21 <- data.frame(chr = "21", start = 1L, end = 100L)
  chr21_res <- checkReferenceCompatibility(chr21, genomeName = "hg38")
  testthat::expect_false(chr21_res$compatible)
  testthat::expect_true(chr21_res$details$namingMismatch)
})

testthat::test_that("compatibility checks every BED row and rejects invalid ranges", {
  bed_file <- tempfile(fileext = ".bed")
  bed <- data.frame(
    chr = rep("chr1", 1001L),
    start = rep(1L, 1001L),
    end = c(rep(100L, 1000L), 300000000L)
  )
  utils::write.table(bed, bed_file, sep = "\t", row.names = FALSE,
                     col.names = FALSE, quote = FALSE)
  on.exit(unlink(bed_file), add = TRUE)

  file_res <- checkReferenceCompatibility(bed_file, genomeName = "hg38")
  testthat::expect_true(file_res$checked)
  testthat::expect_false(file_res$compatible)
  testthat::expect_length(file_res$details$outOfBounds, 1L)

  negative <- data.frame(chr = "chr1", start = -100L, end = -1L)
  negative_res <- checkReferenceCompatibility(negative, genomeName = "hg38")
  testthat::expect_false(negative_res$compatible)
  testthat::expect_equal(negative_res$details$invalidCoordinates, 1L)

  reversed <- data.frame(chr = "chr1", start = 100L, end = 1L)
  reversed_res <- checkReferenceCompatibility(reversed, genomeName = "hg38")
  testthat::expect_false(reversed_res$compatible)
  testthat::expect_equal(reversed_res$details$invalidCoordinates, 1L)

  missing <- data.frame(chr = "chr1", start = NA_real_, end = 100L)
  missing_res <- checkReferenceCompatibility(missing, genomeName = "hg38")
  testthat::expect_false(missing_res$compatible)
  testthat::expect_equal(missing_res$details$invalidCoordinates, 1L)

  non_numeric <- data.frame(V1 = "chr1", V2 = "not-a-coordinate", V3 = "100")
  non_numeric_res <- checkReferenceCompatibility(non_numeric, genomeName = "hg38")
  testthat::expect_false(non_numeric_res$compatible)
  testthat::expect_equal(non_numeric_res$details$invalidCoordinates, 1L)
})

testthat::test_that("canonical genome names are matched case-insensitively", {
  bed <- data.frame(chr = "chrI", start = 1L, end = 5000000L)

  for (genome_name in c("sacCer3", "saccer3", "SACCER3",
                        "https://example.org/SacCer3.fa")) {
    res <- checkReferenceCompatibility(bed, genomeName = genome_name)
    testthat::expect_true(res$checked, info = genome_name)
    testthat::expect_false(res$compatible, info = genome_name)
    testthat::expect_length(res$details$outOfBounds, 1L)
  }
})

testthat::test_that("compatibility reports when validation could not run", {
  bed <- data.frame(chr = "chr1", start = 1L, end = 100L)
  res <- checkReferenceCompatibility(bed, genomeName = "not-a-genome")
  testthat::expect_false(res$checked)
  testthat::expect_true(is.na(res$compatible))
})

testthat::test_that("custom FASTA indexes preserve literal contig names", {
  fai <- tempfile(fileext = ".fai")
  writeLines("chr#1\t1000\t0\t50\t51", fai)
  on.exit(unlink(fai), add = TRUE)
  spec <- list(genomeName = "custom", stockGenome = FALSE, fastaIndex = fai)

  bed <- data.frame(chr = "chr#1", start = 1L, end = 2000L)
  res <- checkReferenceCompatibility(bed, genomeSpec = spec)
  testthat::expect_true(res$checked)
  testthat::expect_false(res$compatible)
  testthat::expect_length(res$details$outOfBounds, 1L)
})

testthat::test_that("all canonical reference contig lengths are compared", {
  dm6 <- GenomicRanges::GRanges("chr2L", IRanges::IRanges(1L, 100L))
  GenomeInfoDb::seqlengths(dm6) <- c(chr2L = 999L)

  res <- checkReferenceCompatibility(dm6, genomeName = "dm6")
  testthat::expect_true(res$checked)
  testthat::expect_false(res$compatible)
  testthat::expect_length(res$details$lengthMismatches, 1L)
})

testthat::test_that("Rsamtools BAM headers retain the assembly tag", {
  testthat::skip_if_not_installed("Rsamtools")
  bam_file <- system.file(package = "igvShiny", "extdata", "tumor.bam")
  testthat::skip_if_not(file.exists(bam_file))

  info <- igvShiny:::.extractBamContigs(bam_file)
  testthat::expect_equal(info$assembly, "GRCh38")
})
