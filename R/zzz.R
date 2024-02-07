.onLoad <- function(libname, pkgname) {
    # assure proper value for "tracks" resource path
    rp <- resourcePaths()
    if ("tracks" %in% names(rp)) {
        shiny::removeResourcePath("tracks")
    }
    shiny::addResourcePath("tracks", get_tracks_dir())
}
