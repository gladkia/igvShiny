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
  # loaders park the files they write in userData and unlink them from an
  # onSessionEnded hook, so a fake without those two leaks past every test
  self$userData <- new.env(parent = emptyenv())
  self$endedCallbacks <- list()
  self$onSessionEnded <- function(callback) {
    self$endedCallbacks <- c(self$endedCallbacks, callback)
    invisible(NULL)
  }
  self$token <- "fake_session_token_123"
  self$notifications <- list()
  self$sendNotification <- function(action, message) {
    self$notifications[[length(self$notifications) + 1L]] <-
      list(action = action, message = message)
    invisible(NULL)
  }
  self$registeredDataObjs <- list()
  self$registerDataObj <- function(name, data, filterFunc) {
    self$registeredDataObjs[[name]] <-
      list(name = name, data = data, filterFunc = filterFunc)
    sprintf("session/%s/dataobj/%s?w=0&nonce=123", self$token, name)
  }
  class(self) <- c("ShinySession", "environment")
  self
}

# Close a fake session, the way shiny closes a real one when its websocket goes.
end_session <- function(session) {
  for (callback in session$endedCallbacks) {
    callback()
  }
  invisible(NULL)
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

# The notifications recorded by fake_session so far.
sent_notifications <- function(session) {
  session$notifications
}

# The payload of the last notification sent.
last_notification <- function(session) {
  notes <- sent_notifications(session)
  testthat::expect_gt(length(notes), 0L)
  notes[[length(notes)]]
}
