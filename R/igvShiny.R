#' @import BiocGenerics
#' @import GenomicRanges
#' @import GenomeInfoDbData
#' @import rtracklayer
#' @import shiny
#' @import jsonlite
#' @import randomcoloR
#' @import httr
#'
#' @name igvShiny
#' @rdname igvShiny

library(randomcoloR)
randomColors <- distinctColorPalette(24)
#----------------------------------------------------------------------------------------------------
verbose <- TRUE
log <- function(...)if(verbose) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
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
#' @param genomeOptions a list with these fields: genomeName, initialLocus,
#' @param options a list, with required elements 'genomeName' and 'initialLocus'.
#'   Local or remote custom genomes can be used by setting 'genomeName' to 'local' or
#'   'remote'. The necessary fasta and index files are provided via 'fasta' and 'index'
#'   arguments, either as path on disk or as URL.
#' @param width a character string, standard css notations, either e.g., "1000px" or "95\%"
#' @param height a character string, needs to be an explicit pixel measure, e.g., "800px"
#' @param elementId a character string, the html element id within which igv is created
#' @param displayMode a character string, default "SQUISHED".
#' @param tracks a list of track specifications to be created and displayed at startup
#' @return the created widget
#'
#' @export
#'
igvShiny <- function(genomeOptions, width = NULL, height = NULL,
                     elementId = NULL, displayMode="squished", tracks=list())
{

  stopifnot(sort(names(genomeOptions)) ==
            c("annotation", "dataMode", "fasta", "fastaIndex", "genomeName", "initialLocus",
              "stockGenome", "validated"))
  stopifnot(genomeOptions[["validated"]])

  if(!genomeOptions[["stockGenome"]] && genomeOptions[["dataMode"]] == "localFiles"){
     directory.name <- "tracks"     # todo: may wish to parameterize this directory name
     fasta.file <- genomeOptions[["fasta"]]
     fasta.indexFile <- genomeOptions[["fastaIndex"]]
     gff3.file <- genomeOptions[["annotation"]]
     if(!dir.exists(directory.name))
        dir.create(directory.name)
     destination <- file.path(directory.name, basename(fasta.file))
     file.copy(fasta.file, destination, overwrite = TRUE)
     destination <- file.path(directory.name, basename(fasta.indexFile))
     file.copy(fasta.indexFile, destination, overwrite = TRUE)
     if(!is.na(gff3.file)){
        destination <- file.path(directory.name, basename(gff3.file))
        file.copy(gff3.file, destination, overwrite = TRUE)
        genomeOptions[["annotation"]] <- file.path(directory.name, basename(gff3.file))
        }
        # now that they have been copied, store the new paths
     genomeOptions[["fasta"]] <- file.path(directory.name, basename(fasta.file))
     genomeOptions[["fastaIndex"]] <- file.path(directory.name, basename(fasta.indexFile))
     } # if custom genome, local files

  state[["requestedHeight"]] <- height

  log("--- ~/github/igvShiny/R/igvShiny ctor");
  log("  initial track count: %d", length(tracks))

    #send namespace info in case widget is being called from a module
  session <- shiny::getDefaultReactiveDomain()
  genomeOptions$displayMode <- displayMode
  genomeOptions$trackHeight <- 100      # todo: make this an igvShiny ctor argument
  genomeOptions$moduleNS <- session$ns("")

  htmlwidgets::createWidget(
    name = 'igvShiny',
    genomeOptions,
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
      log("setting height from state")
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
   log("--- leaving igvShiny.R, renderIgvShiny")
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
   log("--- igvShiny sending message to js, removeTracksByName, %s", paste(trackNames, sep=","))
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
      log("--- igvShiny::loadBedTrack");
      log("rows: %d  cols: %d", nrow(tbl), ncol(tbl))
      }

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   if(colnames(tbl)[1] == "chrom")
      colnames(tbl)[1] <- "chr"

   if(all(colnames(tbl)[1:3] != c("chr", "start", "end"))){
      log("found these colnames: %s", paste(colnames(tbl), collapse=", "))
      log("            required: %s", paste(c("chr", "start", "end"), collapse=", "))
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
                              autoscale, autoscaleGroup=-1,
                              min=NA_real_, max=NA_real_,
                              deleteTracksOfSameName=TRUE, quiet=TRUE)
{
   stopifnot(ncol(tbl) >= 4)

   if(color == "random")
      color <- randomColors[sample(seq_len(length(randomColors)), 1)]

   if(!quiet){
      log("--- igvShiny::loadBedGraphTrack: %s", trackName);
      log("    %d rows, %d columns", nrow(tbl), ncol(tbl))
      #log("    colnames: %s", paste(colnames(tbl), collapse=", "))
      #log("    col classes: %s", paste(unlist(lapply(tbl, class)), collapse=", "))
      }

   if(deleteTracksOfSameName){
      log("--- igvShiny.R loadBedGraphTrack, calling removeTracksByName: %s, %s", id, trackName)
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   if(colnames(tbl)[1] == "chrom")
      colnames(tbl)[1] <- "chr"

   colnames(tbl)[4] <- "value"

   if(all(colnames(tbl)[1:3] != c("chr", "start", "end"))){
      log("found these colnames: %s", paste(colnames(tbl)[1:3], collapse=", "))
      log("            required: %s", paste(c("chr", "start", "end"), collapse=", "))
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
                      autoscale=autoscale, min=min, max=max,
                      autoscaleGroup=autoscaleGroup)  # -1 means no grouping

   session$sendCustomMessage("loadBedGraphTrack", msg.to.igv)

} # loadBedGraphTrack
#------------------------------------------------------------------------------------------------------------------------
#' load a scored genome annotation track provided as a data.frame
#'
#' @description load a genome annotation track provided as a data.frame
#'
#' @rdname loadGenomeAnnotationTrack
#' @aliases loadGenomeAnnotationTrack
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
                              autoscale, autoscaleGroup=-1,
                              min=NA_real_, max=NA_real_,
                              deleteTracksOfSameName=TRUE, quiet=TRUE)
{
   stopifnot(ncol(tbl) >= 4)

   if(color == "random")
      color <- randomColors[sample(seq_len(length(randomColors)), 1)]

   if(!quiet){
      log("--- igvShiny::loadGenomeAnnotationTrack: %s", trackName);
      log("    %d rows, %d columns", nrow(tbl), ncol(tbl))
      #log("    colnames: %s", paste(colnames(tbl), collapse=", "))
      #log("    col classes: %s", paste(unlist(lapply(tbl, class)), collapse=", "))
      }

   if(deleteTracksOfSameName){
      log("--- igvShiny.R loadBedGraphTrack, calling removeTracksByName: %s, %s", id, trackName)
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   if(colnames(tbl)[1] == "chrom")
      colnames(tbl)[1] <- "chr"

   colnames(tbl)[4] <- "value"

   if(all(colnames(tbl)[1:3] != c("chr", "start", "end"))){
      log("found these colnames: %s", paste(colnames(tbl)[1:3], collapse=", "))
      log("            required: %s", paste(c("chr", "start", "end"), collapse=", "))
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
                      autoscale=autoscale, min=min, max=max,
                      autoscaleGroup=autoscaleGroup)  # -1 means no grouping

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
   log("--- entering loadSegTrack %s with %d rows", trackName, nrow(tbl))

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(elementID=id, trackName=trackName, tbl=jsonlite::toJSON(tbl))
   log("about to send loadSegTrack message")
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

   log("======== igvShiny.R, loadVcfTrack")
   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))
   path <- file.path("tracks", "tmp.vcf")
   log("igvShiny::loadVcfTrac, about to write to file '%s'", path)
   writeVcf(vcfData, path)
   log("igvShiny::loadVcfTrac, file.exists(%s)? %s", path, file.exists(path))

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
   log("======== entering igvShiny::loadGwasTrack")

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   temp.file <- tempfile(tmpdir="tracks", fileext=".gwas")
   write.table(tbl.gwas, sep="\t", row.names=FALSE, quote=FALSE, file=temp.file)
   log("--- igvShiny.R, loadGwasTrack wrote %d,%d to %s", nrow(tbl.gwas), ncol(tbl.gwas),
          temp.file)
   log("exists? %s", file.exists(temp.file))
   message <- list(elementID=id, trackName=trackName, gwasDataFilepath=temp.file,
                   color="red", trackHeight=200, autoscale=FALSE,
                   min=ymin, max=ymax)
   session$sendCustomMessage("loadGwasTrack", message)

} # loadGwasTrack
#------------------------------------------------------------------------------------------------------------------------
#' load a bam track which, with index, is served up by http
#'
#' @description load a remote bam track
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
   log("--- about to send message, loadBamTrack")
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

   log("igvShiny::load bam from local data, about to write to file '%s'", file.path)
   export(data, file.path, format="BAM")

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(elementID=id, trackName=trackName, bamDataFilepath=file.path,
                   displayMode = displayMode)
   session$sendCustomMessage("loadBamTrackFromLocalData", message)

} # loadBamTrackFromLocalData
#------------------------------------------------------------------------------------------------------------------------
#' load a cram track which, with index, is served up by http
#'
#' @description load a remote cram track
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

} # loadCramTrackFromURL
#------------------------------------------------------------------------------------------------------------------------
#' load a GFF3 track which, with index, is served up by http
#'
#' @description load a remote GFF3 track
#'
#' @rdname loadGFF3TrackFromURL
#' @aliases loadGFF3TrackFromURL
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param gff3URL character string http url for the bam file, typically very large
#' @param indexURL character string http url for the bam file index, typically small
#' @param color character #RGB or a recognized color name.  ignored if colorTable and colorByAttribute provided
#' @param colorTable list, mapping a gff3 attribute, typically biotype, to a color
#' @param colorByAttribute character, name of a gff3 attribute in column 9, typically 'biotype'
#' @param displayMode character,  "EXPANDED",  "SQUISHED" or "COLLAPSED"
#' @param visibilityWindow numeric, Maximum window size in base pairs for which indexed annotations or variants are displayed
#' @param deleteTracksOfSameName logical, default TRUE
#'
#' @return
#' nothing
#'
#' @export

