library(testthat)
library(igvShiny)

# Edge cases in the two input sanitizers, flagged by review on #127. Both are
# pure functions, so they need no Shiny session.

sanitizeAndMergeOptions <- igvShiny:::.sanitizeAndMergeOptions
sanitizeTracks <- igvShiny:::.sanitizeTracks

test_that("a NA-named trackConfig warns and is ignored, not an error", {
  base <- list(elementID = "igvShiny_0")
  bad <- list(1)
  names(bad) <- NA_character_
  # before the fix this raised "missing value where TRUE/FALSE needed"
  expect_warning(out <- sanitizeAndMergeOptions(base, bad),
                 "must be a named list")
  expect_equal(out, base)
})

test_that("a startup track url must be a non-empty scalar string", {
  for (bad_url in list(NA_character_, "", character(0))) {
    expect_warning(out <- sanitizeTracks(list(list(name = "t", url = bad_url))),
                   "no valid 'url'")
    expect_length(out, 0L)
  }
})

test_that("a non-character startup track url is rejected", {
  expect_warning(out <- sanitizeTracks(list(list(name = "t", url = 42))),
                 "no valid 'url'")
  expect_length(out, 0L)
})

test_that("a valid scalar url is still kept", {
  out <- sanitizeTracks(list(list(name = "t",
                                  url = "https://example.org/x.bed")))
  expect_length(out, 1L)
  expect_equal(out[[1]]$url, "https://example.org/x.bed")
})
