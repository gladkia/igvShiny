# THE FOLLOWING WAS MOVED OUT OF doc section for igvShiny
# param options a list, with required elements "genomeName" and "initialLocus".
#   Local or remote custom genomes can be used by setting "genomeName" to
#   "local" or "remote". The necessary fasta and index files are provided via
#   "fasta" and "index" arguments, either as path on disk or as URL.

#-------------------------------------------------------------------------------
# A list of safe, known igv.js track configuration parameters.
# This allowlist prevents arbitrary code injection and invalid options.
# Sourced from igv.js documentation.
.validIgvTrackOptions <- c(
  "name", "type", "format", "url", "indexURL", "indexed", "order", "displayMode",
  "color", "altColor", "negColor", "posColor", "borderColor", "trait",
  "height", "autoHeight", "minHeight", "maxHeight", "removable",
  "visibilityWindow", "searchable", "autoScale", "autoscale", "autoScaleGroup",
  "autoscaleGroup", "min", "max", "logScale", "graphType", "barChart",
  "flipAxis", "stroke", "noStroke", "fill", "noFill", "featureHeight", "showLabels",
  "font", "fontSize", "fontStyle", "fontWeight", "colorTable", "colorByAttribute",
  "showAllBases", "samplingWindowSize", "samplingDepth", "maxRows",
  "hideEmptyTracks", "oauthToken", "headers", "viewAsPairs", "pairsSupported",
  "maxPanelHeight", "separateBam", "wholeGenomeView", "roi", "queryable"
  # Add other valid igv.js track options here as needed in the future
)

