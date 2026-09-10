# Range request server support for igvShiny
# Enables HTTP 206 Partial Content streaming of local files directly from disk
# via ShinySession$registerDataObj(), with zero in-memory overhead.

#' Internal HTTP Range request handler for local files
#'
#' @param filePath character, normalized path to existing local file
#' @param req environment, Rook request environment supplied by Shiny
#'
#' @return An \code{httpResponse} object (status 206 for Range requests, 200 otherwise)
#'
#' @keywords internal
.serveFileWithHttpRange <- function(filePath, req) {
  if (!file.exists(filePath)) {
    return(shiny::httpResponse(
      status = 404L,
      content_type = "text/plain",
      content = "File not found"
    ))
  }

  fileSize <- as.numeric(file.info(filePath)$size)
  rangeHeader <- req$HTTP_RANGE

  defaultHeaders <- list(
    "Accept-Ranges" = "bytes",
    "Access-Control-Allow-Origin" = "*"
  )

  # Full-file GET helper: returns 200 OK with the entire file
  serveFullFile <- function() {
    con <- file(filePath, "rb")
    on.exit(close(con), add = TRUE)
    bytes <- readBin(con, "raw", n = fileSize)
    headers <- defaultHeaders
    headers[["Content-Length"]] <- as.character(fileSize)
    shiny::httpResponse(
      status = 200L,
      content_type = "application/octet-stream",
      content = bytes,
      headers = headers
    )
  }

  # 416 Range Not Satisfiable helper
  rangeNotSatisfiable <- function() {
    shiny::httpResponse(
      status = 416L,
      content_type = "text/plain",
      content = "Requested Range Not Satisfiable",
      headers = list(
        "Content-Range" = sprintf("bytes */%s", format(fileSize, scientific = FALSE)),
        "Access-Control-Allow-Origin" = "*"
      )
    )
  }

  # Full-file GET (no Range header)
  if (is.null(rangeHeader) || !nzchar(rangeHeader)) {
    return(serveFullFile())
  }

  # RFC 7233 Section 4.3: If Range header contains multiple ranges (e.g. "bytes=0-1,3-4")
  # or does not start with "bytes=", ignore the Range header and return 200 OK.
  if (!grepl("^bytes=", rangeHeader) || grepl(",", rangeHeader)) {
    return(serveFullFile())
  }

  rangeVal <- sub("^bytes=", "", rangeHeader)

  # Check for suffix range: "bytes=-500" (last 500 bytes)
  if (grepl("^-([0-9]+)$", rangeVal)) {
    suffixLen <- suppressWarnings(as.numeric(sub("^-", "", rangeVal)))
    if (is.na(suffixLen) || suffixLen <= 0) {
      return(rangeNotSatisfiable())
    }
    start <- max(0, fileSize - suffixLen)
    end <- fileSize - 1
  } else if (grepl("^([0-9]+)-([0-9]*)$", rangeVal)) {
    # Standard range: "bytes=start-end" or "bytes=start-"
    parts <- regmatches(rangeVal, regexec("^([0-9]+)-([0-9]*)$", rangeVal))[[1]]
    start <- suppressWarnings(as.numeric(parts[2]))
    if (is.na(start) || start < 0 || start >= fileSize) {
      return(rangeNotSatisfiable())
    }
    if (nzchar(parts[3])) {
      end <- suppressWarnings(as.numeric(parts[3]))
      if (is.na(end)) end <- fileSize - 1
    } else {
      end <- fileSize - 1
    }
    end <- min(end, fileSize - 1)
    if (end < start) {
      return(rangeNotSatisfiable())
    }
  } else {
    # Malformed range header: per RFC 7233, ignore and serve 200 OK
    return(serveFullFile())
  }

  lengthToRead <- as.integer(end - start + 1)

  con <- file(filePath, "rb")
  on.exit(close(con), add = TRUE)
  seek(con, where = start, origin = "start")
  bytes <- readBin(con, "raw", n = lengthToRead)

  headers <- defaultHeaders
  headers[["Content-Range"]] <- sprintf(
    "bytes %s-%s/%s",
    format(start, scientific = FALSE),
    format(end, scientific = FALSE),
    format(fileSize, scientific = FALSE)
  )
  headers[["Content-Length"]] <- as.character(lengthToRead)

  shiny::httpResponse(
    status = 206L,
    content_type = "application/octet-stream",
    content = bytes,
    headers = headers
  )
} # .serveFileWithHttpRange


#' Serve a local file via HTTP Range Requests from the Shiny session
#'
#' Registers a local file with the active Shiny session so that \code{igv.js}
#' can stream chunks of the file using HTTP 206 Partial Content requests.
#' This allows random-access binary formats (such as BAM, BAI, CRAM, CRAI,
#' BigWig, and Tabix-indexed files) of arbitrary size to be viewed in \code{igvShiny}
#' without loading them into R memory or copying them to temporary directories.
#'
#' The returned URL is relative to the Shiny application root and is routed
#' through the same HTTP port as the Shiny session, ensuring compatibility
#' with Posit Connect, shinyapps.io, reverse proxies, and local development.
#'
#' @param session Shiny session object (must be an active Shiny session)
#' @param filePath character string, path to an existing, readable local file
#'
#' @return A character string containing the relative URL to access the file
#'   from the browser (e.g. \code{"session/<token>/dataobj/<filename>?..."})
#'
#' @examples
#' \dontrun{
#' # Inside a Shiny server function:
#' server <- function(input, output, session) {
#'   bam_url <- serveLocalFile(session, "data/sample.bam")
#'   bai_url <- serveLocalFile(session, "data/sample.bam.bai")
#'
#'   tracks <- list(
#'     list(
#'       name = "Sample BAM",
#'       type = "alignment",
#'       format = "bam",
#'       url = bam_url,
#'       indexURL = bai_url
#'     )
#'   )
#'   output$igv <- renderIgvShiny({
#'     igvShiny(genomeOptions, tracks = tracks)
#'   })
#' }
#' }
#'
#' @export
#' @keywords utils
serveLocalFile <- function(session, filePath) {
  checkmate::assert_multi_class(session, c("ShinySession", "environment"))
  checkmate::assert_file_exists(filePath, access = "r")

  normPath <- normalizePath(filePath, winslash = "/", mustWork = TRUE)
  filename <- basename(normPath)

  # Create a stable identifier preserving the filename and extension
  dataObjName <- paste0(
    substr(utils::packageVersion("igvShiny"), 1, 4),
    "_",
    sprintf("%08x", as.integer(stats::runif(1, 1, .Machine$integer.max))),
    "_",
    filename
  )

  url <- session$registerDataObj(
    name = dataObjName,
    data = normPath,
    filterFunc = .serveFileWithHttpRange
  )

  url
} # serveLocalFile
