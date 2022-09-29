#' @name GWASTrack-class
#' @rdname GWASTrack-class
#' @exportClass GWASTrack

.GWASTrack <- setClass("GWASTrack",
                        slots=representation(
                            trackName="character",
                            data.mode="character",
                            url="character",
                            chrom.col="numeric",
                            pos.col="numeric",
                            pval.col="numeric",
                            color="character",
                            trackHeight="numeric",
                            autoscale="logical",
                            minY="numeric",
                            maxY="numeric")
                       )

setGeneric('display',  signature='obj', function(obj, session, id, deleteTracksOfSameName=TRUE)
    standardGeneric ('display'))
setGeneric('getUrl',  signature='obj', function(obj) standardGeneric ('getUrl'))
#----------------------------------------------------------------------------------------------------
#' Constructor for GWASTrack
#'
#' \code{GWASTrack} creates an \code{IGV} manhattan track GWAS data
#'
#' @name GWASTrack
#' @rdname GWASTrack-class
#'
#' @param trackName  A character string, used as track label by igv, we recommend unique names per track.
#' @param data a data.frame or a url pointing to one, whose essential structure is described by chrom.col, pos.col, pval.col
#' @param chrom.col numeric, the column number of the chromosome column
#' @param pos.col numeric, the column number of the position column
#' @param pval.col numeric, the column number of the GWAS pvalue colum
#' @param trackHeight numeric typically in range 20 (for annotations) and up to 1000 (for large sample vcf files)
#' @param autoscale  logical
#' @param minY  numeric for explicit (non-auto) scaling
#' @param maxY  numeric for explicit (non-auto) scaling
#' @param color A css color name (e.g., "red" or "#FF0000"
#'
#' @return A GWASTrack object
#'
#' @examples
#'
#'   file <- system.file(package="igvR", "extdata", "gwas-5k.tsv")
#'   tbl.gwas <- read.table(file, sep="\t", header=TRUE, quote="")
#'   dim(tbl.gwas)
#'   track <- GWASTrack("gwas 5k", tbl.gwas, chrom.col=12, pos.col=13, pval.col=28)
#' @export
#'

GWASTrack <- function(trackName,
                      data,
                      chrom.col,
                      pos.col,
                      pval.col,
                      color="darkBlue",
                      trackHeight=50,
                      autoscale=TRUE,
                      minY=0,
                      maxY=30
                      )
{
    data.class <- class(data)
    stopifnot(data.class %in% c("data.frame", "character"))

    if(data.class == "data.frame"){
        mode <- "local.url"
        url <- tempfile(tmpdir="tracks", fileext=".gwas") # expanded in javascript
        write.table(data, sep="\t", row.names=FALSE, quote=FALSE, file=url)
        }

    if(data.class == "character"){
       if(!url.exists(data)){  # was a legitimate url provided?
           error.message <- sprintf("error: putative gwas file url unreachable: '%s'", data)
           stop(error.message)
           }
       mode <- "remote.url"
       url <- data
       }

    obj <- .GWASTrack(trackName=trackName,
                      data.mode=mode,
                      url=url,
                      chrom.col=chrom.col,
                      pos.col=pos.col,
                      pval.col=pval.col,
                      color=color,
                      trackHeight=trackHeight,
                      autoscale=autoscale,
                      minY=minY,
                      maxY=maxY)
    obj

} # GWASTrack
#----------------------------------------------------------------------------------------------------
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
setMethod('display', 'GWASTrack',

  function (obj, session, id, deleteTracksOfSameName=TRUE) {

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

     # javascript function consults dataMode, modifies dataUrl if local.url,
     # prepending the http host of the modest RStudio/Shiny webserver

   message <- list(elementID=id,
                   trackName=obj@trackName,
                   dataMode=obj@data.mode,
                   dataUrl=obj@url,
                   color=obj@color,
                   trackHeight=obj@trackHeight,
                   autoscale=obj@autoscale,
                   min=obj@minY,
                   max=obj@maxY)

   session$sendCustomMessage("loadGwasTrackFlexibleSource", message)

}) # display
#----------------------------------------------------------------------------------------------------
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
setMethod('getUrl', 'GWASTrack',

    function (obj) {
        obj@url
        })