#-------------------------------------------------------------------------------
#' Sanitize and merge track configuration options
#' @param baseOptions A list of default options set by the R function.
#' @param userOptions A list of options provided by the user via trackConfig.
#' @return A merged and sanitized list of options ready to be sent to JavaScript.
#' @keywords igvShiny
.sanitizeAndMergeOptions <- function(baseOptions, userOptions) {
  if (is.null(userOptions) || length(userOptions) == 0) {
    return(baseOptions)
  }

  if (!is.list(userOptions) || is.null(names(userOptions)) || any(names(userOptions) == "")) {
    warning("trackConfig must be a named list. Ignoring.")
    return(baseOptions)
  }

  # Identify and warn about conflicting keys that would override explicit function arguments
  conflictingKeys <- intersect(names(baseOptions), names(userOptions))
  if (length(conflictingKeys) > 0) {
    warning(sprintf("User-provided trackConfig options conflict with function arguments and will be ignored: %s",
                    paste(conflictingKeys, collapse = ", ")))
    userOptions[conflictingKeys] <- NULL # Prioritize base options for security and clarity
  }

  # Filter user options against the allowlist of valid igv.js parameters
  invalidKeys <- setdiff(names(userOptions), .validIgvTrackOptions)
  if (length(invalidKeys) > 0) {
    warning(sprintf("Ignoring invalid or unsupported track options in trackConfig: %s",
                    paste(invalidKeys, collapse = ", ")))
    userOptions[invalidKeys] <- NULL
  }

  # Merge the sanitized user options with the base options
  return(c(baseOptions, userOptions))
}
#-------------------------------------------------------------------------------
#' Create an igvShiny instance
#'
#' @description This function is called in the server function of your shiny app
#'
#' @rdname igvShiny
#' @aliases igvShiny
#'
#' @import BiocGenerics
#' @import GenomicRanges
#' @import GenomeInfoDbData
#' @import shiny
#' @importFrom randomcoloR distinctColorPalette
#' @import httr
#' @importFrom htmlwidgets createWidget shinyWidgetOutput shinyRenderWidget
#' @importFrom futile.logger flog.debug
#'
#' @param genomeOptions a list with these fields: genomeName, initialLocus,
#' annotation, dataMode, fasta, fastaIndex, stockGenome, validated
#' @param width a character string, standard css notations,
#' either e.g., "1000px" or "95\%"
#' @param height a character string, needs to be an explicit pixel measure,
#' e.g., "800px"
#' @param elementId a character string, the html element id within which
#' igv is created
#' @param displayMode a character string, default "SQUISHED".
#' @param tracks a list of track specifications to be created
#' and displayed at startup
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return the created widget
#'
#' @keywords igvShiny
#' @export
#'
igvShiny <- function(genomeOptions,
                     width = NULL,
                     height = NULL,
                     elementId = NULL,
                     displayMode = "squished",
                     tracks = list()) {
  stopifnot(
    sort(names(genomeOptions)) ==
      c(
        "annotation",
        "dataMode",
        "fasta",
        "fastaIndex",
        "genomeName",
        "initialLocus",
        "stockGenome",
        "validated"
      )
  )
  stopifnot(genomeOptions[["validated"]])

  if (!genomeOptions[["stockGenome"]] &&
        genomeOptions[["dataMode"]] == "localFiles") {
    directory.name <- get_tracks_dir()
    fasta.file <- genomeOptions[["fasta"]]
    fasta.indexFile <- genomeOptions[["fastaIndex"]]
    gff3.file <- genomeOptions[["annotation"]]
    destination <-
      file.path(directory.name, basename(fasta.file))
    file.copy(fasta.file, destination, overwrite = TRUE)
    destination <-
      file.path(directory.name, basename(fasta.indexFile))
    file.copy(fasta.indexFile, destination, overwrite = TRUE)
    if (!is.na(gff3.file)) {
      destination <- file.path(directory.name, basename(gff3.file))
      file.copy(gff3.file, destination, overwrite = TRUE)
      genomeOptions[["annotation"]] <-
        file.path(basename(directory.name), basename(gff3.file))
    }
    # now that they have been copied, store the new paths
    genomeOptions[["fasta"]] <-
      file.path(basename(directory.name), basename(fasta.file))
    genomeOptions[["fastaIndex"]] <-
      file.path(basename(directory.name), basename(fasta.indexFile))
  } # if custom genome, local files

  state[["requestedHeight"]] <- height

  flog.debug("---igvShiny ctor")
  flog.debug(sprintf("--initial track count: %d", length(tracks)))

  #send namespace info in case widget is being called from a module
  session <- shiny::getDefaultReactiveDomain()
  genomeOptions$displayMode <- displayMode
  genomeOptions$trackHeight <-
    100      # todo: make this an igvShiny ctor argument
  genomeOptions$moduleNS <- session$ns("")

  htmlwidgets::createWidget(
    name = "igvShiny",
    genomeOptions,
    width = width,
    height = height,
    package = "igvShiny",
    elementId = elementId
  )

} # igvShiny constructor
#-------------------------------------------------------------------------------
#' create the UI for the widget
#'
#' @description This function is called in the ui function of your shiny app
#'
#' @rdname igvShinyOutput
#' @aliases igvShinyOutput
#'
#' @param outputId a character string, specifies the html element id
#' @param width a character string, standard css notations,
#' either e.g., "1000px" or "95\%", "100\%" by default
#' @param height a character string, needs to be an explicit pixel measure,
#' e.g., "800px", "400px" by default
#'
#' @return the created widget's html
#'
#' @examples
#' io <- igvShinyOutput("igvOut")
#'
#' @keywords igvShiny
#' @export
#'
igvShinyOutput <- function(outputId,
                           width = "100%",
                           height = NULL) {
  if ("requestedHeight" %in% ls(state)) {
    flog.debug("setting height from state")
    height <- state[["requestedHeight"]]
  }

  htmlwidgets::shinyWidgetOutput(outputId,
                                 "igvShiny",
                                 width,
                                 height,
                                 package = "igvShiny")
}

#-------------------------------------------------------------------------------
#' draw the igv genome browser element
#'
#' @description This function is called in the server function of your shiny app
#'
#' @rdname renderIgvShiny
#' @aliases renderIgvShiny
#'
#' @param expr an expression that generates an HTML widget
#' @param env  the environment in which to evaluate expr
#' @param quoted logical flag indicating if expr a quoted expression
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return an output or render function that enables the use of the widget
#' within Shiny applications
#'
#' @keywords igvShiny
#' @export
renderIgvShiny <- function(expr,
                           env = parent.frame(),
                           quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted

  x <- htmlwidgets::shinyRenderWidget(expr,
                                      igvShinyOutput,
                                      env,
                                      quoted = TRUE)
  flog.debug("--- leaving igvShiny.R, renderIgvShiny")
  return(x)

}

