testthat::test_that("checkReferenceCompatibility accurately identifies BAM contig and assembly compatibility and mismatches", {
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
})

testthat::test_that("loadBedTrack emits warning and UI toast on reference mismatch, silenced by validateReference=FALSE", {
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
  testthat::expect_silent(
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

  testthat::expect_silent(
    loadBedGraphTrack(session, "igvTest", "OOB BedGraph Silenced", bg_oob,
                      autoscale = TRUE, validateReference = FALSE)
  )
})

testthat::test_that("loadBamTrackFromLocalFile emits warning on assembly mismatch, silenced by validateReference=FALSE", {
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
  testthat::expect_silent(
    loadBamTrackFromLocalFile(session, "igvTest", "Tumor Reads Silenced",
                              bamFile = bam_file, indexFile = bai_file,
                              validateReference = FALSE)
  )
})
