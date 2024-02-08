#' @name GWASTrack-class
#' @rdname GWASTrack-class
#' @importFrom methods is new
#' @importFrom utils write.table

#' @exportClass GWASTrack

.GWASTrack <-
  setClass(
    "GWASTrack",
    slots = representation(
      trackName = "character",
      data.mode = "character",
      url = "character",
      chrom.col = "numeric",
      pos.col = "numeric",
      pval.col = "numeric",
      trackHeight = "numeric",
      autoscale = "logical",
      minY = "numeric",
      maxY = "numeric"
    )
  )

setGeneric("display",
           signature = "obj",
           function(obj,
                    session,
                    id,
                    deleteTracksOfSameName = TRUE) {
             standardGeneric("display")
           })

setGeneric("getUrl",
           signature = "obj",
           function(obj) {
             standardGeneric("getUrl")
           })

#-------------------------------------------------------------------------------
#' Constructor for GWASTrack
#'
#' \code{GWASTrack} creates an \code{IGV} manhattan track from GWAS data
#'
#' @name GWASTrack
#' @rdname GWASTrack-class
#'
#' @param trackName A character string, used as track label by igv, 
#' we recommend unique names per track.
#' @param data a data.frame or a url pointing to one, 
#' whose structure is described by chrom.col, pos.col, pval.col
#' @param chrom.col numeric, the column number of the chromosome column
#' @param pos.col numeric, the column number of the position column
#' @param pval.col numeric, the column number of the GWAS pvalue column
#' @param trackHeight numeric in pixels
#' @param autoscale logical
#' @param minY numeric for explicit (non-auto) scaling
#' @param maxY numeric for explicit (non-auto) scaling
#'
#' @return A GWASTrack object
#'
#' @examples
#' 
#' file <-
#'   # a local gwas file
#'   system.file(package = "igvShiny", "extdata", "gwas-5k.tsv.gz")
#' tbl.gwas <- read.table(file,
#'                        sep = "\t",
#'                        header = TRUE,
#'                        quote = "")
#' dim(tbl.gwas)
#' track <-
#'   GWASTrack(
#'     "gwas 5k",
#'     tbl.gwas,
#'     chrom.col = 12,
#'     pos.col = 13,
#'     pval.col = 28
#'   )
#' getUrl(track)
#' 
#' url <- "https://s3.amazonaws.com/igv.org.demo/gwas_sample.tsv.gz"
#' track <- GWASTrack(
#'   "remote url gwas",
#'   url,
#'   chrom.col = 3,
#'   pos.col = 4,
#'   pval.col = 10,
#'   autoscale = FALSE,
#'   minY = 0,
#'   maxY = 300,
#'   trackHeight = 100
#' )
#' getUrl(track)
#'
#'
#' @export
#'


GWASTrack <- function(trackName,
                      data,
                      chrom.col,
                      pos.col,
                      pval.col,
                      trackHeight = 50,
                      autoscale = TRUE,
                      minY = 0,
                      maxY = 30) {
  data.class <- class(data)
  stopifnot(data.class %in% c("data.frame", "character"))
  
  if (data.class == "data.frame") {
    mode <- "local.url"
    tdir <- get_tracks_dir()
    x <- NULL
    url <-
      tempfile(tmpdir = tdir, fileext = ".gwas") # expanded in javascript
    write.table(
      data,
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      file = url
    )
  }
  
  if (data.class == "character") {
    if (!RCurl::url.exists(data)) {
      # was a legitimate url provided?
      error.message <-
        sprintf("error: putative gwas file url unreachable: '%s'",
                data)
      stop(error.message)
    }
    mode <- "remote.url"
    url <- data
  }
  
  obj <- .GWASTrack(
    trackName = trackName,
    data.mode = mode,
    url = url,
    chrom.col = chrom.col,
    pos.col = pos.col,
    pval.col = pval.col,
    trackHeight = trackHeight,
    autoscale = autoscale,
    minY = minY,
    maxY = maxY
  )
  obj
  
} # GWASTrack
#-------------------------------------------------------------------------------
#' display the already constructed and configured track
#'
#' @rdname display
#' @aliases display
#'
#' @param obj An object of class GWASTrack
#' @param session a Shiny session object
#' @param id character the identifier of the target igv object in the browser
#' @param deleteTracksOfSameName logical to avoid duplications in track names
#'
#' @return nothing
#'
#' @export
#'
setMethod("display",
          "GWASTrack",
          
          function(obj,
                   session,
                   id,
                   deleteTracksOfSameName = TRUE) {
            if (deleteTracksOfSameName) {
              removeTracksByName(session, id, obj@trackName)
            }
            
            state[["userAddedTracks"]] <-
              unique(c(state[["userAddedTracks"]], obj@trackName))
            
            # javascript function consults dataMode,
            # modifies dataUrl if local.url,
            # prepending the http host of the modest RStudio/Shiny webserver
            # make sure the embedded shiny webserver can find it by:
            #   - adding a resource path with a convenient shorthand name,
            #   pointing to the typically long and cryptic actual local host
            #   temporary directory
            #   - adjusting message$dataUrl to use that shorthand directory name
            
            message <- list(
              elementID = id,
              trackName = obj@trackName,
              dataMode = obj@data.mode,
              dataUrl = obj@url,
              trackHeight = obj@trackHeight,
              autoscale = obj@autoscale,
              min = obj@minY,
              max = obj@maxY
            )
            
            if (obj@data.mode == "local.url") {
              directory.name <- dirname(obj@url)
              file.name      <-  basename(obj@url)
              message$dataUrl <- file.path("tracks", file.name)
            }
            
            session$sendCustomMessage("loadGwasTrackFlexibleSource", message)
            
          }) # display
#-------------------------------------------------------------------------------
#' the url of the gwas table
#'
#' @rdname getUrl
#' @aliases getUrl
#'
#' @param obj An object of class GWASTrack
#'
#' @return character
#'
#' @export
#'
setMethod("getUrl",
          "GWASTrack",
          function(obj) {
            obj@url
          })
