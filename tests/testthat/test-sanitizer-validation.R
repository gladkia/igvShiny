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

test_that("a multi-valued startup track url is rejected", {
  expect_warning(
    out <- sanitizeTracks(list(list(name = "t",
                                    url = c("https://a.bed", "https://b.bed")))),
    "no valid 'url'"
  )
  expect_length(out, 0L)
})

test_that("a startup track with no url field is dropped", {
  expect_warning(out <- sanitizeTracks(list(list(name = "t"))),
                 "no valid 'url'")
  expect_length(out, 0L)
})

test_that("a valid scalar url is still kept", {
  out <- sanitizeTracks(list(list(name = "t",
                                  url = "https://example.org/x.bed")))
  expect_length(out, 1L)
  expect_equal(out[[1]]$url, "https://example.org/x.bed")
})

# A merged track holds its members instead of a url of its own: that is how
# igv.js draws junction arcs over a coverage track in one panel (#103).

merged_track <- function(...) {
  list(type = "merged", name = "sashimi-ish",
       tracks = list(list(type = "wig", url = "https://example.org/a.bw"),
                     list(type = "junction", format = "bed",
                          url = "https://example.org/a.bed")),
       ...)
}

test_that("a merged track keeps its members and needs no url of its own", {
  out <- sanitizeTracks(list(merged_track()))
  expect_length(out, 1L)
  expect_length(out[[1]]$tracks, 2L)
  expect_equal(out[[1]]$tracks[[2]]$url, "https://example.org/a.bed")
})

test_that("member tracks are sanitized against the same allowlist", {
  track <- merged_track()
  track$tracks[[1]]$rmdir <- "/tmp"
  expect_warning(out <- sanitizeTracks(list(track)),
                 "invalid or unsupported")
  expect_null(out[[1]]$tracks[[1]]$rmdir)
  expect_equal(out[[1]]$tracks[[1]]$url, "https://example.org/a.bw")
})

test_that("a merged track left with no usable member is dropped", {
  track <- merged_track()
  track$tracks <- list(list(type = "wig", url = NA_character_))
  # two warnings: the member goes first, and the empty parent follows it
  warnings <- capture_warnings(out <- sanitizeTracks(list(track)))
  expect_match(warnings, "no valid 'url'", all = FALSE)
  expect_match(warnings, "no usable member", all = FALSE)
  expect_length(out, 0L)

  expect_warning(out <- sanitizeTracks(list(list(type = "merged", name = "m"))),
                 "no usable member")
  expect_length(out, 0L)
})

test_that("the merged type is matched the way igv.js matches it", {
  # igv.js dispatches on config.type.toLowerCase(). The field is overwritten
  # rather than passed through ..., which would append a second `type` that
  # track[["type"]] never reaches, and the assertion would hold either way.
  track <- merged_track()
  track$type <- "Merged"
  out <- sanitizeTracks(list(track))
  expect_length(out, 1L)
  expect_length(out[[1]]$tracks, 2L)
})

test_that("'tracks' stays unsupported on anything but a merged track", {
  expect_warning(
    out <- sanitizeTracks(list(list(type = "wig",
                                    url = "https://example.org/a.bw",
                                    tracks = list(list(url = "x"))))),
    "invalid or unsupported"
  )
  expect_length(out, 1L)
  expect_null(out[[1]]$tracks)
})

test_that("merged nesting is capped", {
  deep <- merged_track()
  for (i in seq_len(3)) {
    deep <- list(type = "merged", tracks = list(deep))
  }
  expect_warning(out <- sanitizeTracks(list(deep)), "nested more than")
  expect_length(out, 0L)
})

test_that("sanitized tracks carry no names, so they serialize as a JSON array", {
  # igv.js walks a merged track with for...of and calls .every() on the same
  # value; a named R list would reach it as an object and break both
  track <- merged_track()
  names(track$tracks) <- c("coverage", "junctions")
  out <- sanitizeTracks(list(one = track))
  expect_null(names(out))
  expect_null(names(out[[1]]$tracks))
})
