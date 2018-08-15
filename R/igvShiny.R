library(jsonlite)
library(shiny)
#----------------------------------------------------------------------------------------------------
igvShiny <- function(options, width = NULL, height = NULL, elementId = NULL)
{
  supportedOptions <- c("genomeName", "initialLocus")
  stopifnot(all(supportedOptions %in% names(options)))
  supportedGenomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
  stopifnot(options$genomeName %in% supportedGenomes)

  printf("--- ~/github/igvShiny/R/igvShiny ctor");
  #x <- list(
  #  message = message
  #  )

  # create widget
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
removeTracksByName <- function(trackNames)
{
   message <- list(trackNames=trackNames)
   session <- shiny::getDefaultReactiveDomain()
   session$sendCustomMessage("removeTracksByName", message)

} # loadBedGraphTrack
#------------------------------------------------------------------------------------------------------------------------
loadBedTrack <- function(trackName, tbl, deleteTracksOfSameName=TRUE)
{
   message <- list(tbl=jsonlite::toJSON(tbl))
   session <- shiny::getDefaultReactiveDomain()
   session$sendCustomMessage("loadBedTrack", message)

} # loadBedTrack
#------------------------------------------------------------------------------------------------------------------------
loadBedTrackFromFile <- function(trackName, tbl, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(trackName);
      }

   tbl <- data.frame(chrom=c("1", "1", "1"),
                     start=c(7432951, 7437000, 7438000),
                     end=  c(7436000, 7437500, 7437600),
                     stringsAsFactors=FALSE)
   temp.filename <- "~/github/igvShiny/inst/unitTests/tracks/test.bed"
   write.table(tbl, row.names=FALSE, col.names=FALSE, quote=FALSE, sep="\t", file=temp.filename)

   message <- list(trackName, filename="test.bed")
   session <- shiny::getDefaultReactiveDomain()
   session$sendCustomMessage("loadBedTrackFromFile", message)

} # loadBedTrack
#------------------------------------------------------------------------------------------------------------------------
loadBedGraphTrack <- function(trackName, tbl, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(trackName);
      }

   message <- list(trackName=trackName, tbl=jsonlite::toJSON(tbl))
   session <- shiny::getDefaultReactiveDomain()
   session$sendCustomMessage("loadBedGraphTrack", message)

} # loadBedGraphTrack
#------------------------------------------------------------------------------------------------------------------------
loadSegTrack <- function(trackName, tbl, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(trackName);
      }

   message <- list(trackName=trackName, tbl=jsonlite::toJSON(tbl))
   session <- shiny::getDefaultReactiveDomain()
   session$sendCustomMessage("loadSegTrack", message)

} # loadSegTrack
#------------------------------------------------------------------------------------------------------------------------

