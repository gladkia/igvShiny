#' @import BiocGenerics
#' @import GenomicRanges
#' @import GenomeInfoDbData
#' @import rtracklayer
#' @import shiny
#' @import jsonlite
#' @import randomcoloR
#'
#' @name igvShiny
#' @rdname igvShiny

library(randomcoloR)
randomColors <- distinctColorPalette(24)
#----------------------------------------------------------------------------------------------------
printf <- function(...) print(noquote(sprintf(...)))
state <- new.env(parent=emptyenv())
state[["userAddedTracks"]] <- list()
#----------------------------------------------------------------------------------------------------
#' Create an igvShiny instance
#'
#' @description This function is called in the server function of your shiny app
#'
#' @rdname igvShiny
#' @aliases igvShiny
#'
#' @param options a list, with required elements 'genomeName' and 'initialLocus'.
#'   Local or remote custom genomes can be used by setting 'genomeName' to 'local' or
#'   'remote'. The necessary fasta and index files are provided via 'fasta' and 'index'
#'   arguments, either as path on disc or as URL.
#' @param width a character string, standard css notations, either e.g., "1000px" or "95\%"
#' @param height a character string, needs to be an explicit pixel measure, e.g., "800px"
#' @param elementId a character string, the html element id within which igv is created
#' @param displayMode a character string, default "SQUISHED".
#' @param tracks a list of track specifications to be created and displayed at startup
#' @return the created widget
#'
#' @export
#'
igvShiny <- function(options, width = NULL, height = NULL, elementId = NULL,
                     displayMode="squished", tracks=list())
{
  mandatoryOptions <- c("genomeName", "initialLocus")
  stopifnot(all(mandatoryOptions %in% names(options)))
  supportedGenomeNames <- c("hg38", "hg19", "mm10", "tair10", "rhos", "local", "remote")
  stopifnot(options$genomeName %in% supportedGenomeNames)
  if (options$genomeName == "remote") {
    printf("Provided remote fasta url: %s", options$fasta)
    # assert that the fasta and index are accessible
    stopifnot("fasta" %in% names(options))
    stopifnot(httr::http_status(httr::HEAD(options$fasta))$category == "Success")
    if (is.null(options$index))
      options$index <- paste(options$fasta, "fai", sep = ".")
    printf("Remote fasta index url: %s", options$index)
    stopifnot(httr::http_status(httr::HEAD(options$index))$category == "Success")
  }
  if (options$genomeName == "local") {
    # assert that the fasta and index exists
    stopifnot("fasta" %in% names(options))
    stopifnot(file.exists(options$fasta))
    printf("Provided local fasta file: %s", options$fasta)
    if (is.null(options$index))
      options$index <- paste(options$fasta, "fai", sep = ".")
    stopifnot(file.exists(options$index))
    printf("Local fasta index file: %s", options$index)

    # copy fasta file to tracks directory
    directory.name <- "tracks"   # need this as directory within the current working directory
    if (!dir.exists(directory.name)) dir.create(directory.name)
    filename <- file.path(directory.name, basename(options$fasta))
    file.copy(options$fasta, filename, overwrite = TRUE)
    options$fasta <- filename
    filename <- file.path(directory.name, basename(options$index))
    file.copy(options$index, filename, overwrite = TRUE)
    options$index <- filename
  }

  state[["requestedHeight"]] <- height

  printf("--- ~/github/igvShiny/R/igvShiny ctor");
  printf("  initial track count: %d", length(tracks))

  #send namespace info in case widget is being called from a module
  session <- shiny::getDefaultReactiveDomain()
  options$moduleNS <- session$ns("")

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
#' create the UI for the widget
#'
#' @description This function is called in the ui function of your shiny app
#'
#' @rdname igvShinyOutput
#' @aliases igvShinyOutput
#'
#' @param outputId a character string, specifies the html element id
#' @param width a character string, standard css notations, either e.g., "1000px" or "95\%", "100\%" by default
#' @param height a character string, needs to be an explicit pixel measure, e.g., "800px", "400px" by default
#'
#' @return the created widget's html
#'
#' @export
#'
igvShinyOutput <- function(outputId, width = '100%', height = NULL)
{
    if("requestedHeight" %in% ls(state)){
      printf("setting height from state")
      height <- state[["requestedHeight"]]
      }

  htmlwidgets::shinyWidgetOutput(outputId, 'igvShiny', width, height, package = 'igvShiny')
}
#----------------------------------------------------------------------------------------------------
#' draw the igv genome browser element
#'
#' @description This function is called in the server function of your shiny app
#'
#' @rdname renderIgvShiny
#' @aliases renderIgvShiny
#'
#' @param expr not sure...
#' @param env  not sure...
#' @param quoted not sure...
#'
#' @export
renderIgvShiny <- function(expr, env=parent.frame(), quoted = FALSE)
{
   if (!quoted){
      expr <- substitute(expr)
      } # force quoted

   x <- htmlwidgets::shinyRenderWidget(expr, igvShinyOutput, env, quoted = TRUE)
   printf("--- leaving igvShiny.R, renderIgvShiny")
   return(x)

}
#----------------------------------------------------------------------------------------------------
#' redraw the igv genome browser element
#'
#' @description maybe a relic, unused, originally intended to refresh?
#'
#' @rdname redrawIgvWidget
#' @aliases redrawIgvWidget
#'
#' @param session an environmet or list, provided and managed by shiny
#'
#' @export
redrawIgvWidget <- function(session)
{
   session$sendCustomMessage("redrawIgvWidget", message=list())

} # redrawIgvWidget
#----------------------------------------------------------------------------------------------------
#' focus igv on a region
#'
#' @description zoom in or out to show the nominated region, by chromosome locus or gene symbol
#'
#' @rdname showGenomicRegion
#' @aliases showGenomicRegion
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param region a character string, either e.g. "chr5:92,221,640-92,236,523" or "MEF2C"
#'
#' @export
showGenomicRegion <- function(session, id, region)
{
   message <- list(region=region, elementID=id)
   session$sendCustomMessage("showGenomicRegion", message)

} # showGenomicRegion
#------------------------------------------------------------------------------------------------------------------------
#' return the current igv region
#'
#' @description return the current region displayed by your igv instance
#'
#' @rdname showGenomicRegion
#' @aliases showGenomicRegion
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#'
#' @return
#'  a character string of format "chrom:start-end"
#'
#' @export

getGenomicRegion <- function(session, id)
{
   message <- list(elementID=id)
   session$sendCustomMessage("getGenomicRegion", message)

} # gertGenomicRegion
#------------------------------------------------------------------------------------------------------------------------
#' remove tracks from the browser
#'
#' @description delete tracks on the browser
#'
#' @rdname removeTracksByName
#' @aliases removeTracksByName
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackNames a vector of character strings
#'
#' @return
#' nothing
#'
#' @export

removeTracksByName <- function(session, id, trackNames)
{
   message <- list(trackNames=trackNames, elementID=id)
   session$sendCustomMessage("removeTracksByName", message)

} # removeTracksByName
#------------------------------------------------------------------------------------------------------------------------
#' remove only those tracks explicitly added by your app
#'
#' @description remove only those tracks explicitly added by your app.  stock tracks (i.e.,
#' Refseq Genes) remain
#'
#' @rdname removeUserAddedTracks
#' @aliases removeUserAddedTracks
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#'
#' @return
#' nothing
#'
#' @export

removeUserAddedTracks <- function(session, id)
{
   removeTracksByName(session, id, state[["userAddedTracks"]])
   state[["userAddedTracks"]] <- list()

} # removeUserAddedTracks
#------------------------------------------------------------------------------------------------------------------------
#' load a bed track provided as a data.frame
#'
#' @description load a bed track provided as a data.frame
#'
#' @rdname loadBedTrack
#' @aliases loadBedTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" "start" "end" columns
#' @param color character string, a legal CSS color, or "random", "gray" by default
#' @param trackHeight an integer, 50 (pixels) by default
#' @param deleteTracksOfSameName logical, default TRUE
#' @param quiet logical, default TRUE, controls verbosity
#'
#' @return
#' nothing
#'
#' @export

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
#' load a bedgraph track provided as a data.frame
#'
#' @description load a bedgrapn track provided as a data.frame
#'
#' @rdname loadBedGraphTrack
#' @aliases loadBedGraphTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" "start" "end" "score" columns
#' @param color character string, a legal CSS color, or "random", "gray" by default
#' @param trackHeight an integer, 30 (pixels) by default
#' @param autoscale logical
#' @param min numeric, consulted when autoscale is FALSE
#' @param max numeric, consulted when autoscale is FALSE
#' @param deleteTracksOfSameName logical, default TRUE
#' @param quiet logical, default TRUE, controls verbosity
#'
#' @return
#' nothing
#'
#' @export

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
#' load a seg track provided as a data.frame
#'
#' @description load a SEG track provided as a data.frame.  igv "displays segmented data as
#'  a blue-to-red heatmap where the data range is -1.5 to 1.5... The segmented data
#' file format is the output of the Circular Binary Segmentation algorithm (Olshen et al., 2004)".
#'
#' @rdname loadSEGTrack
#' @aliases loadSEGTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" "start" "end" "score" columns
#' @param deleteTracksOfSameName logical, default TRUE
#'
#' @return
#' nothing
#'
#' @export
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
#' load a VCF (variant) track provided as a Bioconductor VariantAnnotation object
#'
#' @description load a VCF (variant) track provided as a Bioconductor VariantAnnotation object
#'
#' @rdname loadVcfTrack
#' @aliases loadVcfTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param vcfData VariantAnnotation object
#' @param deleteTracksOfSameName logical, default TRUE
#'
#' @return
#' nothing
#'
#' @export

loadVcfTrack <- function(session, id, trackName, vcfData, deleteTracksOfSameName=TRUE)
{

   printf("======== igvShiny.R, loadVcfTrack")
   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))
   path <- file.path("tracks", "tmp.vcf")
   printf("igvShiny::loadVcfTrac, about to write to file '%s'", path)
   writeVcf(vcfData, path)
   printf("igvShiny::loadVcfTrac, file.exists(%s)? %s", path, file.exists(path))

   message <- list(elementID=id, trackName=trackName, vcfDataFilepath=path)
   session$sendCustomMessage("loadVcfTrack", message)

} # loadVcfTrack
#------------------------------------------------------------------------------------------------------------------------
#' load a GWAS (genome-wide association study)  track provided as a data.frame
#'
#' @description load a GWAS (genome-wide association study)  track provided as a data.frame
#'
#' @rdname loadGwasTrack
#' @aliases loadGwasTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param tbl.gwas data.frame, with at least "chrom" "start" "end" columns
#' @param deleteTracksOfSameName logical, default TRUE
#'
#' @return
#' nothing
#'
#' @export
loadGwasTrack <- function(session, id, trackName, tbl.gwas, ymin = 0, ymax = 35, deleteTracksOfSameName=TRUE)
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
                   min=ymin, max=ymax)
   session$sendCustomMessage("loadGwasTrack", message)

} # loadGwasTrack
#------------------------------------------------------------------------------------------------------------------------
#' load a bam track which, with index, is served up by http
#'
#' @description
#'
#' @rdname loadBamTrackFromURL
#' @aliases loadBamTrackFromURL
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param bamURL character string http url for the bam file, typically very large
#' @param indexURL character string http url for the bam file index, typically small
#' @param deleteTracksOfSameName logical, default TRUE
#' @param displayMode character string, possible values are "EXPANDED" (default),
#'   "SQUISHED" or "COLLAPSED"
#' @param showAllBases logical, show all bases in the alignment, default FALSE
#'
#' @return
#' nothing
#'
#' @export

