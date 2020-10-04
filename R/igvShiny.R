library(jsonlite)
library(shiny)
library(VariantAnnotation)
library(randomcoloR)
randomColors <- distinctColorPalette(24)
#----------------------------------------------------------------------------------------------------
printf <- function(...) print(noquote(sprintf(...)))
state <- new.env(parent=emptyenv())
state[["userAddedTracks"]] <- list()
#----------------------------------------------------------------------------------------------------
igvShiny <- function(options, width = NULL, height = NULL, elementId = NULL, displayMode="squished")
{
  supportedOptions <- c("genomeName", "initialLocus")
  stopifnot(all(supportedOptions %in% names(options)))
  supportedGenomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
  stopifnot(options$genomeName %in% supportedGenomes)
  state[["requestedHeight"]] <- height

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
    if("requestedHeight" %in% ls(state)){
      printf("setting height from state")
      height <- state[["requestedHeight"]]
      }

  htmlwidgets::shinyWidgetOutput(outputId, 'igvShiny', width, height, package = 'igvShiny')
}
#----------------------------------------------------------------------------------------------------
renderIgvShiny <- function(expr, env=parent.frame(), quoted = FALSE)
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
showGenomicRegion <- function(session, id, region)
{
   message <- list(region=region, elementID=id)
   session$sendCustomMessage("showGenomicRegion", message)

} # showGenomicRegion
#------------------------------------------------------------------------------------------------------------------------
getGenomicRegion <- function(session, id)
{
   message <- list(elementID=id)
   session$sendCustomMessage("getGenomicRegion", message)

} # gertGenomicRegion
#------------------------------------------------------------------------------------------------------------------------
removeTracksByName <- function(session, id, trackNames)
{
   message <- list(trackNames=trackNames, elementID=id)
   session$sendCustomMessage("removeTracksByName", message)

} # removeTracksByName
#------------------------------------------------------------------------------------------------------------------------
removeUserAddedTracks <- function(session, id)
{
   removeTracksByName(session, id, state[["userAddedTracks"]])
   state[["userAddedTracks"]] <- list()

} # removeUserAddedTracks
#------------------------------------------------------------------------------------------------------------------------
loadBedTrack <- function(session, id, trackName, tbl, color="gray", trackHeight=50,
                         deleteTracksOfSameName=TRUE, quiet=TRUE)
{
   if(color == "random")
      color <- randomColors[sample(seq_len(length(randomColors)), 1)]

   if(!quiet){
      printf("--- igvShiny::loadBedTrack");
      print(dim(tbl))
      print(head(tbl))
      print(unlist(lapply(tbl, class)))
      }

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
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

   msg.to.igv <- list(elementID=id, trackName=trackName,
                      tbl=jsonlite::toJSON(tbl), color=color, trackHeight=trackHeight)
   session$sendCustomMessage("loadBedTrack", msg.to.igv)

} # loadBedTrack
#------------------------------------------------------------------------------------------------------------------------
loadBedGraphTrack <- function(session, id, trackName, tbl, color="gray", trackHeight=30,
                              autoscale, min=NA_real_, max=NA_real_,
                              deleteTracksOfSameName=TRUE, quiet=TRUE)
{
   stopifnot(ncol(tbl) >= 4)

   if(color == "random")
      color <- randomColors[sample(seq_len(length(randomColors)), 1)]

   if(!quiet){
      printf("--- igvShiny::loadBedGraphTrack");
      printf("    %d rows, %d columns", nrow(tbl), ncol(tbl))
      printf("    colnames: %s", paste(colnames(tbl), collapse=", "))
      printf("    col classes: %s", paste(unlist(lapply(tbl, class)), collapse=", "))
      print(fivenum(tbl[, 4]))
      }

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
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

   msg.to.igv <- list(elementID=id, trackName=trackName, tbl=jsonlite::toJSON(tbl),
                      color=color, trackHeight=trackHeight,
                      autoscale=autoscale, min=min, max=max)

   session$sendCustomMessage("loadBedGraphTrack", msg.to.igv)

} # loadBedGraphTrack
#------------------------------------------------------------------------------------------------------------------------
loadSegTrack <- function(session, id, trackName, tbl, deleteTracksOfSameName=TRUE)
{
   printf("--- entering loadSegTrack %s with %d rows", trackName, nrow(tbl))

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(elementID=id, trackName=trackName, tbl=jsonlite::toJSON(tbl))
   printf("about to send loadSegTrack message")
   session$sendCustomMessage("loadSegTrack", message)

} # loadSegTrack
#------------------------------------------------------------------------------------------------------------------------
loadVcfTrack <- function(session, id, trackName, vcfData, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))
   path <- file.path("tracks", "tmp.vcf")
   writeVcf(vcfData, path)

   message <- list(elementID=id, trackName=trackName, vcfDataFilepath=path)
   session$sendCustomMessage("loadVcfTrack", message)

} # loadVcfTrack
#------------------------------------------------------------------------------------------------------------------------
loadGwasTrack <- function(session, id, trackName, tbl.gwas, deleteTracksOfSameName=TRUE)
{
   printf("======== entering igvShiny::loadGwasTrack")

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   temp.file <- tempfile(tmpdir="tracks", fileext=".gwas")
   write.table(tbl.gwas, sep="\t", row.names=FALSE, quote=FALSE, file=temp.file)
   printf("--- igvShiny.R, loadGwasTrack wrote %d,%d to %s", nrow(tbl.gwas), ncol(tbl.gwas),
          temp.file)
   printf("exists? %s", file.exists(temp.file))
   message <- list(elementID=id, trackName=trackName, gwasDataFilepath=temp.file,
                   color="red", trackHeight=200, autoscale=FALSE,
                   min=0, max=35)
   session$sendCustomMessage("loadGwasTrack", message)

} # loadGwasTrack
#------------------------------------------------------------------------------------------------------------------------

