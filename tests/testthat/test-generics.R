# getGenomicRegion, showGenomicRegion and removeTracksByName are S4 generics so
# that a package building on igvShiny (igvR) can add methods for its own class
# without masking these functions. The default "ANY" method must keep every
# existing (session, id, ...) call working.

test_that("the three region/track functions are S4 generics", {
  for (f in c("getGenomicRegion", "showGenomicRegion",
              "removeTracksByName")) {
    expect_true(methods::isGeneric(f, where = asNamespace("igvShiny")))
    expect_true(methods::existsMethod(f, "ANY",
                                      where = asNamespace("igvShiny")))
  }
  expect_named(formals(showGenomicRegion), c("session", "id", "region"))
  expect_named(formals(getGenomicRegion), c("session", "id"))
  expect_named(formals(removeTracksByName), c("session", "id", "trackNames"))
})

test_that("a method for a new S4 class dispatches; the default still works", {
  methods::setClass("dummyIgv", representation(calls = "environment"),
                    where = globalenv())
  on.exit(methods::removeClass("dummyIgv", where = globalenv()), add = TRUE)
  methods::setMethod("showGenomicRegion", "dummyIgv",
                     function(session, id, region) {
                       assign("region", id, envir = session@calls)
                       "dummy-show"
                     }, where = globalenv())
  methods::setMethod("getGenomicRegion", "dummyIgv",
                     function(session, id) "chr1:1-100", where = globalenv())
  methods::setMethod("removeTracksByName", "dummyIgv",
                     function(session, id, trackNames) "dummy-remove",
                     where = globalenv())
  on.exit({
    for (f in c("showGenomicRegion", "getGenomicRegion",
                "removeTracksByName")) {
      methods::removeMethod(f, "dummyIgv", where = globalenv())
    }
  }, add = TRUE, after = FALSE)

  # igvR-style calls: (igv, region) and (igv, trackNames)
  igv <- methods::new("dummyIgv", calls = new.env())
  expect_identical(showGenomicRegion(igv, "MEF2C"), "dummy-show")
  expect_identical(get("region", envir = igv@calls), "MEF2C")
  expect_identical(getGenomicRegion(igv), "chr1:1-100")
  expect_identical(removeTracksByName(igv, c("a", "b")), "dummy-remove")

  # the default method is untouched for a session
  session <- fake_session()
  showGenomicRegion(session, id = "igvShiny_0", "chr1:1-1000")
  expect_equal(last_message(session, "showGenomicRegion"),
               list(region = "chr1:1-1000", elementID = "igvShiny_0"))
  getGenomicRegion(session, id = "igvShiny_0")
  expect_equal(last_message(session, "getGenomicRegion"),
               list(elementID = "igvShiny_0"))
  removeTracksByName(session, id = "igvShiny_0", trackNames = "x")
  expect_equal(last_message(session, "removeTracksByName"),
               list(trackNames = "x", elementID = "igvShiny_0"))
})

test_that("the default methods work through a module's session_proxy", {
  module <- function(id) {
    shiny::moduleServer(id, function(input, output, session) {
      showGenomicRegion(session, id = session$ns("igvShiny_0"), "NDUFS2")
      getGenomicRegion(session, id = session$ns("igvShiny_0"))
      removeTracksByName(session, session$ns("igvShiny_0"), c("t1", "t2"))
    })
  }
  shiny::testServer(module, args = list(id = "mod"), {
    expect_s3_class(session, "session_proxy")
    # dispatch only: MockShinySession's own sendCustomMessage is used, so the
    # test does not depend on whether its bindings can be overridden
    for (f in c("showGenomicRegion", "getGenomicRegion",
                "removeTracksByName")) {
      defined <- methods::selectMethod(f, class(session))@defined
      expect_identical(as.character(defined), "ANY")
    }
    expect_no_error(
      showGenomicRegion(session, id = session$ns("igvShiny_0"), "MEF2C"))
    expect_no_error(getGenomicRegion(session, id = session$ns("igvShiny_0")))
    expect_no_error(removeTracksByName(session, session$ns("igvShiny_0"), "t3"))
  })
})