loadBamTrackFromURL <- function(session, id, trackName, bamURL, indexURL, deleteTracksOfSameName=TRUE,
                                displayMode = "EXPANDED", showAllBases = FALSE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))
   message <- list(elementID=id,trackName=trackName, bam=bamURL, index=indexURL,
                   displayMode = displayMode, showAllBases = showAllBases)
   printf("--- about to send message, loadBamTrack")
   session$sendCustomMessage("loadBamTrackFromURL", message)

} # loadBamTrackFromURL
#------------------------------------------------------------------------------------------------------------------------
#' load GenomicAlignments data as an igv.js alignemnt track
#'
#' @description load GenomicAlignments data  as an igv.js alignemnt track
#' @rdname loadBamTrackFromLocalData
#' @aliases loadBamTrackFromLocalData
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param data  GenomicAlignments object
#' @param deleteTracksOfSameName logical, default TRUE
#' @param displayMode character string, possible values are "EXPANDED" (default),
#'   "SQUISHED" or "COLLAPSED"
#'
#' @return
#' nothing
#'
#' @export

loadBamTrackFromLocalData <- function(session, id, trackName, data, deleteTracksOfSameName=TRUE,
                                      displayMode = "EXPANDED")
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   directory.name <- "tracks"   # need this as directory within the current working directory
   if(!dir.exists(directory.name)) dir.create(directory.name)
   file.path <- tempfile(tmpdir=directory.name, fileext=".bam")

   printf("igvShiny::load bam from local data, about to write to file '%s'", file.path)
   export(data, file.path, format="BAM")

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(elementID=id, trackName=trackName, bamDataFilepath=file.path,
                   displayMode = displayMode)
   session$sendCustomMessage("loadBamTrackFromLocalData", message)

} # loadBanTrackFromLocalData
#------------------------------------------------------------------------------------------------------------------------
#' load a cram track which, with index, is served up by http
#'
#' @description
#'
#' @rdname loadCramTrackFromURL
#' @aliases loadCramTrackFromURL
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param cramURL character string http url for the bam file, typically very large
#' @param indexURL character string http url for the bam file index, typically small
#' #' @param deleteTracksOfSameName logical, default TRUE
#'
#' @return
#' nothing
#'
#' @export

loadCramTrackFromURL <- function(session, id, trackName, cramURL, indexURL, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(elementID=id,trackName=trackName, cram=cramURL, index=indexURL)
   session$sendCustomMessage("loadCramTrackFromURL", message)

} # loadCramTrack
#------------------------------------------------------------------------------------------------------------------------

