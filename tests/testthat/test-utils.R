library(testthat)
library(igvShiny)

test_that("get_tracks_dir returns a valid character string", {
    # The checkmate test is good, so we can keep it inside an expect_true call
    expect_true(checkmate::test_string(get_tracks_dir()))
})

test_that(".tracksDir re-points the shiny resource path when it moves (#132)", {
  # simulate the tracks directory moving: point the resource path somewhere else
  # and check that the next .tracksDir() call brings it back in step
  moved <- file.path(tempdir(), "tracks-stale")
  dir.create(moved, showWarnings = FALSE, recursive = TRUE)
  shiny::removeResourcePath("tracks")
  shiny::addResourcePath("tracks", moved)

  dir <- igvShiny:::.tracksDir()

  served <- shiny::resourcePaths()[["tracks"]]
  expect_identical(normalizePath(served, winslash = "/", mustWork = FALSE),
                   normalizePath(dir, winslash = "/", mustWork = FALSE))
  # a file written into the returned directory is one shiny actually serves
  f <- tempfile(tmpdir = dir, fileext = ".bed")
  writeLines("chr1\t1\t2", f)
  expect_true(file.exists(file.path(served, basename(f))))
})

test_that("track files written for a session go when the session does (#152)", {
  session <- fake_session()
  tbl <- data.frame(chr = "chr1", start = 100, end = 200,
                    stringsAsFactors = FALSE)
  loadBedTrack(session, "igv", "one", tbl)
  loadBedTrack(session, "igv", "two", tbl)
  written <- session$userData$igvShinyTrackFiles$paths

  # two loads, two files, and one hook to remove both of them
  expect_length(written, 2L)
  expect_true(all(file.exists(written)))
  expect_length(session$endedCallbacks, 1L)

  end_session(session)
  expect_false(any(file.exists(written)))
})

test_that("a session without an onSessionEnded hook still gets a path (#152)", {
  # a stub session is no reason for a loader to error, here or downstream
  stub <- new.env(parent = emptyenv())
  path <- igvShiny:::.trackFile(stub, ".bed")

  expect_true(checkmate::test_string(path))
  expect_null(stub$userData)
})
