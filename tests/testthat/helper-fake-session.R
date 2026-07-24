# A minimal stand-in for the Shiny session object.
#
# Every track loader ends in `session$sendCustomMessage(type, message)`, so a
# fake session that records those calls lets the loaders be tested without a
# browser. That matters for coverage as well as speed: the shinytest2 tests run
# the app in a separate process, which covr cannot instrument, so everything
# exercised only through them counts as uncovered.

fake_session <- function() {
  self <- new.env(parent = emptyenv())
  self$messages <- list()
  self$sendCustomMessage <- function(type, message) {
    self$messages[[length(self$messages) + 1L]] <-
      list(type = type, message = message)
    invisible(NULL)
  }
  self
}

# The messages recorded so far, optionally narrowed to one message type.
sent_messages <- function(session, type = NULL) {
  if (is.null(type)) {
    return(session$messages)
  }
  Filter(function(m) identical(m$type, type), session$messages)
}

# The payload of the last message of `type`; fails the test if none was sent,
# which gives a clearer report than indexing into an empty list.
last_message <- function(session, type) {
  msgs <- sent_messages(session, type)
  testthat::expect_gt(length(msgs), 0L)
  msgs[[length(msgs)]]$message
}
