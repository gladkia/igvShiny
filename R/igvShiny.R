# THE FOLLOWING WAS MOVED OUT OF doc section for igvShiny
# param options a list, with required elements "genomeName" and "initialLocus".
#   Local or remote custom genomes can be used by setting "genomeName" to
#   "local" or "remote". The necessary fasta and index files are provided via
#   "fasta" and "index" arguments, either as path on disk or as URL.

#-------------------------------------------------------------------------------
# A list of safe, known igv.js track configuration parameters.
# This allowlist prevents arbitrary code injection and invalid options.
#
# Every name here has to be one igv.js actually reads. A name it does not know
# is worse than a rejected one: it passes validation, reaches the browser, and
# is ignored there, so the user gets no warning from either side and a track
# drawn with defaults. test-track-option-allowlist.R holds the list to that,
# checking each name against the bundled igv.js build.
.validIgvTrackOptions <- c(
  "name", "type", "format", "url", "indexURL", "indexed", "order",
  "displayMode", "color", "altColor", "borderColor",
  "trait", "height", "autoHeight", "minHeight", "maxHeight", "removable",
  ## seg tracks read their two gradients from these; the shorter negColor and
  ## posColor, which look like the obvious spelling, are read by nothing
  "negColorScale", "posColorScale",
  ## only the lower-case s spelling is a track option. autoScaleGroup used to
  ## sit here next to it, which meant a capitalised typo passed validation and
  ## produced an ungrouped track with nothing said about it
  "autoscale", "autoscaleGroup",
  "visibilityWindow", "searchable", "autoScale",
  "min", "max", "logScale", "graphType",
  "flipAxis", "stroke", "fill", "featureHeight",
  "font", "colorTable",
  ## the gwas parser reads these 1-based; without them it guesses the layout
  ## from the header names it knows, and any other spelling draws nothing
  "columns",
  "showAllBases", "samplingWindowSize", "samplingDepth", "maxRows",
  "oauthToken", "headers", "viewAsPairs", "pairsSupported",
  "wholeGenomeView", "roi", "queryable",
  ## alignment tracks sort their reads at load time from this object, the same
  ## one the igv.js right-click menu builds; "TAG" plus a tag covers #104
  "sort",
  ## splice junction filters, thickness and label rules, read by
  ## SpliceJunctionTrack straight off the track config. Names come from the
  ## igv.js 3.8.4 source, not from its spliceJunctionTrack.html example: that
  ## example sets labelUniqueReadCount and four siblings, and no such option
  ## exists in the library any more
  "minUniquelyMappedReads", "minTotalReads", "maxFractionMultiMappedReads",
  "minSplicedAlignmentOverhang", "minJunctionEndsVisible",
  "minSamplesWithThisJunction", "maxSamplesWithThisJunction",
  "minPercentSamplesWithThisJunction", "maxPercentSamplesWithThisJunction",
  "thicknessBasedOn", "bounceHeightBasedOn", "colorBy",
  "colorByNumReadsThreshold", "labelWith", "labelWithInParen",
  "hideAnnotatedJunctions", "hideUnannotatedJunctions", "hideMotifs",
  "hideStrand",
  ## MergedTrack passes this one down to every member track it draws, which is
  ## what makes overlaid coverage readable under the junction arcs
  "alpha"
  # Add other valid igv.js track options here as needed in the future
  # "tracks" is deliberately absent: it is meaningful on a merged track only,
  # and .sanitizeTrack handles it there.
)

#-------------------------------------------------------------------------------
# A merged track may itself hold merged tracks - igv.js builds its members
# through the same factory as top-level tracks, and nothing there stops the
# recursion. One level is all that has a use (coverage under junction arcs);
# the cap only bounds a pathological config, it states no policy.
.maxTrackNestingDepth <- 3L