loadGFF3TrackFromURL <- function(session, id, trackName, gff3URL, indexURL,
                                 color="gray", colorTable, colorByAttribute,
                                 displayMode, trackHeight=50,
                                 visibilityWindow, deleteTracksOfSameName=TRUE)
{
   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   message <- list(elementID=id,trackName=trackName, dataURL=gff3URL, indexURL=indexURL,
                   color=color, colorTable=colorTable, colorByAttribute=colorByAttribute,
                   displayMode=displayMode, trackHeight=trackHeight,
                   visibilityWindow=visibilityWindow)

   session$sendCustomMessage("loadGFF3TrackFromURL", message)

} # loadGFF3TrackFromURL
#------------------------------------------------------------------------------------------------------------------------
#' load a GFF3 track defined by local data
#'
#' @description load a local GFF3 track file
#'
#' @rdname loadGFF3TrackFromLocalData
#' @aliases loadGFF3TrackFromLocalData
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param tbl.gff3 data.frame  in standard 9-column GFF3 format
#' @param color character #RGB or a recognized color name.  ignored if colorTable and colorByAttribute provided
#' @param colorTable list, mapping a gff3 attribute, typically biotype, to a color
#' @param colorByAttribute character, name of a gff3 attribute in column 9, typically 'biotype'
#' @param displayMode character,  "EXPANDED",  "SQUISHED" or "COLLAPSED"
#' @param visibilityWindow numeric, Maximum window size in base pairs for which indexed annotations or variants are displayed
#' @param deleteTracksOfSameName logical, default TRUE
#'
#' @return
#' nothing
#'
#' @export