#-------------------------------------------------------------------------------
#' focus igv on a region
#'
#' @description zoom in or out to show the nominated region, by chromosome locus
#' or gene symbol
#'
#' @rdname showGenomicRegion
#' @aliases showGenomicRegion
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param region a character string, either e.g. "chr5:92,221,640-92,236,523"
#' or "MEF2C"
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @keywords igvShiny
#' @export
showGenomicRegion <- function(session, id, region) {
  message <- list(region = region, elementID = id)
  session$sendCustomMessage("showGenomicRegion", message)
} # showGenomicRegion

#-------------------------------------------------------------------------------
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
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' a character string of format "chrom:start-end"
#'
#' @keywords igvShiny
#' @export

getGenomicRegion <- function(session, id) {
  message <- list(elementID = id)
  session$sendCustomMessage("getGenomicRegion", message)
} # gertGenomicRegion

#-------------------------------------------------------------------------------
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

#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords igvShiny
#' @export
removeTracksByName <- function(session, id, trackNames) {
  message <- list(trackNames = trackNames, elementID = id)
  lmsg <-
    sprintf("--- igvShiny sending message to js, removeTracksByName, %s",
            toString(trackNames))
  flog.debug(lmsg)
  session$sendCustomMessage("removeTracksByName", message)

} # removeTracksByName

#-------------------------------------------------------------------------------
#' remove only those tracks explicitly added by your app
#'
#' @description remove only those tracks explicitly added by your app.
#' stock tracks (i.e., #' Refseq Genes) remain
#'
#' @rdname removeUserAddedTracks
#' @aliases removeUserAddedTracks
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords igvShiny
#' @export

removeUserAddedTracks <- function(session, id) {

  removeTracksByName(session, id, state[["userAddedTracks"]])
  state[["userAddedTracks"]] <- list()

} # removeUserAddedTracks

#-------------------------------------------------------------------------------
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
#' @param color character string, a legal CSS color, or "random",
#' "gray" by default
#' @param trackHeight an integer, 50 (pixels) by default
#' @param deleteTracksOfSameName logical, default TRUE
#' @param quiet logical, default TRUE, controls verbosity
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadBedTrack <-
  function(session,
           id,
           trackName,
           tbl,
           color = "",
           trackHeight = 50,
           deleteTracksOfSameName = TRUE,
           quiet = TRUE,
           trackConfig = list()) {
    if (color == "random")
      color <-
        randomColors[sample(seq_len(length(randomColors)), 1)]

    if (!quiet) {
      flog.debug("--- igvShiny::loadBedTrack")

      flog.debug(sprintf("rows: %d  cols: %d", nrow(tbl), ncol(tbl)))
    }

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    if (colnames(tbl)[1] == "chrom")
      colnames(tbl)[1] <- "chr"

    if (all(colnames(tbl)[c(1, 2, 3)] != c("chr", "start", "end"))) {
      lmsg <- sprintf("found these colnames: %s",
                      toString(colnames(tbl)))
      lmsg2 <- sprintf("            required: %s",
                       toString(c("chr", "start", "end")))
      flog.debug(lmsg)
      flog.debug(lmsg2)
      stop("improper columns in bed track data.frame")
    }

    stopifnot(is(tbl$chr, "character"))
    stopifnot(is(tbl$start, "numeric"))
    stopifnot(is(tbl$end, "numeric"))
    new.order <- order(tbl$start, decreasing = FALSE)
    tbl <- tbl[new.order, ]

    temp.file <-
      tempfile(tmpdir = get_tracks_dir(), fileext = ".bed")
    write.table(
      tbl,
      sep = "\t",
      row.names = FALSE,
      col.names = FALSE,
      quote = FALSE,
      file = temp.file
    )
    lmsg <- sprintf("--- igvShiny.R, loadBedTrack wrote %d,%d to %s",
                    nrow(tbl),
                    ncol(tbl),
                    temp.file)
    flog.debug(lmsg)
    flog.debug(sprintf("exists? %s", file.exists(temp.file)))

    base.msg.to.igv <- list(
      elementID = id,
      trackName = trackName,
      bedFilepath = file.path("tracks", basename(temp.file)),
      color = color,
      trackHeight = trackHeight
    )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    session$sendCustomMessage("loadBedTrackFromFile", msg.to.igv)

  } # loadBedTrack

