library(testthat)
library(igvShiny)

test_that(".serveFileWithHttpRange returns 404 for non-existent files", {
  req <- as.environment(list(REQUEST_METHOD = "GET", PATH_INFO = "/test"))
  resp <- igvShiny:::.serveFileWithHttpRange("/non/existent/file.bin", req)
  expect_equal(resp$status, 404L)
})

test_that(".serveFileWithHttpRange returns 200 for full-file requests", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(as.raw(0:99), tmp)

  req <- as.environment(list(REQUEST_METHOD = "GET", PATH_INFO = "/test"))
  resp <- igvShiny:::.serveFileWithHttpRange(tmp, req)

  expect_equal(resp$status, 200L)
  expect_equal(resp$headers[["Accept-Ranges"]], "bytes")
  expect_equal(resp$headers[["Content-Length"]], "100")
  expect_equal(as.integer(resp$content), 0:99)
})

test_that(".serveFileWithHttpRange returns 206 with correct byte slices", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(as.raw(0:255), tmp)

  # Range: bytes=10-20 (11 bytes)
  req <- as.environment(list(
    REQUEST_METHOD = "GET",
    PATH_INFO = "/test",
    HTTP_RANGE = "bytes=10-20"
  ))
  resp <- igvShiny:::.serveFileWithHttpRange(tmp, req)

  expect_equal(resp$status, 206L)
  expect_equal(resp$headers[["Content-Range"]], "bytes 10-20/256")
  expect_equal(resp$headers[["Content-Length"]], "11")
  expect_equal(resp$headers[["Accept-Ranges"]], "bytes")
  expect_equal(as.integer(resp$content), 10:20)

  # Range: open-ended bytes=250-
  req2 <- as.environment(list(
    REQUEST_METHOD = "GET",
    PATH_INFO = "/test",
    HTTP_RANGE = "bytes=250-"
  ))
  resp2 <- igvShiny:::.serveFileWithHttpRange(tmp, req2)

  expect_equal(resp2$status, 206L)
  expect_equal(resp2$headers[["Content-Range"]], "bytes 250-255/256")
  expect_equal(resp2$headers[["Content-Length"]], "6")
  expect_equal(as.integer(resp2$content), 250:255)
})

test_that(".serveFileWithHttpRange returns 416 for unsatisfiable ranges", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(as.raw(0:49), tmp)

  # Start beyond file size
  req1 <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=100-200"
  ))
  resp1 <- igvShiny:::.serveFileWithHttpRange(tmp, req1)
  expect_equal(resp1$status, 416L)

  # End before start
  req2 <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=30-20"
  ))
  resp2 <- igvShiny:::.serveFileWithHttpRange(tmp, req2)
  expect_equal(resp2$status, 416L)

  # Suffix 0 is invalid
  req3 <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=-0"
  ))
  resp3 <- igvShiny:::.serveFileWithHttpRange(tmp, req3)
  expect_equal(resp3$status, 416L)
})

test_that(".serveFileWithHttpRange handles suffix ranges correctly", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(as.raw(0:99), tmp) # 100 bytes

  # Range: bytes=-10 (last 10 bytes: 90-99)
  req <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=-10"
  ))
  resp <- igvShiny:::.serveFileWithHttpRange(tmp, req)
  expect_equal(resp$status, 206L)
  expect_equal(resp$headers[["Content-Range"]], "bytes 90-99/100")
  expect_equal(resp$headers[["Content-Length"]], "10")
  expect_equal(as.integer(resp$content), 90:99)

  # Range: bytes=-200 (suffix larger than file -> returns all 100 bytes)
  req2 <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=-200"
  ))
  resp2 <- igvShiny:::.serveFileWithHttpRange(tmp, req2)
  expect_equal(resp2$status, 206L)
  expect_equal(resp2$headers[["Content-Range"]], "bytes 0-99/100")
  expect_equal(resp2$headers[["Content-Length"]], "100")
  expect_equal(as.integer(resp2$content), 0:99)
})

test_that(".serveFileWithHttpRange ignores multiple or malformed ranges and returns 200", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(as.raw(0:49), tmp)

  # Multiple ranges (unsupported per RFC 7233 Section 4.3 -> ignore and return 200)
  req_multi <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=0-10,20-30"
  ))
  resp_multi <- igvShiny:::.serveFileWithHttpRange(tmp, req_multi)
  expect_equal(resp_multi$status, 200L)
  expect_equal(resp_multi$headers[["Content-Length"]], "50")
  expect_equal(length(resp_multi$content), 50L)

  # Malformed range (ignore and return 200)
  req_malformed <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=abc-xyz"
  ))
  resp_malformed <- igvShiny:::.serveFileWithHttpRange(tmp, req_malformed)
  expect_equal(resp_malformed$status, 200L)
  expect_equal(resp_malformed$headers[["Content-Length"]], "50")
})

