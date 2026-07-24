library(testthat)
library(igvShiny)

# trackConfig is user-supplied and goes straight into an igv.js track object, so
# the allowlist in .sanitizeAndMergeOptions is a security boundary as much as a
# convenience. .sanitizeTracks does the same job for the startup `tracks`
# argument (the regression fixed in #36). Neither had any test.

sanitizeAndMergeOptions <- igvShiny:::.sanitizeAndMergeOptions
sanitizeTracks <- igvShiny:::.sanitizeTracks

test_that("an empty or absent trackConfig leaves the base options alone", {
  base <- list(elementID = "igvShiny_0", trackName = "t")
  expect_equal(sanitizeAndMergeOptions(base, list()), base)
  expect_equal(sanitizeAndMergeOptions(base, NULL), base)
})

test_that("valid igv.js options are merged in", {
  base <- list(elementID = "igvShiny_0", trackName = "t")
  merged <- sanitizeAndMergeOptions(base, list(height = 120, autoscale = TRUE))
  expect_equal(merged$height, 120)
  expect_true(merged$autoscale)
  expect_equal(merged$trackName, "t")
})

test_that("options outside the allowlist are dropped with a warning", {
  base <- list(elementID = "igvShiny_0")
  expect_warning(
    merged <- sanitizeAndMergeOptions(base, list(onClick = "alert(1)")),
    "invalid or unsupported"
  )
  expect_null(merged$onClick)
})

test_that("user options never override the function's own arguments", {
  base <- list(elementID = "igvShiny_0", trackName = "mine", color = "blue")
  expect_warning(
    merged <- sanitizeAndMergeOptions(base, list(trackName = "theirs")),
    "conflict with function arguments"
  )
  expect_equal(merged$trackName, "mine")
})

test_that("a trackConfig that is not a named list is refused", {
  base <- list(elementID = "igvShiny_0")
  expect_warning(merged <- sanitizeAndMergeOptions(base, list(1, 2)),
                 "must be a named list")
  expect_equal(merged, base)
})

test_that("autoscaleGroup survives as both number and string (#105)", {
  base <- list(elementID = "igvShiny_0")
  expect_equal(sanitizeAndMergeOptions(base, list(autoscaleGroup = 3))$autoscaleGroup, 3)
  expect_equal(sanitizeAndMergeOptions(base, list(autoscaleGroup = "grp"))$autoscaleGroup, "grp")
})

test_that("startup tracks keep their valid keys and lose the invalid ones", {
  tracks <- list(list(name = "genes", type = "annotation",
                      url = "https://example.org/g.gff3", bogusKey = 1))
  expect_warning(out <- sanitizeTracks(tracks), "invalid or unsupported")
  expect_length(out, 1L)
  expect_null(out[[1]]$bogusKey)
  expect_equal(out[[1]]$name, "genes")
})

test_that("a startup track without a url is dropped", {
  expect_warning(out <- sanitizeTracks(list(list(name = "no url"))),
                 "no valid 'url'")
  expect_length(out, 0L)
})

test_that("an unnamed startup track entry is dropped", {
  expect_warning(out <- sanitizeTracks(list(list("a", "b"))),
                 "must be a named list")
  expect_length(out, 0L)
})

test_that("an empty tracks argument yields an empty list, not NULL (#36)", {
  expect_equal(sanitizeTracks(list()), list())
  expect_equal(sanitizeTracks(NULL), list())
})