#-------------------------------------------------------------------------------
#' load a bedgraph track from a URL
#'
#' @description load a bedgraph track provided as a data.frame
#'
#' @rdname loadBedGraphTrackFromURL
#' @aliases loadBedGraphTrackFromURL
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param url character
#' @param color character string, a legal CSS color, or "random",
#' "gray" by default
#' @param trackHeight an integer, 30 (pixels) by default
#' @param autoscale logical
#' @param min numeric, consulted when autoscale is FALSE
#' @param max numeric, consulted when autoscale is FALSE
#' @param quiet logical, default TRUE, controls verbosity
#' @param autoscaleGroup numeric(1) defaults to -1
#' @param deleteTracksOfSameName logical(1) defaults to TRUE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadBedGraphTrackFromURL <-
  function(session,
           id,
           trackName,
           url,
           color = "gray",
           trackHeight = 30,
           autoscale = TRUE,
           min = 0,
           max = 1,
           autoscaleGroup = -1,
           deleteTracksOfSameName = TRUE,
           quiet = TRUE,
           trackConfig = list()) {
    message("---- loadBedGraphTrackFromURL")

    if (color == "random")
      color <-
        randomColors[sample(seq_len(length(randomColors)), 1)]

    if (!quiet) {
      lmsg <- sprintf("--- igvShiny::loadBedGraphTrackFromURL: %s",
                      trackName)
      flog.debug(lmsg)
    }

    if (deleteTracksOfSameName) {
      lmsg <- sprintf(
        "--- loadBedGraphTrackFromURL, calling removeTracksByName: %s, %s",
        id,
        trackName
      )
      flog.debug(lmsg)
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        url = url,
        color = color,
        trackHeight = trackHeight,
        autoscale = autoscale,
        min = min,
        max = max,
        autoscaleGroup = autoscaleGroup
      )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)

    flog.debug("--- igvShiny.R loadBedGraphTrackFromURL, msg.to.igv: ")
    futile.logger::flog.info(jsonlite::toJSON(msg.to.igv))
    flog.debug("--- igvShiny.R loadBedGraphTrackFromURL, sendingCustomMessage")
    session$sendCustomMessage("loadBedGraphTrackFromURL", msg.to.igv)
    flog.debug("--- loadBedGraphTrackFromURL, after sendingCustomMessage")

  } # loadBedGraphTrackFromURL

#-------------------------------------------------------------------------------
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
#' @param color character string, a legal CSS color, or "random",
#' "gray" by default
#' @param trackHeight an integer, 30 (pixels) by default
#' @param autoscale logical
#' @param autoscaleGroup numeric(1) defaults to -1
#' @param min numeric, consulted when autoscale is FALSE
#' @param max numeric, consulted when autoscale is FALSE
#' @param deleteTracksOfSameName logical, default TRUE
#' @param quiet logical, default TRUE, controls verbosity
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadBedGraphTrack <-
  function(session,
           id,
           trackName,
           tbl,
           color = "gray",
           trackHeight = 30,
           autoscale,
           autoscaleGroup = -1,
           min = NA_real_,
           max = NA_real_,
           deleteTracksOfSameName = TRUE,
           quiet = TRUE,
           trackConfig = list()) {
    stopifnot(ncol(tbl) >= 4)

    if (color == "random")
      color <-
        randomColors[sample(seq_len(length(randomColors)), 1)]

    if (!quiet) {
      flog.debug("--- igvShiny::loadGenomeAnnotationTrack: %s",
                 trackName)
      flog.debug("    %d rows, %d columns", nrow(tbl), ncol(tbl))
    }

    if (deleteTracksOfSameName) {
      flog.debug(
        "--- igvShiny.R loadBedGraphTrack, calling removeTracksByName: %s, %s",
        id,
        trackName
      )
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    if (colnames(tbl)[1] == "chrom")
      colnames(tbl)[1] <- "chr"

    colnames(tbl)[4] <- "value"

    if (all(colnames(tbl)[c(1, 2, 3)] != c("chr", "start", "end"))) {
      flog.debug("found these colnames: %s",
                 paste(colnames(tbl)[c(1, 2, 3)],
                       collapse = ", "))
      flog.debug("            required: %s",
                 paste(c("chr", "start", "end"),
                       collapse = ", "))
      stop("improper columns in bed track data.frame")
    }

    stopifnot(is(tbl$chr, "character"))
    stopifnot(is(tbl$start, "numeric"))
    stopifnot(is(tbl$end, "numeric"))
    stopifnot(is(tbl$value, "numeric"))

    new.order <- order(tbl$start, decreasing = FALSE)
    tbl <- tbl[new.order, ]

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        tbl = jsonlite::toJSON(tbl),
        color = color,
        trackHeight = trackHeight,
        autoscale = autoscale,
        min = min,
        max = max,
        autoscaleGroup = autoscaleGroup
      )  # -1 means no grouping

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    session$sendCustomMessage("loadBedGraphTrack", msg.to.igv)

  } # loadBedGraphTrack
