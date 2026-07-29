#' get_tracks_dir
#
#' Get the directory where tracks are stored. The directory can be defined
#' with environmental variable.
#' If not defined the default is a directory called "tracks" in the temp
#' directory.
#
#' We need a local directory to write files - for instance,
#' a vcf file representing a genomic region of interest.
#' We then tell shiny about that directory, so that shiny's built-in http server
#' can serve up files we write there, ultimately consumed by igv.js
#'
#' @param env_var The name of the environmental variable to use.
#'
#' @return string with the path to the tracks directory.
#'
#' @examples
#' gtd <- get_tracks_dir(env_var = "TRACKS_DIR")
#'
#' @keywords utils
#' @export
get_tracks_dir <- function(env_var = "TRACKS_DIR") {
  checkmate::assert_string(env_var)
  default_dir <- file.path(tempdir(), "tracks")
  tracks_dir <- Sys.getenv(env_var, default_dir)

  checkmate::assert_access(dirname(tracks_dir), "rw")

  if (!dir.exists(tracks_dir)) {
    dir.create(tracks_dir, recursive = TRUE)
  }
  tracks_dir
} # get_tracks_dir
#-------------------------------------------------------------------------------
#' Get the tracks directory and make sure shiny serves that very directory
#'
#' @description The "tracks" resource path is registered once, when the package
#' is loaded. The default directory lives under \code{tempdir()}, which is not
#' guaranteed to stay put for the life of the process: when it moves, files are
#' written to the new directory while shiny still serves the old one, and igv.js
#' gets a 404 for a file that exists on disk. Re-registering the path before
#' each write keeps the served directory and the written directory the same.
#'
#' @return string with the path to the tracks directory.
#'
#' @keywords internal
.tracksDir <- function() {
  tracks_dir <- get_tracks_dir()
  # resourcePaths() is an atomic vector, so [["tracks"]] errors when the path is
  # not registered yet - which is the case the first time this runs (.onLoad)
  registered <- shiny::resourcePaths()
  served <- if ("tracks" %in% names(registered)) {
    registered[["tracks"]]
  } else {
    NULL
  }

  # normalizePath so that /var/... and its /private/var/... realpath (macOS)
  # do not look like two different directories
  canonical <- function(path) {
    normalizePath(path, winslash = "/", mustWork = FALSE)
  }

  if (is.null(served) || !identical(canonical(served), canonical(tracks_dir))) {
    if (!is.null(served)) {
      shiny::removeResourcePath("tracks")
    }
    shiny::addResourcePath("tracks", tracks_dir)
  }

  tracks_dir
} # .tracksDir
#-------------------------------------------------------------------------------
#' Make a file on disk reachable by igv.js
#'
#' @description Files igv.js reads by url have to sit in the directory shiny
#' serves as "tracks". Alignment files run to gigabytes, so the file is linked
#' rather than copied where the filesystem allows it (windows, and any mount
#' refusing links, falls back to a copy). The name is randomized: two loaders
#' may be handed same-named files from different directories.
#'
#' @param path character string, an existing file
#' @param ext character string, the extension of the served file
#'
#' @return string with the path to the file, relative to the shiny app
#'
#' @keywords internal
.stageTrackFile <- function(path, ext) {
  dest <- tempfile(tmpdir = .tracksDir(), fileext = ext)
  ok <- suppressWarnings(file.symlink(normalizePath(path), dest))
  if (!ok) {
    ok <- file.copy(path, dest)
  }
  if (!ok) {
    stop(sprintf("igvShiny: could not stage '%s' for serving", path))
  }
  file.path("tracks", basename(dest))
} # .stageTrackFile
