library(jsonlite)
library(shiny)
library(VariantAnnotation)
#----------------------------------------------------------------------------------------------------
state <- new.env(parent=emptyenv())
state[["userAddedTracks"]] <- list()
#----------------------------------------------------------------------------------------------------
igvShiny <- function(options, width = NULL, height = NULL, elementId = NULL, displayMode="squished")
{
  supportedOptions <- c("genomeName", "initialLocus")
  stopifnot(all(supportedOptions %in% names(options)))
  supportedGenomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
  stopifnot(options$genomeName %in% supportedGenomes)

  printf("--- ~/github/igvShiny/R/igvShiny ctor");

  htmlwidgets::createWidget(
    name = 'igvShiny',
    options,
    width = width,
    height = height,
    package = 'igvShiny',
    elementId = elementId
    )

} # igvShiny constructor
#----------------------------------------------------------------------------------------------------
igvShinyOutput <- function(outputId, width = '100%', height = '400px')
{
  htmlwidgets::shinyWidgetOutput(outputId, 'igvShiny', width, height, package = 'igvShiny')
}
#----------------------------------------------------------------------------------------------------
renderIgvShiny <- function(expr, env = parent.frame(), quoted = FALSE)
{
   if (!quoted){
      expr <- substitute(expr)
      } # force quoted

  htmlwidgets::shinyRenderWidget(expr, igvShinyOutput, env, quoted = TRUE)

}
#----------------------------------------------------------------------------------------------------
redrawIgvWidget <- function(session)
{
   session$sendCustomMessage("redrawIgvWidget", message=list())

} # redrawIgvWidget
#----------------------------------------------------------------------------------------------------
showGenomicRegion <- function(session, region)
{
   message <- list(region=region)
   session$sendCustomMessage("showGenomicRegion", message)

} # showGenomicRegion
#------------------------------------------------------------------------------------------------------------------------
getGenomicRegion <- function(session, region)
{
   session$sendCustomMessage("getGenomicRegion", message)

} # gertGenomicRegion
#------------------------------------------------------------------------------------------------------------------------
removeTracksByName <- function(session, trackNames)
{
   message <- list(trackNames=trackNames)
   session$sendCustomMessage("removeTracksByName", message)

} # removeTracksByName
#------------------------------------------------------------------------------------------------------------------------
removeUserAddedTracks <- function(session)
{
   removeTracksByName(session, state[["userAddedTracks"]])
   state[["userAddedTracks"]] <- list()

} # removeUserAddedTracks
#------------------------------------------------------------------------------------------------------------------------
loadBedTrack <- function(session, trackName, tbl, color="gray", trackHeight=50, deleteTracksOfSameName=TRUE, quiet=TRUE)
{
   if(!quiet){
      printf("--- igvShiny::loadBedTrack");
      print(dim(tbl))
      print(head(tbl))
      print(unlist(lapply(tbl, class)))
      }

   if(deleteTracksOfSameName){
      removeTracksByName(session, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   if(colnames(tbl)[1] == "chrom")
      colnames(tbl)[1] <- "chr"

   if(all(colnames(tbl)[1:3] != c("chr", "start", "end"))){
      printf("found these colnames: %s", paste(colnames(tbl), collapse=", "))
      printf("            required: %s", paste(c("chr", "start", "end"), collapse=", "))
      stop("improper columns in bed track data.frame")
      }

   stopifnot(is(tbl$chr, "character"))
   stopifnot(is(tbl$start, "numeric"))
   stopifnot(is(tbl$end, "numeric"))
   new.order <- order(tbl$start, decreasing=FALSE)
   tbl <- tbl[new.order,]

   msg.to.igv <- list(trackName=trackName, tbl=jsonlite::toJSON(tbl), color=color, trackHeight=trackHeight)
   session$sendCustomMessage("loadBedTrack", msg.to.igv)

} # loadBedTrack
#------------------------------------------------------------------------------------------------------------------------
loadBedGraphTrack <- function(session, trackName, tbl, color="gray", trackHeight=30,
                              autoscale, min=NA_real_, max=NA_real_,
                              deleteTracksOfSameName=TRUE, quiet=TRUE)
{

   stopifnot(ncol(tbl) >= 4)

   if(!quiet){
      printf("--- igvShiny::loadBedGraphTrack");
      printf("    %d rows, %d columns", nrow(tbl), ncol(tbl))
      printf("    colnames: %s", paste(colnames(tbl), collapse=", "))
      printf("    col classes: %s", paste(unlist(lapply(tbl, class)), collapse=", "))
      print(fivenum(tbl[, 4]))
      }

   if(deleteTracksOfSameName){
      removeTracksByName(session, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   if(colnames(tbl)[1] == "chrom")
      colnames(tbl)[1] <- "chr"

   colnames(tbl)[4] <- "value"

   if(all(colnames(tbl)[1:3] != c("chr", "start", "end"))){
      printf("found these colnames: %s", paste(colnames(tbl)[1:3], collapse=", "))
      printf("            required: %s", paste(c("chr", "start", "end"), collapse=", "))
      stop("improper columns in bed track data.frame")
      }

   stopifnot(is(tbl$chr, "character"))
   stopifnot(is(tbl$start, "numeric"))
   stopifnot(is(tbl$end, "numeric"))
   stopifnot(is(tbl$value, "numeric"))

   new.order <- order(tbl$start, decreasing=FALSE)
   tbl <- tbl[new.order,]

   msg.to.igv <- list(trackName=trackName, tbl=jsonlite::toJSON(tbl), color=color, trackHeight=trackHeight,
                      autoscale=autoscale, min=min, max=max)

   session$sendCustomMessage("loadBedGraphTrack", msg.to.igv)

} # loadBedGraphTrack
#------------------------------------------------------------------------------------------------------------------------
loadSegTrack <- function(session, trackName, tbl, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(trackName=trackName, tbl=jsonlite::toJSON(tbl))
   session$sendCustomMessage("loadSegTrack", message)

} # loadSegTrack
#------------------------------------------------------------------------------------------------------------------------
loadVcfTrack <- function(session, trackName, vcfData, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))
   path <- file.path("tracks", "tmp.vcf")
   writeVcf(vcfData, path)

   message <- list(trackName=trackName, vcfDataFilepath=path)
   session$sendCustomMessage("loadVcfTrack", message)

} # loadVcfTrack
#------------------------------------------------------------------------------------------------------------------------