#-------------------------------------------------------------------------------
#' load a seg track provided as a data.frame
#'
#' @description load a SEG track provided as a data.frame.  igv "displays
#' segmented data as a blue-to-red heatmap where the data range is
#' -1.5 to 1.5... The segmented data file format is the output of
#' the Circular Binary Segmentation algorithm (Olshen et al., 2004)".
#'
#' @rdname loadSEGTrack
#' @aliases loadSEGTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" "start" "end" "score" columns
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export
loadSegTrack <-
  function(session,
           id,
           trackName,
           tbl,
           deleteTracksOfSameName = TRUE,
           trackConfig = list()) {
    flog.debug("--- entering loadSegTrack %s with %d rows",
               trackName,
               nrow(tbl))

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        tbl = jsonlite::toJSON(tbl)
      )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    flog.debug("about to send loadSegTrack message")
    session$sendCustomMessage("loadSegTrack", msg.to.igv)

  } # loadSegTrack

#-------------------------------------------------------------------------------
#' load a VCF (variant) track provided as a Bioconductor
#' VariantAnnotation object
#'
#' @description load a VCF (variant) track provided as a Bioconductor
#' VariantAnnotation object
#'
#' @rdname loadVcfTrack
#' @aliases loadVcfTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param vcfData VariantAnnotation object
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo-withVCF.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadVcfTrack <- function(session,
                         id,
                         trackName,
                         vcfData,
                         deleteTracksOfSameName = TRUE,
                         trackConfig = list()) {
  if (!requireNamespace("VariantAnnotation"))
    stop("install VariantAnnotation to use this function")

  flog.debug("======== igvShiny.R, loadVcfTrack")
  if (deleteTracksOfSameName) {
    removeTracksByName(session, id, trackName)
  }

  state[["userAddedTracks"]] <-
    unique(c(state[["userAddedTracks"]], trackName))
  temp.file <- tempfile(tmpdir = get_tracks_dir(), fileext = ".vcf")
  lmsg <- sprintf("igvShiny::loadVcfTrack, about to write to file '%s'", temp.file)
  flog.debug(lmsg)
  VariantAnnotation::writeVcf(vcfData, temp.file)
  lmsg2 <- sprintf("igvShiny::loadVcfTrack, file.exists(%s)? %s",
                   temp.file,
                   file.exists(temp.file))
  flog.debug(lmsg2)

  path <- file.path("tracks", basename(temp.file))
  base.msg.to.igv <-
    list(
      elementID = id,
      trackName = trackName,
      vcfDataFilepath = path
    )

  msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
  session$sendCustomMessage("loadVcfTrack", msg.to.igv)

} # loadVcfTrack

