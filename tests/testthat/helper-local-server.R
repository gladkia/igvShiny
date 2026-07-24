# A static HTTP server over inst/extdata, for the code paths that take a URL.
#
# These paths used to be tested against https://gladki.pl, which made the test
# suite depend on a third-party host: CI went red whenever that host was slow or
# throttled the runner IPs, with no change in the package. Serving the same
# fixture files from 127.0.0.1 keeps the real http:// code path (httr::HEAD,
# httr::http_error) under test while making it offline-safe.
#
# httpuv comes in with shiny, so this adds no dependency.

local_server_start <- function() {
  dir <- system.file(package = "igvShiny", "extdata")
  port <- httpuv::randomPort()
  server <- httpuv::startServer(
    "127.0.0.1", port,
    list(staticPaths = list("/" = dir))
  )
  list(server = server, port = port)
}

# Serves for the lifetime of the calling test (or test file, when called from
# a helper), then shuts down - `withr::defer` is what testthat uses internally
# for this kind of scoped cleanup.
local_server <- function(env = parent.frame()) {
  srv <- local_server_start()
  withr::defer(srv$server$stop(), envir = env)
  srv$port
}

local_url <- function(port, filename) {
  sprintf("http://127.0.0.1:%d/%s", port, filename)
}
