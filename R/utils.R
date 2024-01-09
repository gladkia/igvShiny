#' get_tracks_dir
#
#' Get the directory where tracks are stored. The directory can be defined with environmental variable.
#' If not defined the default is a directory called "tracks" in the temp directory.
#
#' We need a local directory to write files - for instance, a vcf file representing a genomic
#' region of interest. We then tell shiny about that directory, so that shiny's built-in http server
#' can serve up files we write there, ultimately consumed by igv.js
#'
#' @param env_var The name of the environmental variable to use.
#'
#' @return string with the path to the tracks directory.
#' 
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
}