#-------------------------------------------------------------------------------
#' load a GWAS (genome-wide association study) track
#' provided as a data.frame
#'
#' @description load a GWAS (genome-wide association study) track
#' provided as a data.frame
#'
#' @rdname loadGwasTrack
#' @aliases loadGwasTrack
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param ymin numeric defaults to 0
#' @param ymax numeric defaults to 35
#' @param tbl.gwas data.frame, with at least "chrom" "start" "end" columns
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export
loadGwasTrack <- function(session,
                          id,
                          trackName,
                          tbl.gwas,
                          ymin = 0,
                          ymax = 35,
                          deleteTracksOfSameName = TRUE,
                          trackConfig = list()) {
  flog.debug("======== entering igvShiny::loadGwasTrack")

  if (deleteTracksOfSameName) {
    removeTracksByName(session, id, trackName)
  }

  state[["userAddedTracks"]] <-
    unique(c(state[["userAddedTracks"]], trackName))

  temp.file <-
    tempfile(tmpdir = get_tracks_dir(), fileext = ".gwas")
  write.table(
    tbl.gwas,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    file = temp.file
  )
  lmsg <- sprintf(
    "--- igvShiny.R, loadGwasTrack wrote %d,%d to %s",
    nrow(tbl.gwas),
    ncol(tbl.gwas),
    temp.file
  )
  flog.debug(lmsg)
  flog.debug(sprintf("exists? %s", file.exists(temp.file)))
  base.msg.to.igv <-
    list(
      elementID = id,
      trackName = trackName,
      gwasDataFilepath = file.path("tracks", basename(temp.file)),
      color = "red",
      trackHeight = 200,
      autoscale = FALSE,
      min = ymin,
      max = ymax
    )

  msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
  session$sendCustomMessage("loadGwasTrack", msg.to.igv)

} # loadGwasTrack

#-------------------------------------------------------------------------------
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
#' @param bamURL character string http url for the bam file,
#' typically very large
#' @param indexURL character string http url for the bam file index,
#' typically small
#' @param deleteTracksOfSameName logical, default TRUE
#' @param displayMode character string, possible values are "EXPANDED"(default),
#' "SQUISHED" or "COLLAPSED"
#' @param showAllBases logical, show all bases in the alignment, default FALSE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadBamTrackFromURL <-
  function(session,
           id,
           trackName,
           bamURL,
           indexURL,
           deleteTracksOfSameName = TRUE,
           displayMode = "EXPANDED",
           showAllBases = FALSE,
           trackConfig = list()) {
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))
    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        bam = bamURL,
        index = indexURL,
        displayMode = displayMode,
        showAllBases = showAllBases
      )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    flog.debug("--- about to send message, loadBamTrack")
    session$sendCustomMessage("loadBamTrackFromURL", msg.to.igv)

  } # loadBamTrackFromURL

#-------------------------------------------------------------------------------
#' load GenomicAlignments data as an igv.js alignment track
#'
#' @description load GenomicAlignments data  as an igv.js alignment track
#' @rdname loadBamTrackFromLocalData
#' @aliases loadBamTrackFromLocalData
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param data  GenomicAlignments object
#' @param deleteTracksOfSameName logical, default TRUE
#' @param displayMode character string, possible values are "EXPANDED"(default),
#' "SQUISHED" or "COLLAPSED"
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadBamTrackFromLocalData <-
  function(session,
           id,
           trackName,
           data,
           deleteTracksOfSameName = TRUE,
           displayMode = "EXPANDED",
           trackConfig = list()) {
    if (!requireNamespace("rtracklayer"))
      stop("install rtracklayer to use loadBamTrackFromLocalData")
    if (!requireNamespace("Rsamtools"))
      stop("install Rsamtools to use loadBamTrackFromLocalData")
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    t_dir <- get_tracks_dir()
    fpath <- tempfile(tmpdir = t_dir, fileext = ".bam")

    lmsg <-
      sprintf("igvShiny::load bam from local data, about to write to file '%s'",
              fpath)
    flog.debug(lmsg)
    rtracklayer::export(data, fpath, format = "BAM")

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        bamDataFilepath = file.path("tracks", basename(fpath)),
        displayMode = displayMode
      )
    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    session$sendCustomMessage("loadBamTrackFromLocalData", msg.to.igv)

  } # loadBamTrackFromLocalData