loadGFF3TrackFromLocalData <- function(session, id, trackName, tbl.gff3,
                                       color="gray", colorTable, colorByAttribute,
                                       displayMode, trackHeight=50,
                                       visibilityWindow, deleteTracksOfSameName=TRUE)
{
   log("--- entering loadGFF3TrackFromLocalDAta")

   if(deleteTracksOfSameName){
      removeTracksByName(session, id, trackName);
      }

   state[["userAddedTracks"]] <- unique(c(state[["userAddedTracks"]], trackName))

   gff3.filePath <- tempfile(tmpdir="tracks", fileext=".gff3")
   write.table(tbl.gff3, sep="\t", row.names=FALSE, quote=FALSE, file=gff3.filePath)
   log("--- igvShiny.R, loadGFF3TrackFromLocalData wrote %d,%d to %s",
       nrow(tbl.gff3), ncol(tbl.gff3), gff3.filePath)

   log("exists? %s", file.exists(gff3.filePath))

   message <- list(elementID=id, trackName=trackName, filePath=gff3.filePath,
                   color=color, colorTable=colorTable, colorByAttribute=colorByAttribute,
                   displayMode=displayMode, trackHeight=trackHeight,
                   visibilityWindow=visibilityWindow)

   session$sendCustomMessage("loadGFF3TrackFromLocalData", message)

} # loadGFF3TrackFromLocalData
#------------------------------------------------------------------------------------------------------------------------