#-------------------------------------------------------------------------------
#' Sanitize and merge track configuration options
#' @param baseOptions A list of default options set by the R function.
#' @param userOptions A list of options provided by the user via trackConfig.
#' @return A merged and sanitized list of options ready to be sent to
#' JavaScript.
#' @keywords igvShiny
.sanitizeAndMergeOptions <- function(baseOptions, userOptions) {
  if (is.null(userOptions) || length(userOptions) == 0) {
    return(baseOptions)
  }

  # anyNA guards the NA-name case: without it, `any(names == "")` evaluates to
  # NA when a name is NA and the `if` errors instead of warning and ignoring.
  if (!is.list(userOptions) || is.null(names(userOptions)) ||
      anyNA(names(userOptions)) || any(names(userOptions) == "")) {
    warning("trackConfig must be a named list. Ignoring.")
    return(baseOptions)
  }

  # Identify and warn about conflicting keys that would override explicit
  # function arguments
  conflictingKeys <- intersect(names(baseOptions), names(userOptions))
  if (length(conflictingKeys) > 0) {
    fmt <- paste("User-provided trackConfig options conflict with function",
                 "arguments and will be ignored: %s")
    warning(sprintf(fmt, toString(conflictingKeys)))
    # Prioritize base options for security and clarity
    userOptions[conflictingKeys] <- NULL
  }

  # Filter user options against the allowlist of valid igv.js parameters
  invalidKeys <- setdiff(names(userOptions), .validIgvTrackOptions)
  if (length(invalidKeys) > 0) {
    fmt <- paste("Ignoring invalid or unsupported track options in",
                 "trackConfig: %s")
    warning(sprintf(fmt, toString(invalidKeys)))
    userOptions[invalidKeys] <- NULL
  }

  # Merge the sanitized user options with the base options
  return(c(baseOptions, userOptions))
}
#-------------------------------------------------------------------------------
#' Sanitize a list of startup track specifications
#' @param tracks A list of named lists, each an igv.js track configuration.
#' @param depth An integer, how deep this list sits in a merged track; 1 for
#' the startup list itself.
#' @return A sanitized list of track configurations; invalid entries or keys
#' are dropped with a warning.
#' @keywords igvShiny
.sanitizeTracks <- function(tracks, depth = 1L) {
  if (is.null(tracks) || length(tracks) == 0) {
    return(list())
  }

  sanitized <- Filter(Negate(is.null), lapply(tracks, .sanitizeTrack,
                                              depth = depth))
  # Names have to go: igv.js walks a merged track with `for (let tconf of
  # this.config.tracks)` and calls .every() on the same value, and a named R
  # list serializes to a JSON object, which is neither iterable nor an array.
  unname(sanitized)
}
#-------------------------------------------------------------------------------
#' Sanitize one startup track specification
#' @param track A named list, one igv.js track configuration.
#' @param depth An integer, how deep this track sits in a merged track.
#' @return The sanitized track, or NULL if it cannot be used.
#' @keywords igvShiny
.sanitizeTrack <- function(track, depth) {
  if (!is.list(track) || is.null(names(track)) || any(is.na(names(track))) ||
      any(names(track) == "")) {
    msg <- paste("Ignoring invalid entry in 'tracks': each entry must be",
                 "a named list.")
    warning(msg)
    return(NULL)
  }

  # igv.js dispatches on config.type.toLowerCase(), so "Merged" is a merged
  # track there and has to be one here too.
  type <- track[["type"]]
  merged <- is.character(type) && length(type) == 1L && !is.na(type) &&
    identical(tolower(type), "merged")

  # "tracks" is a key only a merged track may carry, so it is pulled out of
  # the allowlist pass rather than added to the allowlist: on any other track
  # it stays unsupported and is dropped with the usual warning.
  members <- NULL
  if (merged) {
    members <- track[["tracks"]]
    track[["tracks"]] <- NULL
  }

  invalidKeys <- setdiff(names(track), .validIgvTrackOptions)
  if (length(invalidKeys) > 0) {
    fmt <- paste("Ignoring invalid or unsupported track options in",
                 "'tracks': %s")
    warning(sprintf(fmt, toString(invalidKeys)))
    track[invalidKeys] <- NULL
  }

  if (merged) {
    if (depth >= .maxTrackNestingDepth) {
      fmt <- paste("Dropping merged track nested more than %d levels deep in",
                   "'tracks'.")
      warning(sprintf(fmt, .maxTrackNestingDepth))
      return(NULL)
    }
    # Members go through this same allowlist, so a merged track widens no
    # boundary; it only relaxes where the url has to sit.
    members <- .sanitizeTracks(members, depth = depth + 1L)
    if (length(members) == 0) {
      msg <- paste("Dropping merged track in 'tracks' with no usable member",
                   "track.")
      warning(msg)
      return(NULL)
    }
    track[["tracks"]] <- members
    return(track)
  }

  # A usable url is a single non-empty, non-NA character string. is.null()
  # alone let NA, "", character(0) and non-character values through to
  # igv.js as broken tracks.
  url <- track[["url"]]
  if (!is.character(url) || length(url) != 1L || is.na(url) ||
      !nzchar(url)) {
    msg <- paste("Dropping entry in 'tracks' with no valid 'url' after",
                 "removing unsupported options.")
    warning(msg)
    return(NULL)
  }
  track
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
#' @param tracks a list of track specifications to be created and displayed
#' at startup. Each element is itself a named list of igv.js track options
#' (e.g. \code{name}, \code{type}, \code{format}, \code{url}), for example:
#' \code{list(list(name="genes", type="annotation", format="gff3",
#' url="https://.../genes.gff3"))}. Unrecognized keys are dropped with a
#' warning; see \code{.validIgvTrackOptions} for the full allowlist.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
    directory.name <- .tracksDir()
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
  # outside a shiny session (script, vignette) there is no namespace to
  # prepend; the JS side concatenates moduleNS with the event name, so the
  # no-module case is the empty string
  genomeOptions$moduleNS <- if (is.null(session)) "" else session$ns("")
  genomeOptions$tracks <- .sanitizeTracks(tracks)

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
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
#' @param trackConfig a named list of additional igv.js track configuration
#' options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
        randomColors[sample(seq_along(randomColors), 1)]

    if (!quiet) {
      flog.debug("--- igvShiny::loadBedTrack")

      flog.debug(sprintf("rows: %d  cols: %d", NROW(tbl), NCOL(tbl)))
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
      .trackFile(session, ".bed")
    write.table(
      tbl,
      sep = "\t",
      row.names = FALSE,
      col.names = FALSE,
      quote = FALSE,
      file = temp.file
    )
    lmsg <- sprintf("--- igvShiny.R, loadBedTrack wrote %d,%d to %s",
                    NROW(tbl),
                    NCOL(tbl),
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
#' @param trackConfig a named list of additional igv.js track configuration
#' options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
        randomColors[sample(seq_along(randomColors), 1)]

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
#' @param trackConfig a named list of additional igv.js track configuration
#' options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
    stopifnot(NCOL(tbl) >= 4)

    if (color == "random")
      color <-
        randomColors[sample(seq_along(randomColors), 1)]

    if (!quiet) {
      flog.debug("--- igvShiny::loadGenomeAnnotationTrack: %s",
                 trackName)
      flog.debug("    %d rows, %d columns", NROW(tbl), NCOL(tbl))
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
                 toString(colnames(tbl)[c(1, 2, 3)]))
      flog.debug("            required: %s",
                 toString(c("chr", "start", "end")))
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
#' @param trackConfig a named list of additional igv.js track configuration
#' options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
               NROW(tbl))

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
#' @param trackConfig a named list of additional igv.js track configuration
#' options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "local-data.R")
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
  temp.file <- .trackFile(session, ".vcf")
  lmsg <- sprintf("igvShiny::loadVcfTrack, about to write to file '%s'",
                  temp.file)
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
#' @param trackConfig a named list of additional igv.js track configuration
#' options. A table whose headers igv.js does not recognize needs its layout
#' spelled out, 1-based, as
#' \code{columns = list(chromosome = 3, position = 4, value = 10)};
#' \code{colorTable} takes a chromosome-to-color map, see
#' \code{\link{GWASTrack}}
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
    .trackFile(session, ".gwas")
  write.table(
    tbl.gwas,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    file = temp.file
  )
  lmsg <- sprintf(
    "--- igvShiny.R, loadGwasTrack wrote %d,%d to %s",
    NROW(tbl.gwas),
    NCOL(tbl.gwas),
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
#' @param trackConfig a named list of additional igv.js track configuration
#' options. Alignment tracks read \code{sort}: \code{list(sort =
#' list(chr = "chr1", position = 155160540, option = "TAG", tag = "HP"))}
#' sorts the reads at that 1-based position by the HP tag. Any igv.js sort
#' option works (BASE, STRAND, INSERT_SIZE, ...); reads sort descending
#' unless \code{direction = "ASC"}.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
#' @param trackConfig a named list of additional igv.js track configuration
#' options, \code{sort} among them; see \code{\link{loadBamTrackFromURL}}.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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

    fpath <- .trackFile(session, ".bam")
    # rtracklayer indexes the bam it writes, next to it and under a name we
    # never see; it is served alongside, so it goes at session end too
    .registerTrackFile(session, paste0(fpath, ".bai"))

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
#' @param trackConfig a named list of additional igv.js track configuration
#' options, \code{sort} among them; see \code{\link{loadBamTrackFromURL}}.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
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
#' load a cram file sitting on the same machine as the shiny app
#'
#' @description load a local cram track. Unlike \code{loadBamTrackFromLocalData}
#' this loader takes file paths, not an R object: no bioconductor package parses
#' cram, so the file and its index are handed to igv.js untouched, through the
#' directory shiny serves as "tracks".
#'
#' @rdname loadCramTrackFromLocalData
#' @aliases loadCramTrackFromLocalData
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param cramFile character string, path to a cram file
#' @param indexFile character string, path to its crai index,
#' by default the cram file with ".crai" appended
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration
#' options, \code{sort} among them; see \code{\link{loadBamTrackFromURL}}.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadCramTrackFromLocalData <-
  function(session,
           id,
           trackName,
           cramFile,
           indexFile = paste0(cramFile, ".crai"),
           deleteTracksOfSameName = TRUE,
           trackConfig = list()) {
    checkmate::assert_file_exists(cramFile, access = "r")
    checkmate::assert_file_exists(indexFile, access = "r")
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    cramPath <- .stageTrackFile(session, cramFile, ".cram")
    indexPath <- .stageTrackFile(session, indexFile, ".crai")
    flog.debug(sprintf("igvShiny::load local cram, serving '%s'", cramPath))

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        cram = cramPath,
        index = indexPath
      )
    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    # the payload is what the remote loader sends, only with app-relative urls,
    # so the browser side needs no handler of its own
    session$sendCustomMessage("loadCramTrackFromURL", msg.to.igv)

  } # loadCramTrackFromLocalData

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
#' @param trackConfig a named list of additional igv.js track configuration
#' options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "local-data.R")
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
#' @param trackConfig a named list of additional igv.js track configuration
#' options.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "demos", "local-data.R")
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
      .trackFile(session, ".gff3")
    write.table(
      tbl.gff3,
      sep = "\t",
      row.names = FALSE,
      quote = FALSE,
      file = gff3.filePath
    )
    lmsg <- sprintf(
      "--- igvShiny.R, loadGFF3TrackFromLocalData wrote %d,%d to %s",
      NROW(tbl.gff3),
      NCOL(tbl.gff3),
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
#' load a splice junction track served up by http
#'
#' @description load splice junctions from a BED file reachable by URL, as
#' written by STAR (\code{SJ.out.tab} converted to BED). Six columns, with the
#' per-junction attributes packed into the name column as \code{key=value}
#' pairs separated by semicolons: \code{motif}, \code{uniquely_mapped},
#' \code{multi_mapped}, \code{maximum_spliced_alignment_overhang} and
#' \code{annotated_junction}. The track reads its filters and labels from
#' those attributes.
#'
#' igv.js draws junctions from a file of that shape only - it derives none of
#' them from a bam file, and it has no sashimi plot. Show this track above a
#' coverage track (bigWig, bedGraph) for the same sample to get the
#' arcs-over-coverage view sashimi plots are wanted for.
#'
#' @rdname loadSpliceJunctionTrackFromURL
#' @aliases loadSpliceJunctionTrackFromURL
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param url character string http url for the bed file of junctions
#' @param indexURL character string http url for a tabix index, needed only
#' for a bgzipped bed; "" by default, which loads the file whole
#' @param trackHeight an integer, 100 (pixels) by default
#' @param displayMode character, "COLLAPSED", "EXPANDED" or "SQUISHED"
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration
#' options. The junction ones are read straight off it:
#' \code{minUniquelyMappedReads}, \code{minTotalReads},
#' \code{maxFractionMultiMappedReads}, \code{minSplicedAlignmentOverhang},
#' \code{thicknessBasedOn}, \code{bounceHeightBasedOn}, \code{colorBy},
#' \code{labelWith}, \code{hideAnnotatedJunctions},
#' \code{hideUnannotatedJunctions}, \code{hideMotifs} among them.
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadSpliceJunctionTrackFromURL <-
  function(session,
           id,
           trackName,
           url,
           indexURL = "",
           trackHeight = 100,
           displayMode = "COLLAPSED",
           deleteTracksOfSameName = TRUE,
           trackConfig = list()) {
    # A usable index is a single non-empty, non-NA character string; anything
    # else means "no index". NULL is the trap: list() keeps it, shiny sends it
    # as JSON null, and the handler reads .length off it. That throws, so the
    # track never loads and R sees nothing at all - the failure shows up only
    # in the browser console.
    if (!is.character(indexURL) || length(indexURL) != 1L || is.na(indexURL)) {
      if (length(indexURL) > 0L) {
        warning("indexURL must be a single character string. Ignoring it.")
      }
      indexURL <- ""
    }

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        url = url,
        indexURL = indexURL,
        trackHeight = trackHeight,
        displayMode = displayMode
      )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    session$sendCustomMessage("loadSpliceJunctionTrackFromURL", msg.to.igv)

  } # loadSpliceJunctionTrackFromURL
#-------------------------------------------------------------------------------
# The per-junction attributes SpliceJunctionTrack reads off the bed name
# column, in the spelling igv.js looks for.
.junctionAttributeColumns <-
  c("motif", "uniquely_mapped", "multi_mapped",
    "maximum_spliced_alignment_overhang", "annotated_junction")

#' Pack junction attributes into a bed name column
#' @param tbl A data.frame of junctions.
#' @return A character vector, one packed name field per row.
#' @keywords igvShiny
.packJunctionAttributes <- function(tbl) {
  columns <- intersect(.junctionAttributeColumns, colnames(tbl))
  if (length(columns) == 0) {
    return(rep(".", NROW(tbl)))
  }

  asAttribute <- function(values) {
    # igv.js compares annotated_junction against the strings "true" and
    # "false", and R would write a logical column as TRUE/FALSE, which matches
    # neither: the junction would be neither annotated nor unannotated and
    # both hide options would pass it through.
    if (is.logical(values)) {
      return(tolower(as.character(values)))
    }
    as.character(values)
  }

  packed <- lapply(columns, function(column) {
    paste0(column, "=", asAttribute(tbl[[column]]))
  })
  packed <- do.call(paste, c(packed, list(sep = ";")))

  # The bed decoder reads column 4 as attributes only when it holds a "=" and
  # a ";" past its first character. A single pair carries no ";", so it would
  # arrive as a plain track label and every junction filter would quietly find
  # nothing to read. A trailing ";" is dropped by the parser, so it costs
  # nothing and keeps one attribute working like five.
  if (length(columns) == 1L) {
    packed <- paste0(packed, ";")
  }
  packed
} # .packJunctionAttributes
#-------------------------------------------------------------------------------
#' load a splice junction track from a data.frame
#'
#' @description load splice junctions held in R. The table is written as the
#' six-column bed igv.js draws junctions from, and served from the same
#' directory as the other local-data tracks.
#'
#' Coordinates are taken as bed coordinates and written out unchanged, as the
#' other \code{*FromLocalData} loaders take theirs. STAR reports the first and
#' last intron base of a junction 1-based in \code{SJ.out.tab}, so a table read
#' straight from that file needs its start shifted by one first; a bed already
#' converted from it, which is what STAR wrappers and the igv.js test fixtures
#' ship, is passed in as is.
#'
#' Columns \code{chrom} (or \code{chr}), \code{start} and \code{end} are
#' required. \code{score} and \code{strand} are used when present. The
#' per-junction attributes \code{motif}, \code{uniquely_mapped},
#' \code{multi_mapped}, \code{maximum_spliced_alignment_overhang} and
#' \code{annotated_junction} are packed into the bed name column, which is
#' where the track reads its filters and labels from; supply the ones you
#' want to filter or label on. A \code{name} column, if you have already
#' packed it yourself, is written through untouched.
#'
#' Without \code{uniquely_mapped} or an explicit \code{score} the arcs all
#' draw at the same thickness: igv.js has nothing to size them by.
#'
#' @rdname loadSpliceJunctionTrackFromLocalData
#' @aliases loadSpliceJunctionTrackFromLocalData
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" "start" "end" columns, in bed
#' coordinates: a 0-based start and an exclusive end
#' @param trackHeight an integer, 100 (pixels) by default
#' @param displayMode character, "COLLAPSED", "EXPANDED" or "SQUISHED"
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration
#' options, the junction ones among them; see
#' \code{\link{loadSpliceJunctionTrackFromURL}}
#'
#' @examples
#' library(igvShiny)
#' demo_app_file <-
#'   system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
#' if (interactive()) {
#'   shiny::runApp(demo_app_file)
#' }
#'
#' @return
#' nothing
#'
#' @keywords track_loaders
#' @export

loadSpliceJunctionTrackFromLocalData <-
  function(session,
           id,
           trackName,
           tbl,
           trackHeight = 100,
           displayMode = "COLLAPSED",
           deleteTracksOfSameName = TRUE,
           trackConfig = list()) {
    stopifnot(is.data.frame(tbl))

    if ("chrom" %in% colnames(tbl)) {
      colnames(tbl)[colnames(tbl) == "chrom"] <- "chr"
    }
    missingColumns <- setdiff(c("chr", "start", "end"), colnames(tbl))
    if (length(missingColumns) > 0) {
      fmt <- "improper columns in splice junction data.frame, missing: %s"
      stop(sprintf(fmt, toString(missingColumns)))
    }
    stopifnot(is(tbl$chr, "character"))
    stopifnot(is(tbl$start, "numeric"))
    stopifnot(is(tbl$end, "numeric"))

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    name <- if ("name" %in% colnames(tbl)) {
      as.character(tbl$name)
    } else {
      .packJunctionAttributes(tbl)
    }
    # igv.js reads the bed score as the uniquely mapped spanning read count and
    # sizes the arcs by it, so a uniquely_mapped column stands in for a score
    # column when the caller gives one and not the other. 1000 is the score the
    # bed decoder itself falls back to.
    score <- if ("score" %in% colnames(tbl)) {
      tbl$score
    } else if ("uniquely_mapped" %in% colnames(tbl)) {
      tbl$uniquely_mapped
    } else {
      1000
    }
    strand <- if ("strand" %in% colnames(tbl)) as.character(tbl$strand) else "."

    tbl.bed <- data.frame(
      chr = tbl$chr,
      start = tbl$start,
      end = tbl$end,
      name = name,
      score = score,
      strand = strand,
      stringsAsFactors = FALSE
    )

    bed.filePath <- .trackFile(session, ".bed")
    write.table(
      tbl.bed,
      file = bed.filePath,
      sep = "\t",
      quote = FALSE,
      row.names = FALSE,
      col.names = FALSE
    )
    lmsg <- sprintf(
      "--- igvShiny.R, loadSpliceJunctionTrackFromLocalData wrote %d to %s",
      NROW(tbl.bed), bed.filePath
    )
    flog.debug(lmsg)

    base.msg.to.igv <-
      list(
        elementID = id,
        trackName = trackName,
        url = file.path("tracks", basename(bed.filePath)),
        indexURL = "",
        trackHeight = trackHeight,
        displayMode = displayMode
      )

    msg.to.igv <- .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig)
    # The url handler takes it from here: an unindexed bed served by shiny is
    # the same job as an unindexed bed served by anyone else.
    session$sendCustomMessage("loadSpliceJunctionTrackFromURL", msg.to.igv)

  } # loadSpliceJunctionTrackFromLocalData
#-------------------------------------------------------------------------------