#-------------------------------------------------------------------------------
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
#' @param cramURL character string http url for the bam file,
#' typically very large
#' @param indexURL character string http url for the bam file index,
#' typically small
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadCramTrackFromURL <-
  function(session,
           id,
           trackName,
           cramURL,
           indexURL,
           deleteTracksOfSameName = TRUE,
           trackConfig = list()) {
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        cram = cramURL,
        index = indexURL
      )
    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    session$sendCustomMessage("loadCramTrackFromURL", msg.to.igv)

  } # loadCramTrackFromURL

#-------------------------------------------------------------------------------
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
#' @param trackHeight numeric defaults to 50
#' @param gff3URL character string http url for the bam file,
#' typically very large
#' @param indexURL character string http url for the bam file index,
#' typically small
#' @param color character #RGB or a recognized color name.  ignored if
#' colorTable and colorByAttribute provided
#' @param colorTable list, mapping a gff3 attribute, typically biotype,
#' to a color
#' @param colorByAttribute character, name of a gff3 attribute in column 9,
#' typically "biotype"
#' @param displayMode character,  "EXPANDED",  "SQUISHED" or "COLLAPSED"
#' @param visibilityWindow numeric, Maximum window size in base pairs
#' for which indexed annotations or variants are displayed
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo-GFF3.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadGFF3TrackFromURL <-
  function(session,
           id,
           trackName,
           gff3URL,
           indexURL,
           color = "gray",
           colorTable,
           colorByAttribute,
           displayMode,
           trackHeight = 50,
           visibilityWindow,
           deleteTracksOfSameName = TRUE,
           trackConfig = list()) {

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        dataURL = gff3URL,
        indexURL = indexURL,
        color = color,
        colorTable = colorTable,
        colorByAttribute = colorByAttribute,
        displayMode = displayMode,
        trackHeight = trackHeight,
        visibilityWindow = visibilityWindow
      )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    session$sendCustomMessage("loadGFF3TrackFromURL", msg.to.igv)

  } # loadGFF3TrackFromURL
#-------------------------------------------------------------------------------
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
#' @param trackHeight numeric defaults to 50
#' @param tbl.gff3 data.frame  in standard 9-column GFF3 format
#' @param color character #RGB or a recognized color name.  ignored if
#' colorTable and colorByAttribute provided
#' @param colorTable list, mapping a gff3 attribute, typically biotype,
#' to a color
#' @param colorByAttribute character, name of a gff3 attribute in column 9,
#' typically "biotype"
#' @param displayMode character,  "EXPANDED",  "SQUISHED" or "COLLAPSED"
#' @param visibilityWindow numeric, Maximum window size in base pairs
#' for which indexed annotations or variants are displayed
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "igvShinyDemo-GFF3.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadGFF3TrackFromLocalData <-
  function(session,
           id,
           trackName,
           tbl.gff3,
           color = "gray",
           colorTable,
           colorByAttribute,
           displayMode,
           trackHeight = 50,
           visibilityWindow,
           deleteTracksOfSameName = TRUE,
           trackConfig = list()) {
    flog.debug("--- entering loadGFF3TrackFromLocalData")

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    gff3.filePath <-
      tempfile(tmpdir = get_tracks_dir(), fileext = ".gff3")
    write.table(
      tbl.gff3,
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      file = gff3.filePath
    )
    lmsg <- sprintf(
      "--- igvShiny.R, loadGFF3TrackFromLocalData wrote %d,%d to %s",
      nrow(tbl.gff3),
      ncol(tbl.gff3),
      gff3.filePath
    )
    flog.debug(lmsg)

    flog.debug(sprintf("exists? %s", file.exists(gff3.filePath)))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        filePath = file.path("tracks", basename(gff3.filePath)),
        color = color,
        colorTable = colorTable,
        colorByAttribute = colorByAttribute,
        displayMode = displayMode,
        trackHeight = trackHeight,
        visibilityWindow = visibilityWindow
      )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    session$sendCustomMessage("loadGFF3TrackFromLocalData", msg.to.igv)

  } # loadGFF3TrackFromLocalData
#-------------------------------------------------------------------------------

