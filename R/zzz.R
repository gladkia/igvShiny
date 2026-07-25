.onLoad <- function(libname, pkgname) {
  # assure proper value for "tracks" resource path; .tracksDir() re-points it
  # whenever the tracks directory moves, so every write site goes through it too
  .tracksDir()
}
