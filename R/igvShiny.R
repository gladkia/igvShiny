library(jsonlite)
library(shiny)
#----------------------------------------------------------------------------------------------------
state <- new.env(parent=emptyenv())
state[["userAddedTracks"]] <- list()
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
loadBedTrack <- function(session, trackName, tbl, color="gray", trackHeight=50, deleteTracksOfSameName=TRUE)
{
   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   stopifnot(colnames(tbl)[1:3] == c("chr", "start", "end"))
   stopifnot(is(tbl$chr, "character"))
   stopifnot(is(tbl$start, "numeric"))
   stopifnot(is(tbl$end, "numeric"))

   message <- list(trackName=trackName, tbl=jsonlite::toJSON(tbl), color=color, trackHeight=trackHeight)
   session$sendCustomMessage("loadBedTrack", message)

} # loadBedTrack
#------------------------------------------------------------------------------------------------------------------------
loadBedTrackFromFile <- function(session, trackName, tbl, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, trackName);
      }

   tbl <- data.frame(chrom=c("1", "1", "1"),
                     start=c(7432951, 7437000, 7438000),
                     end=  c(7436000, 7437500, 7437600),
                     stringsAsFactors=FALSE)
   temp.filename <- "~/github/igvShiny/inst/unitTests/tracks/test.bed"
   write.table(tbl, row.names=FALSE, col.names=FALSE, quote=FALSE, sep="\t", file=temp.filename)

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(trackName, filename="test.bed")
   session$sendCustomMessage("loadBedTrackFromFile", message)

} # loadBedTrack
#------------------------------------------------------------------------------------------------------------------------
loadBedGraphTrack <- function(session, trackName, tbl, color="gray", trackHeight=50, deleteTracksOfSameName=TRUE, quiet=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   stopifnot(colnames(tbl) == c("chr", "start", "end", "value"))
   stopifnot(is(tbl$chr, "character"))
   stopifnot(is(tbl$start, "numeric"))
   stopifnot(is(tbl$end, "numeric"))
   stopifnot(is(tbl$value, "numeric"))

   if(!quiet){
      printf("--- igvShiny::loadBedGraphTrack");
      printf("    %d rows, %d columns", nrow(tbl), ncol(tbl))
      printf("    colnames: %s", paste(colnames(tbl), collapse=", "))
      printf("    col classes: %s", paste(unlist(lapply(tbl, class)), collapse=", "))
      print(fivenum(tbl[, 4]))
      }
   message <- list(trackName=trackName, tbl=jsonlite::toJSON(tbl), color=color, trackHeight=trackHeight)
   session$sendCustomMessage("loadBedGraphTrack", message)

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