test_that(".serveFileWithHttpRange works on real BAM and BAI sample files", {
  bam_file <- system.file(package = "igvShiny", "extdata", "A_2_A24_02_01_01.nanopore.minimap.sorted.bam")
  bai_file <- paste0(bam_file, ".bai")
  skip_if_not(file.exists(bam_file) && file.exists(bai_file))

  # BAM header slice (first 64 KB)
  req_bam <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=0-65535"
  ))
  resp_bam <- igvShiny:::.serveFileWithHttpRange(bam_file, req_bam)
  expect_equal(resp_bam$status, 206L)
  expect_equal(length(resp_bam$content), 65536L)
  # Verify BGZF / gzip header magic bytes (0x1f, 0x8b)
  expect_equal(resp_bam$content[1], as.raw(0x1f))
  expect_equal(resp_bam$content[2], as.raw(0x8b))

  # BAI header slice (first 4 bytes: BAI\1)
  req_bai <- as.environment(list(
    REQUEST_METHOD = "GET",
    HTTP_RANGE = "bytes=0-3"
  ))
  resp_bai <- igvShiny:::.serveFileWithHttpRange(bai_file, req_bai)
  expect_equal(resp_bai$status, 206L)
  expect_equal(rawToChar(resp_bai$content), "BAI\001")
})

test_that("serveLocalFile registers file with session and returns valid relative URL", {
  tmp <- tempfile(fileext = ".bam")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(as.raw(1:10), tmp)

  session <- fake_session()
  url <- serveLocalFile(session, tmp)

  expect_true(is.character(url))
  expect_match(url, sprintf("^session/%s/dataobj/", session$token))
  expect_match(url, basename(tmp))
  expect_true(length(session$registeredDataObjs) >= 1L)

  # Input validation
  expect_error(serveLocalFile(123, tmp))
  expect_error(serveLocalFile(session, "/non/existent/path.bam"))
})

test_that("loadBamTrackFromLocalFile sends loadBamTrackFromURL custom message", {
  bam_file <- system.file(package = "igvShiny", "extdata", "A_2_A24_02_01_01.nanopore.minimap.sorted.bam")
  bai_file <- paste0(bam_file, ".bai")
  skip_if_not(file.exists(bam_file) && file.exists(bai_file))

  session <- fake_session()

  loadBamTrackFromLocalFile(
    session = session,
    id = "igvTest",
    trackName = "Nanopore Reads",
    bamFile = bam_file,
    indexFile = bai_file,
    displayMode = "SQUISHED"
  )

  msg <- last_message(session, "loadBamTrackFromURL")
  expect_equal(msg$elementID, "igvTest")
  expect_equal(msg$trackName, "Nanopore Reads")
  expect_equal(msg$displayMode, "SQUISHED")
  expect_match(msg$bam, sprintf("^session/%s/dataobj/", session$token))
  expect_match(msg$index, sprintf("^session/%s/dataobj/", session$token))
})

test_that("loadBamTrackFromLocalData delegates character BAM path to loadBamTrackFromLocalFile", {
  bam_file <- system.file(package = "igvShiny", "extdata", "A_2_A24_02_01_01.nanopore.minimap.sorted.bam")
  bai_file <- paste0(bam_file, ".bai")
  skip_if_not(file.exists(bam_file) && file.exists(bai_file))

  session <- fake_session()

  loadBamTrackFromLocalData(
    session = session,
    id = "igvTest",
    trackName = "Nanopore Delegated",
    data = bam_file,
    displayMode = "COLLAPSED"
  )

  msg <- last_message(session, "loadBamTrackFromURL")
  expect_equal(msg$elementID, "igvTest")
  expect_equal(msg$trackName, "Nanopore Delegated")
  expect_equal(msg$displayMode, "COLLAPSED")
  expect_match(msg$bam, sprintf("^session/%s/dataobj/", session$token))
})

test_that("loadCramTrackFromLocalData uses serveLocalFile with Range support", {
  tmp_cram <- tempfile(fileext = ".cram")
  tmp_crai <- tempfile(fileext = ".crai")
  on.exit(unlink(c(tmp_cram, tmp_crai)), add = TRUE)
  writeBin(as.raw(1:10), tmp_cram)
  writeBin(as.raw(1:10), tmp_crai)

  session <- fake_session()

  loadCramTrackFromLocalData(
    session = session,
    id = "igvCram",
    trackName = "Local CRAM",
    cramFile = tmp_cram,
    indexFile = tmp_crai
  )

  msg <- last_message(session, "loadCramTrackFromURL")
  expect_equal(msg$elementID, "igvCram")
  expect_equal(msg$trackName, "Local CRAM")
  expect_match(msg$cram, sprintf("^session/%s/dataobj/", session$token))
  expect_match(msg$index, sprintf("^session/%s/dataobj/", session$token))
})

test_that(".sanitizeTracks normalises 'index' to 'indexURL'", {
  tracks <- list(
    list(
      name = "Test BAM",
      type = "alignment",
      format = "bam",
      url = "http://example.com/test.bam",
      index = "http://example.com/test.bam.bai"
    )
  )

  sanitized <- igvShiny:::.sanitizeTracks(tracks)
  expect_equal(length(sanitized), 1L)
  expect_equal(sanitized[[1]]$url, "http://example.com/test.bam")
  expect_equal(sanitized[[1]]$indexURL, "http://example.com/test.bam.bai")
  expect_null(sanitized[[1]][["index"]])
  expect_false("index" %in% names(sanitized[[1]]))
})
