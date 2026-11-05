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
  "alpha",
  ## alignment track sizing, coverage display and read row heights
  "coverageTrackHeight", "showCoverage", "showAlignments",
  "alignmentRowHeight", "squishedRowHeight",
  ## annotation track row height in EXPANDED mode, sent by loadTrack
  "expandedRowHeight"
  # Add other valid igv.js track options here as needed in the future
  # "tracks" is deliberately absent: it is meaningful on a merged track only,
  # and .sanitizeTrack handles it there.
)

# Genotype colors only a variant track reads. They are kept out of the global
# allowlist so that bed, bedGraph, ... loaders still warn and drop them; the
# vcf builder, VariantTrack and a "variant" config list or startup track add
# them through the `allowed` argument of .sanitizeAndMergeOptions.
.variantTrackOptions <- c("homvarColor", "hetvarColor", "homrefColor")

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
#' @param allowed character, the option names igv.js reads for this kind of
#' track; defaults to the global allowlist
#' @return A merged and sanitized list of options ready to be sent to
#' JavaScript.
#' @keywords igvShiny
.sanitizeAndMergeOptions <- function(baseOptions, userOptions,
                                     allowed = .validIgvTrackOptions) {
  checkmate::assert_character(allowed, any.missing = FALSE)
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

  # Map trackHeight alias to height for consistency with loader arguments
  if ("trackHeight" %in% names(userOptions)) {
    if (!("height" %in% names(userOptions)) &&
        !("height" %in% names(baseOptions))) {
      checkmate::assert_number(
        userOptions[["trackHeight"]],
        lower = 1,
        finite = TRUE
      )
      userOptions[["height"]] <- userOptions[["trackHeight"]]
    }
    userOptions[["trackHeight"]] <- NULL
  }

  # Filter user options against the allowlist of valid igv.js parameters
  invalidKeys <- setdiff(names(userOptions), allowed)
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

  # Normalise 'index' alias to 'indexURL'
  if ("index" %in% names(track) && !"indexURL" %in% names(track)) {
    track[["indexURL"]] <- track[["index"]]
    track[["index"]] <- NULL
  }

  allowed <- .validIgvTrackOptions
  if (is.character(type) && length(type) == 1L && !is.na(type) &&
      identical(tolower(type), "variant"))
    allowed <- c(allowed, .variantTrackOptions)
  invalidKeys <- setdiff(names(track), allowed)
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

  # the reference check reads fastaIndex off disk, and the block below rewrites
  # it to a served path, so the spec has to be registered before that happens
  session <- shiny::getDefaultReactiveDomain()
  .registerGenomeSpec(session, elementId, genomeOptions)

  if (!genomeOptions[["stockGenome"]] &&
        genomeOptions[["dataMode"]] == "localFiles") {
    directory.name <- .tracksDir()
    fasta.file <- genomeOptions[["fasta"]]
    fasta.indexFile <- genomeOptions[["fastaIndex"]]
    gff3.file <- genomeOptions[["annotation"]]
    # igv.js reads an indexed fasta by Range requests only; the "tracks"
    # resource path ignores Range and answers with the whole file, which
    # never finishes for a multi-GB genome behind a remote server (#183)
    if (!is.null(session)) {
      genomeOptions[["fasta"]] <- serveLocalFile(session, fasta.file)
      genomeOptions[["fastaIndex"]] <- serveLocalFile(session, fasta.indexFile)
    } else {
      file.copy(fasta.file, file.path(directory.name, basename(fasta.file)),
                overwrite = TRUE)
      file.copy(fasta.indexFile,
                file.path(directory.name, basename(fasta.indexFile)),
                overwrite = TRUE)
      genomeOptions[["fasta"]] <-
        file.path(basename(directory.name), basename(fasta.file))
      genomeOptions[["fastaIndex"]] <-
        file.path(basename(directory.name), basename(fasta.indexFile))
    }
    # the annotation is fetched whole, so it stays on the static path, which
    # streams from disk instead of reading the file into R memory
    if (!is.na(gff3.file)) {
      destination <- file.path(directory.name, basename(gff3.file))
      file.copy(gff3.file, destination, overwrite = TRUE)
      genomeOptions[["annotation"]] <-
        file.path(basename(directory.name), basename(gff3.file))
    }
  } # if custom genome, local files

  state[["requestedHeight"]] <- height

  flog.debug("---igvShiny ctor")
  flog.debug(sprintf("--initial track count: %d", length(tracks)))

  #send namespace info in case widget is being called from a module
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
#' @param validateReference logical flag, default TRUE: checks track contigs
#' and coordinates against the active reference genome and emits warnings/toasts
#' on mismatch.
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
           trackConfig = list(),
           validateReference = TRUE) {
    if (!quiet) {
      flog.debug("--- igvShiny::loadBedTrack")

      flog.debug(sprintf("rows: %d  cols: %d", NROW(tbl), NCOL(tbl)))
    }

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    tbl <- .normalizeBedColumns(tbl)

    .validateTrackReference(session, id, trackName, tbl,
                            validateReference = validateReference)

    payload <- .bedTrackPayload(trackName, tbl,
                                path = .trackFile(session, ".bed"),
                                color = color,
                                trackHeight = trackHeight,
                                trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadBedTrackFromFile", msg.to.igv)

  } # loadBedTrack

#-------------------------------------------------------------------------------
#' Give a bed-like data.frame the chr/start/end column names loaders expect
#'
#' @description Renames a leading "chrom" column to "chr" and fails when the
#' first three columns are not chr, start and end.
#'
#' @param tbl data.frame, with at least "chrom" (or "chr") "start" "end" columns
#'
#' @return the data.frame, its first column possibly renamed
#'
#' @keywords internal
.normalizeBedColumns <- function(tbl) {
  checkmate::assert_class(tbl, "data.frame")
  checkmate::assert_true(NCOL(tbl) >= 3L)

  if (colnames(tbl)[1] == "chrom")
    colnames(tbl)[1] <- "chr"

  if (all(colnames(tbl)[c(1, 2, 3)] != c("chr", "start", "end"))) {
    flog.debug("found these colnames: %s", toString(colnames(tbl)))
    flog.debug("            required: %s", toString(c("chr", "start", "end")))
    stop("improper columns in bed track data.frame")
  }

  tbl
} # .normalizeBedColumns

#-------------------------------------------------------------------------------
#' Build the payload of a bed track from a data.frame
#'
#' @description The browser-free half of \code{loadBedTrack}: checks and sorts
#' the table, writes it to \code{path} as headerless bed, and returns the
#' message body the \code{loadBedTrackFromFile} handler in igvShiny.js reads.
#' It touches no session; the caller picks the path (in a sender, with
#' \code{.trackFile()}) and adds the element id.
#'
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" (or "chr") "start" "end" columns
#' @param path character string, the file to write; its basename is what the
#' browser fetches from the \code{tracks/} resource path
#' @param color character string, a legal CSS color, or "random"
#' @param trackHeight an integer, 50 (pixels) by default
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the paths written (here: \code{path})
#'
#' @keywords internal
.bedTrackPayload <- function(trackName,
                             tbl,
                             path,
                             color = "",
                             trackHeight = 50,
                             trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(path)
  checkmate::assert_string(color)

  if (color == "random")
    color <- randomColors[sample(seq_along(randomColors), 1)]

  tbl <- .normalizeBedColumns(tbl)

  stopifnot(is(tbl$chr, "character"))
  stopifnot(is(tbl$start, "numeric"))
  stopifnot(is(tbl$end, "numeric"))
  new.order <- order(tbl$start, decreasing = FALSE)
  tbl <- tbl[new.order, ]

  write.table(
    tbl,
    sep = "\t",
    row.names = FALSE,
    col.names = FALSE,
    quote = FALSE,
    file = path
  )
  flog.debug("--- igvShiny.R, .bedTrackPayload wrote %d,%d to %s",
             NROW(tbl), NCOL(tbl), path)

  config <- list(
    trackName = trackName,
    bedFilepath = file.path("tracks", basename(path)),
    color = color,
    trackHeight = trackHeight
  )

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = path)
} # .bedTrackPayload

#-------------------------------------------------------------------------------
#' Build the payload of a bedpe interaction track from a data.frame
#'
#' @description The browser-free builder of \code{BedpeInteractionsTrack}:
#' sorts the table by chrom1 and start1, writes it to \code{path} as
#' headerless bedpe, and returns the message body the
#' \code{loadBedpeTrackFromFile} handler in igvShiny.js reads. It has no
#' exported data.frame loader; \code{loadTrack()} is its sender.
#'
#' @param trackName character string
#' @param tbl data.frame, bedpe: chrom1, start1, end1, chrom2, start2, end2,
#' then optional columns
#' @param path character string, the file to write; its basename is what the
#' browser fetches from the \code{tracks/} resource path
#' @param color character string, a legal CSS color, or "random"
#' @param trackHeight numeric, pixels
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the paths written (here: \code{path})
#'
#' @keywords internal
.bedpeTrackPayload <- function(trackName,
                               tbl,
                               path,
                               color = "darkBlue",
                               trackHeight = 50,
                               trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_class(tbl, "data.frame")
  checkmate::assert_true(NCOL(tbl) >= 6L)
  checkmate::assert_string(path)
  checkmate::assert_string(color)
  checkmate::assert_number(trackHeight, lower = 1)

  if (color == "random")
    color <- randomColors[sample(seq_along(randomColors), 1)]

  tbl <- tbl[order(tbl[[1]], tbl[[2]]), , drop = FALSE]
  write.table(
    tbl,
    sep = "\t",
    row.names = FALSE,
    col.names = FALSE,
    quote = FALSE,
    file = path
  )
  flog.debug("--- igvShiny.R, .bedpeTrackPayload wrote %d,%d to %s",
             NROW(tbl), NCOL(tbl), path)

  config <- list(
    trackName = trackName,
    bedpeFilepath = file.path("tracks", basename(path)),
    color = color,
    trackHeight = trackHeight
  )

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = path)
} # .bedpeTrackPayload

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

    payload <- .bedGraphUrlTrackPayload(trackName, url,
                                        color = color,
                                        trackHeight = trackHeight,
                                        autoscale = autoscale,
                                        min = min,
                                        max = max,
                                        autoscaleGroup = autoscaleGroup,
                                        trackConfig = trackConfig)
    msg.to.igv <- c(list(elementID = id), payload$config)

    flog.debug("--- igvShiny.R loadBedGraphTrackFromURL, msg.to.igv: ")
    futile.logger::flog.info(jsonlite::toJSON(msg.to.igv))
    flog.debug("--- igvShiny.R loadBedGraphTrackFromURL, sendingCustomMessage")
    session$sendCustomMessage("loadBedGraphTrackFromURL", msg.to.igv)
    flog.debug("--- loadBedGraphTrackFromURL, after sendingCustomMessage")

  } # loadBedGraphTrackFromURL

#-------------------------------------------------------------------------------
#' Build the payload of a quantitative track read from a URL
#'
#' @description The browser-free half of \code{loadBedGraphTrackFromURL}:
#' returns the message body the \code{loadBedGraphTrackFromURL} handler in
#' igvShiny.js reads. Nothing is written, so \code{files} is empty.
#'
#' @param trackName character string
#' @param url character string, a bedGraph, wig or bigwig URL
#' @param color character string, a legal CSS color, or "random"
#' @param trackHeight an integer, 30 (pixels) by default
#' @param autoscale logical
#' @param min numeric, consulted when autoscale is FALSE
#' @param max numeric, consulted when autoscale is FALSE
#' @param autoscaleGroup numeric(1), -1 (no group) by default
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, \code{character(0)}
#'
#' @keywords internal
.bedGraphUrlTrackPayload <- function(trackName,
                                     url,
                                     color = "gray",
                                     trackHeight = 30,
                                     autoscale = TRUE,
                                     min = 0,
                                     max = 1,
                                     autoscaleGroup = -1,
                                     trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(url)
  checkmate::assert_string(color)

  if (color == "random")
    color <- randomColors[sample(seq_along(randomColors), 1)]

  config <- list(
    trackName = trackName,
    url = url,
    color = color,
    trackHeight = trackHeight,
    autoscale = autoscale,
    min = min,
    max = max,
    autoscaleGroup = autoscaleGroup
  )

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = character(0))
} # .bedGraphUrlTrackPayload

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
#' @param validateReference logical flag, default TRUE: checks track contigs
#' and coordinates against the active reference genome and emits warnings/toasts
#' on mismatch.
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
           trackConfig = list(),
           validateReference = TRUE) {
    stopifnot(NCOL(tbl) >= 4)

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

    tbl <- .normalizeBedGraphColumns(tbl)

    .validateTrackReference(session, id, trackName, tbl,
                            validateReference = validateReference)

    payload <- .bedGraphTrackPayload(trackName, tbl,
                                     color = color,
                                     trackHeight = trackHeight,
                                     autoscale = autoscale,
                                     autoscaleGroup = autoscaleGroup,
                                     min = min,
                                     max = max,
                                     trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadBedGraphTrack", msg.to.igv)

  } # loadBedGraphTrack

#-------------------------------------------------------------------------------
#' Give a bedGraph-like data.frame the chr/start/end/value column names
#'
#' @description Renames a leading "chrom" column to "chr" and the fourth column
#' to "value", then applies the chr/start/end check of
#' \code{.normalizeBedColumns}.
#'
#' @param tbl data.frame, with at least four columns: chrom (or chr), start,
#' end and a numeric score
#'
#' @return the data.frame, with its columns renamed
#'
#' @keywords internal
.normalizeBedGraphColumns <- function(tbl) {
  checkmate::assert_class(tbl, "data.frame")
  checkmate::assert_true(NCOL(tbl) >= 4L)

  if (colnames(tbl)[1] == "chrom")
    colnames(tbl)[1] <- "chr"

  colnames(tbl)[4] <- "value"

  .normalizeBedColumns(tbl)
} # .normalizeBedGraphColumns

#-------------------------------------------------------------------------------
#' Build the payload of a bedGraph track from a data.frame
#'
#' @description The browser-free half of \code{loadBedGraphTrack}: checks and
#' sorts the table and returns the message body the \code{loadBedGraphTrack}
#' handler in igvShiny.js reads. The features travel inline as JSON, so
#' \code{files} is empty.
#'
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" "start" "end" "score" columns
#' @param color character string, a legal CSS color, or "random"
#' @param trackHeight an integer, 30 (pixels) by default
#' @param autoscale logical
#' @param autoscaleGroup numeric(1), -1 (no group) by default
#' @param min numeric, consulted when autoscale is FALSE
#' @param max numeric, consulted when autoscale is FALSE
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, \code{character(0)}
#'
#' @keywords internal
.bedGraphTrackPayload <- function(trackName,
                                  tbl,
                                  color = "gray",
                                  trackHeight = 30,
                                  autoscale,
                                  autoscaleGroup = -1,
                                  min = NA_real_,
                                  max = NA_real_,
                                  trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(color)

  if (color == "random")
    color <- randomColors[sample(seq_along(randomColors), 1)]

  tbl <- .normalizeBedGraphColumns(tbl)

  stopifnot(is(tbl$chr, "character"))
  stopifnot(is(tbl$start, "numeric"))
  stopifnot(is(tbl$end, "numeric"))
  stopifnot(is(tbl$value, "numeric"))

  new.order <- order(tbl$start, decreasing = FALSE)
  tbl <- tbl[new.order, ]

  config <- list(
    trackName = trackName,
    tbl = jsonlite::toJSON(tbl),
    color = color,
    trackHeight = trackHeight,
    autoscale = autoscale,
    min = min,
    max = max,
    autoscaleGroup = autoscaleGroup
  )  # -1 means no grouping

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = character(0))
} # .bedGraphTrackPayload
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

    # built before anything is sent: bad input removes no track
    payload <- .segTrackPayload(trackName, tbl, trackConfig = trackConfig)

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    msg.to.igv <- c(list(elementID = id), payload$config)
    flog.debug("about to send loadSegTrack message")
    session$sendCustomMessage("loadSegTrack", msg.to.igv)

  } # loadSegTrack

#-------------------------------------------------------------------------------
#' Build the payload of a seg track from a data.frame
#'
#' @description The browser-free half of \code{loadSegTrack}: returns the
#' message body the \code{loadSegTrack} handler in igvShiny.js reads. The
#' segments travel inline as JSON, so \code{files} is empty.
#'
#' @param trackName character string
#' @param tbl data.frame of segments, written through as is
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, \code{character(0)}
#'
#' @keywords internal
.segTrackPayload <- function(trackName, tbl, trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_class(tbl, "data.frame")

  config <- list(
    trackName = trackName,
    tbl = jsonlite::toJSON(tbl)
  )

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = character(0))
} # .segTrackPayload

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
#' @param validateReference logical flag, default TRUE: checks track contigs
#' against the active reference genome and emits warnings/toasts on mismatch.
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
                         trackConfig = list(),
                         validateReference = TRUE) {
  if (!requireNamespace("VariantAnnotation"))
    stop("install VariantAnnotation to use this function")

  .validateTrackReference(session, id, trackName, vcfData,
                          validateReference = validateReference)

  flog.debug("======== igvShiny.R, loadVcfTrack")
  if (deleteTracksOfSameName) {
    removeTracksByName(session, id, trackName)
  }

  state[["userAddedTracks"]] <-
    unique(c(state[["userAddedTracks"]], trackName))
  payload <- .vcfTrackPayload(trackName, vcfData,
                              path = .trackFile(session, ".vcf"),
                              trackConfig = trackConfig)

  msg.to.igv <- c(list(elementID = id), payload$config)
  session$sendCustomMessage("loadVcfTrack", msg.to.igv)

} # loadVcfTrack

#-------------------------------------------------------------------------------
#' Build the payload of a VCF track from a VariantAnnotation object
#'
#' @description The browser-free half of \code{loadVcfTrack}: writes
#' \code{vcfData} to \code{path} with \code{VariantAnnotation::writeVcf} and
#' returns the message body the \code{loadVcfTrack} handler in igvShiny.js
#' reads. Needs VariantAnnotation (Suggests).
#'
#' @param trackName character string
#' @param vcfData a \code{VCF} object from VariantAnnotation
#' @param path character string, the file to write; its basename is what the
#' browser fetches from the \code{tracks/} resource path
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the paths written (here: \code{path})
#'
#' @keywords internal
.vcfTrackPayload <- function(trackName, vcfData, path, trackConfig = list()) {
  if (!requireNamespace("VariantAnnotation", quietly = TRUE))
    stop("install VariantAnnotation to use this function")
  checkmate::assert_string(trackName)
  checkmate::assert_class(vcfData, "VCF")
  checkmate::assert_string(path)

  flog.debug("igvShiny::.vcfTrackPayload, about to write to file '%s'", path)
  VariantAnnotation::writeVcf(vcfData, path)
  flog.debug("igvShiny::.vcfTrackPayload, file.exists(%s)? %s",
             path, file.exists(path))

  config <- list(
    trackName = trackName,
    vcfDataFilepath = file.path("tracks", basename(path))
  )

  allowed <- c(.validIgvTrackOptions, .variantTrackOptions)
  list(config = .sanitizeAndMergeOptions(config, trackConfig,
                                         allowed = allowed),
       files = path)
} # .vcfTrackPayload

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

  # built before anything is sent: bad input removes no track
  payload <- .gwasTrackPayload(trackName, tbl.gwas,
                               path = .trackFile(session, ".gwas"),
                               ymin = ymin,
                               ymax = ymax,
                               trackConfig = trackConfig)

  if (deleteTracksOfSameName) {
    removeTracksByName(session, id, trackName)
  }

  state[["userAddedTracks"]] <-
    unique(c(state[["userAddedTracks"]], trackName))

  msg.to.igv <- c(list(elementID = id), payload$config)
  session$sendCustomMessage("loadGwasTrack", msg.to.igv)

} # loadGwasTrack

#-------------------------------------------------------------------------------
#' Build the payload of a GWAS track from a data.frame
#'
#' @description The browser-free half of \code{loadGwasTrack}: writes the table
#' with its header to \code{path} and returns the message body the
#' \code{loadGwasTrack} handler in igvShiny.js reads.
#'
#' @param trackName character string
#' @param tbl.gwas data.frame, the GWAS table
#' @param path character string, the file to write; its basename is what the
#' browser fetches from the \code{tracks/} resource path
#' @param ymin numeric defaults to 0
#' @param ymax numeric defaults to 35
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the paths written (here: \code{path})
#'
#' @keywords internal
.gwasTrackPayload <- function(trackName,
                              tbl.gwas,
                              path,
                              ymin = 0,
                              ymax = 35,
                              trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_class(tbl.gwas, "data.frame")
  checkmate::assert_string(path)

  write.table(
    tbl.gwas,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    file = path
  )
  flog.debug("--- igvShiny.R, .gwasTrackPayload wrote %d,%d to %s",
             NROW(tbl.gwas), NCOL(tbl.gwas), path)

  config <- list(
    trackName = trackName,
    gwasDataFilepath = file.path("tracks", basename(path)),
    color = "red",
    trackHeight = 200,
    autoscale = FALSE,
    min = ymin,
    max = ymax
  )

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = path)
} # .gwasTrackPayload

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
#' @param trackHeight numeric, track height in pixels (default: NULL, igv.js defaults to 300)
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
           trackConfig = list(),
           trackHeight = NULL) {
    if (!is.null(trackHeight)) {
      checkmate::assert_number(trackHeight, lower = 1, finite = TRUE)
    }
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    payload <- .bamUrlTrackPayload(trackName, bamURL, indexURL,
                                   displayMode = displayMode,
                                   showAllBases = showAllBases,
                                   trackHeight = trackHeight,
                                   trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    flog.debug("--- about to send message, loadBamTrack")
    session$sendCustomMessage("loadBamTrackFromURL", msg.to.igv)

  } # loadBamTrackFromURL

#-------------------------------------------------------------------------------
#' Build the payload of a bam track read by url
#'
#' @description The browser-free half of \code{loadBamTrackFromURL} and
#' \code{loadBamTrackFromLocalFile}: returns the message body the
#' \code{loadBamTrackFromURL} handler in igvShiny.js reads. The urls are used
#' as given (remote, or app-relative from \code{serveLocalFile()}); nothing is
#' written, so \code{files} is empty.
#'
#' @param trackName character string
#' @param bamURL character string, url of the bam file
#' @param indexURL character string, url of the bam index
#' @param displayMode character string, "EXPANDED" (default), "SQUISHED" or
#' "COLLAPSED"
#' @param showAllBases logical, or NULL to leave the key out of the message
#' (what \code{loadBamTrackFromLocalFile} has always sent)
#' @param trackHeight numeric track height in pixels, or NULL for the igv.js
#' default
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, \code{character(0)}
#'
#' @keywords internal
.bamUrlTrackPayload <- function(trackName,
                                bamURL,
                                indexURL,
                                displayMode = "EXPANDED",
                                showAllBases = FALSE,
                                trackHeight = NULL,
                                trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(bamURL)
  checkmate::assert_string(indexURL)
  checkmate::assert_flag(showAllBases, null.ok = TRUE)
  checkmate::assert_number(trackHeight, lower = 1, finite = TRUE,
                           null.ok = TRUE)

  config <- list(
    trackName = trackName,
    bam = bamURL,
    index = indexURL,
    displayMode = displayMode
  )
  config$showAllBases <- showAllBases
  config$height <- trackHeight

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = character(0))
} # .bamUrlTrackPayload

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
#' @param validateReference logical flag, default TRUE: checks track contigs
#' against the active reference genome and emits warnings/toasts on mismatch.
#' @param trackHeight numeric, track height in pixels (default: NULL, igv.js defaults to 300)
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
           trackConfig = list(),
           validateReference = TRUE,
           trackHeight = NULL) {
    if (!is.null(trackHeight)) {
      checkmate::assert_number(trackHeight, lower = 1, finite = TRUE)
    }
    if (is.character(data) && length(data) == 1 && file.exists(data)) {
      return(loadBamTrackFromLocalFile(session, id, trackName,
                                       bamFile = data,
                                       deleteTracksOfSameName = deleteTracksOfSameName,
                                       displayMode = displayMode,
                                       trackConfig = trackConfig,
                                       validateReference = validateReference,
                                       trackHeight = trackHeight))
    }

    if (!requireNamespace("rtracklayer"))
      stop("install rtracklayer to use loadBamTrackFromLocalData")
    if (!requireNamespace("Rsamtools"))
      stop("install Rsamtools to use loadBamTrackFromLocalData")
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    .validateTrackReference(session, id, trackName, data,
                            validateReference = validateReference)

    fpath <- .trackFile(session, ".bam")
    # rtracklayer indexes the bam it writes, next to it and under a name we
    # never see; it is served alongside, so it goes at session end too
    .registerTrackFile(session, paste0(fpath, ".bai"))

    payload <- .bamLocalDataTrackPayload(trackName, data,
                                         path = fpath,
                                         displayMode = displayMode,
                                         trackHeight = trackHeight,
                                         trackConfig = trackConfig)

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadBamTrackFromLocalData", msg.to.igv)

  } # loadBamTrackFromLocalData

#-------------------------------------------------------------------------------
#' Build the payload of a bam track from in-memory alignments
#'
#' @description The browser-free half of \code{loadBamTrackFromLocalData}:
#' exports \code{data} to \code{path} as bam with \code{rtracklayer::export},
#' which also writes the index \code{paste0(path, ".bai")}, and returns the
#' message body the \code{loadBamTrackFromLocalData} handler in igvShiny.js
#' reads. Needs rtracklayer and Rsamtools (Suggests).
#'
#' @param trackName character string
#' @param data a \code{GAlignments} object (GenomicAlignments)
#' @param path character string, the bam file to write; its basename is what
#' the browser fetches from the \code{tracks/} resource path
#' @param displayMode character string, "EXPANDED" (default), "SQUISHED" or
#' "COLLAPSED"
#' @param trackHeight numeric track height in pixels, or NULL for the igv.js
#' default
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the bam and its index
#'
#' @keywords internal
.bamLocalDataTrackPayload <- function(trackName,
                                      data,
                                      path,
                                      displayMode = "EXPANDED",
                                      trackHeight = NULL,
                                      trackConfig = list()) {
  if (!requireNamespace("rtracklayer", quietly = TRUE))
    stop("install rtracklayer to use loadBamTrackFromLocalData")
  if (!requireNamespace("Rsamtools", quietly = TRUE))
    stop("install Rsamtools to use loadBamTrackFromLocalData")
  checkmate::assert_string(trackName)
  checkmate::assert_string(path)
  checkmate::assert_number(trackHeight, lower = 1, finite = TRUE,
                           null.ok = TRUE)

  flog.debug("igvShiny::.bamLocalDataTrackPayload, writing '%s'", path)
  rtracklayer::export(data, path, format = "BAM")

  config <- list(
    trackName = trackName,
    bamDataFilepath = file.path("tracks", basename(path)),
    displayMode = displayMode
  )
  config$height <- trackHeight

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = c(path, paste0(path, ".bai")))
} # .bamLocalDataTrackPayload

#-------------------------------------------------------------------------------
#' Load a BAM Track from a Local File via HTTP Range Requests
#'
#' Streams a local BAM file and its index directly from disk using HTTP 206
#' Partial Content requests handled by the Shiny session. This allows viewing
#' multi-gigabyte BAM files without loading them into R memory.
#'
#' @rdname loadBamTrackFromLocalFile
#' @aliases loadBamTrackFromLocalFile
#'
#' @param session an environment or list, provided and managed by shiny (ShinySession)
#' @param id character string, the html element id of this widget instance
#' @param trackName character string, display name for the track
#' @param bamFile character string, path to an existing, readable .bam file
#' @param indexFile character string, path to the corresponding .bai index file
#'   (default: \code{paste0(bamFile, ".bai")})
#' @param deleteTracksOfSameName logical, whether to delete any existing track
#'   with the same name (default: TRUE)
#' @param displayMode character string, display mode for alignments ("EXPANDED",
#'   "COLLAPSED", or "SQUISHED"), default "EXPANDED"
#' @param trackConfig list, additional track options passed to igv.js
#' @param validateReference logical flag, default TRUE: checks track contigs
#'   against the active reference genome and emits warnings/toasts on mismatch.
#' @param trackHeight numeric, track height in pixels (default: NULL, igv.js defaults to 300)
#'
#' @return None, sends a message to the browser
#'
#' @examples
#' \dontrun{
#' # Inside a Shiny server function:
#' bamFile <- system.file(package = "igvShiny", "extdata",
#'                        "A_2_A24_02_01_01.nanopore.minimap.sorted.bam")
#' baiFile <- paste0(bamFile, ".bai")
#' loadBamTrackFromLocalFile(session, "igvShiny_0", "Nanopore Reads",
#'                          bamFile, baiFile, displayMode = "SQUISHED",
#'                          trackHeight = 100)
#' }
#'
#' @keywords track_loaders
#' @export
loadBamTrackFromLocalFile <-
  function(session,
           id,
           trackName,
           bamFile,
           indexFile = paste0(bamFile, ".bai"),
           deleteTracksOfSameName = TRUE,
           displayMode = "EXPANDED",
           trackConfig = list(),
           validateReference = TRUE,
           trackHeight = NULL) {
    checkmate::assert_multi_class(session, c("ShinySession", "environment"))
    checkmate::assert_string(id)
    checkmate::assert_string(trackName)
    checkmate::assert_file_exists(bamFile, access = "r")
    checkmate::assert_file_exists(indexFile, access = "r")
    if (!is.null(trackHeight)) {
      checkmate::assert_number(trackHeight, lower = 1, finite = TRUE)
    }

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    .validateTrackReference(session, id, trackName, bamFile,
                            validateReference = validateReference)

    bamUrl <- serveLocalFile(session, bamFile)
    baiUrl <- serveLocalFile(session, indexFile)

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    payload <- .bamUrlTrackPayload(trackName, bamUrl, baiUrl,
                                   displayMode = displayMode,
                                   showAllBases = NULL,
                                   trackHeight = trackHeight,
                                   trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadBamTrackFromURL", msg.to.igv)

  } # loadBamTrackFromLocalFile

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
#' @param trackHeight numeric, track height in pixels (default: NULL, igv.js defaults to 300)
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
           trackConfig = list(),
           trackHeight = NULL) {
    if (!is.null(trackHeight)) {
      checkmate::assert_number(trackHeight, lower = 1, finite = TRUE)
    }
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    payload <- .cramUrlTrackPayload(trackName, cramURL, indexURL,
                                    trackHeight = trackHeight,
                                    trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadCramTrackFromURL", msg.to.igv)

  } # loadCramTrackFromURL

#-------------------------------------------------------------------------------
#' Build the payload of a cram track read by url
#'
#' @description The browser-free half of \code{loadCramTrackFromURL} and
#' \code{loadCramTrackFromLocalData}: returns the message body the
#' \code{loadCramTrackFromURL} handler in igvShiny.js reads. The urls are used
#' as given (remote, or app-relative from \code{serveLocalFile()}); nothing is
#' written, so \code{files} is empty.
#'
#' @param trackName character string
#' @param cramURL character string, url of the cram file
#' @param indexURL character string, url of the crai index
#' @param trackHeight numeric track height in pixels, or NULL for the igv.js
#' default
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, \code{character(0)}
#'
#' @keywords internal
.cramUrlTrackPayload <- function(trackName,
                                 cramURL,
                                 indexURL,
                                 trackHeight = NULL,
                                 trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(cramURL)
  checkmate::assert_string(indexURL)
  checkmate::assert_number(trackHeight, lower = 1, finite = TRUE,
                           null.ok = TRUE)

  config <- list(
    trackName = trackName,
    cram = cramURL,
    index = indexURL
  )
  config$height <- trackHeight

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = character(0))
} # .cramUrlTrackPayload

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
#' @param validateReference logical flag, default TRUE: checks track contigs
#' against the active reference genome and emits warnings/toasts on mismatch.
#' @param trackHeight numeric, track height in pixels (default: NULL, igv.js defaults to 300)
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
           trackConfig = list(),
           validateReference = TRUE,
           trackHeight = NULL) {
    checkmate::assert_file_exists(cramFile, access = "r")
    checkmate::assert_file_exists(indexFile, access = "r")
    if (!is.null(trackHeight)) {
      checkmate::assert_number(trackHeight, lower = 1, finite = TRUE)
    }
    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    .validateTrackReference(session, id, trackName, cramFile,
                            validateReference = validateReference)

    cramPath <- serveLocalFile(session, cramFile)
    indexPath <- serveLocalFile(session, indexFile)
    flog.debug(sprintf("igvShiny::load local cram, serving '%s'", cramPath))

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    payload <- .cramUrlTrackPayload(trackName, cramPath, indexPath,
                                    trackHeight = trackHeight,
                                    trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    # the payload is what the remote loader sends, only with app-relative urls,
    # so the browser side needs no handler of its own
    session$sendCustomMessage("loadCramTrackFromURL", msg.to.igv)

  } # loadCramTrackFromLocalData

#' @rdname loadCramTrackFromLocalData
#' @aliases loadCramTrackFromLocalFile
#' @export
loadCramTrackFromLocalFile <- loadCramTrackFromLocalData

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

    payload <- .gff3UrlTrackPayload(trackName, gff3URL, indexURL,
                                    color = color,
                                    colorTable = colorTable,
                                    colorByAttribute = colorByAttribute,
                                    displayMode = displayMode,
                                    trackHeight = trackHeight,
                                    visibilityWindow = visibilityWindow,
                                    trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadGFF3TrackFromURL", msg.to.igv)

  } # loadGFF3TrackFromURL

#-------------------------------------------------------------------------------
#' Build the payload of a GFF3 track read by url
#'
#' @description The browser-free half of \code{loadGFF3TrackFromURL}: returns
#' the message body the \code{loadGFF3TrackFromURL} handler in igvShiny.js
#' reads. Nothing is written, so \code{files} is empty. Like the loader, it
#' has no defaults for the colour, display and window arguments.
#'
#' @param trackName character string
#' @param gff3URL character string, url of the gff3 file
#' @param indexURL character string, url of its index
#' @param color character #RGB or a recognized color name.  ignored if
#' colorTable and colorByAttribute provided
#' @param colorTable list, mapping a gff3 attribute, typically biotype,
#' to a color
#' @param colorByAttribute character, name of a gff3 attribute in column 9,
#' typically "biotype"
#' @param displayMode character,  "EXPANDED",  "SQUISHED" or "COLLAPSED"
#' @param trackHeight numeric defaults to 50
#' @param visibilityWindow numeric, Maximum window size in base pairs
#' for which indexed annotations or variants are displayed
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, \code{character(0)}
#'
#' @keywords internal
.gff3UrlTrackPayload <- function(trackName,
                                 gff3URL,
                                 indexURL,
                                 color = "gray",
                                 colorTable,
                                 colorByAttribute,
                                 displayMode,
                                 trackHeight = 50,
                                 visibilityWindow,
                                 trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(gff3URL)

  config <- list(
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

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = character(0))
} # .gff3UrlTrackPayload
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

    payload <- .gff3TrackPayload(trackName, tbl.gff3,
                                 path = .trackFile(session, ".gff3"),
                                 color = color,
                                 colorTable = colorTable,
                                 colorByAttribute = colorByAttribute,
                                 displayMode = displayMode,
                                 trackHeight = trackHeight,
                                 visibilityWindow = visibilityWindow,
                                 trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadGFF3TrackFromLocalData", msg.to.igv)

  } # loadGFF3TrackFromLocalData

#-------------------------------------------------------------------------------
#' Build the payload of a GFF3 track from a data.frame
#'
#' @description The browser-free half of \code{loadGFF3TrackFromLocalData}:
#' writes the table, header line included as before, to \code{path} and
#' returns the message body the \code{loadGFF3TrackFromLocalData} handler in
#' igvShiny.js reads.
#'
#' @param trackName character string
#' @param tbl.gff3 data.frame in standard 9-column GFF3 format
#' @param path character string, the file to write; its basename is what the
#' browser fetches from the \code{tracks/} resource path
#' @param color character #RGB or a recognized color name.  ignored if
#' colorTable and colorByAttribute provided
#' @param colorTable list, mapping a gff3 attribute, typically biotype,
#' to a color
#' @param colorByAttribute character, name of a gff3 attribute in column 9,
#' typically "biotype"
#' @param displayMode character,  "EXPANDED",  "SQUISHED" or "COLLAPSED"
#' @param trackHeight numeric defaults to 50
#' @param visibilityWindow numeric, Maximum window size in base pairs
#' for which indexed annotations or variants are displayed
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the paths written (here: \code{path})
#'
#' @keywords internal
.gff3TrackPayload <- function(trackName,
                              tbl.gff3,
                              path,
                              color = "gray",
                              colorTable,
                              colorByAttribute,
                              displayMode,
                              trackHeight = 50,
                              visibilityWindow,
                              trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_class(tbl.gff3, "data.frame")
  checkmate::assert_string(path)

  write.table(
    tbl.gff3,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    file = path
  )
  flog.debug("--- igvShiny.R, .gff3TrackPayload wrote %d,%d to %s",
             NROW(tbl.gff3), NCOL(tbl.gff3), path)

  config <- list(
    trackName = trackName,
    filePath = file.path("tracks", basename(path)),
    color = color,
    colorTable = colorTable,
    colorByAttribute = colorByAttribute,
    displayMode = displayMode,
    trackHeight = trackHeight,
    visibilityWindow = visibilityWindow
  )

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = path)
} # .gff3TrackPayload
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
    payload <- .spliceJunctionUrlTrackPayload(trackName, url,
                                              indexURL = indexURL,
                                              trackHeight = trackHeight,
                                              displayMode = displayMode,
                                              trackConfig = trackConfig)

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    msg.to.igv <- c(list(elementID = id), payload$config)
    session$sendCustomMessage("loadSpliceJunctionTrackFromURL", msg.to.igv)

  } # loadSpliceJunctionTrackFromURL

#-------------------------------------------------------------------------------
#' Build the payload of a splice junction track read by url
#'
#' @description The browser-free half of
#' \code{loadSpliceJunctionTrackFromURL} (and, with an app-relative url, of
#' \code{loadSpliceJunctionTrackFromLocalData}): returns the message body the
#' \code{loadSpliceJunctionTrackFromURL} handler in igvShiny.js reads. Nothing
#' is written, so \code{files} is empty.
#'
#' @param trackName character string
#' @param url character string, url of the junction bed file
#' @param indexURL character string, url of a tabix index, or "" for none;
#' anything but a single non-NA string is turned into "" with a warning
#' @param trackHeight an integer, 100 (pixels) by default
#' @param displayMode character, "COLLAPSED", "EXPANDED" or "SQUISHED"
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, \code{character(0)}
#'
#' @keywords internal
.spliceJunctionUrlTrackPayload <- function(trackName,
                                           url,
                                           indexURL = "",
                                           trackHeight = 100,
                                           displayMode = "COLLAPSED",
                                           trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(url)

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

  config <- list(
    trackName = trackName,
    url = url,
    indexURL = indexURL,
    trackHeight = trackHeight,
    displayMode = displayMode
  )

  list(config = .sanitizeAndMergeOptions(config, trackConfig),
       files = character(0))
} # .spliceJunctionUrlTrackPayload
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
    tbl <- .normalizeJunctionColumns(tbl)

    if (deleteTracksOfSameName) {
      removeTracksByName(session, id, trackName)
    }

    state[["userAddedTracks"]] <-
      unique(c(state[["userAddedTracks"]], trackName))

    payload <- .spliceJunctionTrackPayload(trackName, tbl,
                                           path = .trackFile(session, ".bed"),
                                           trackHeight = trackHeight,
                                           displayMode = displayMode,
                                           trackConfig = trackConfig)

    msg.to.igv <- c(list(elementID = id), payload$config)
    # The url handler takes it from here: an unindexed bed served by shiny is
    # the same job as an unindexed bed served by anyone else.
    session$sendCustomMessage("loadSpliceJunctionTrackFromURL", msg.to.igv)

  } # loadSpliceJunctionTrackFromLocalData

#-------------------------------------------------------------------------------
#' Give a junction data.frame the chr/start/end column names and check them
#'
#' @description Renames a "chrom" column to "chr" and fails when chr, start
#' or end is missing or of the wrong type.
#'
#' @param tbl data.frame, with at least "chrom" (or "chr") "start" "end" columns
#'
#' @return the data.frame, its "chrom" column possibly renamed
#'
#' @keywords internal
.normalizeJunctionColumns <- function(tbl) {
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

  tbl
} # .normalizeJunctionColumns

#-------------------------------------------------------------------------------
#' Build the payload of a splice junction track from a data.frame
#'
#' @description The browser-free half of
#' \code{loadSpliceJunctionTrackFromLocalData}: writes the six-column junction
#' bed to \code{path} and returns the message body of
#' \code{.spliceJunctionUrlTrackPayload} pointed at it, which is what the
#' \code{loadSpliceJunctionTrackFromURL} handler in igvShiny.js reads.
#'
#' @param trackName character string
#' @param tbl data.frame, with at least "chrom" (or "chr") "start" "end"
#' columns, in bed coordinates; see \code{loadSpliceJunctionTrackFromLocalData}
#' for the optional columns
#' @param path character string, the file to write; its basename is what the
#' browser fetches from the \code{tracks/} resource path
#' @param trackHeight an integer, 100 (pixels) by default
#' @param displayMode character, "COLLAPSED", "EXPANDED" or "SQUISHED"
#' @param trackConfig a named list of additional igv.js track configuration
#' options, merged onto the defaults
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the paths written (here: \code{path})
#'
#' @keywords internal
.spliceJunctionTrackPayload <- function(trackName,
                                        tbl,
                                        path,
                                        trackHeight = 100,
                                        displayMode = "COLLAPSED",
                                        trackConfig = list()) {
  checkmate::assert_string(trackName)
  checkmate::assert_string(path)

  tbl <- .normalizeJunctionColumns(tbl)

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

  write.table(
    tbl.bed,
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
  )
  flog.debug("--- igvShiny.R, .spliceJunctionTrackPayload wrote %d to %s",
             NROW(tbl.bed), path)

  payload <- .spliceJunctionUrlTrackPayload(
    trackName,
    url = file.path("tracks", basename(path)),
    indexURL = "",
    trackHeight = trackHeight,
    displayMode = displayMode,
    trackConfig = trackConfig
  )
  payload$files <- path
  payload
} # .spliceJunctionTrackPayload
#-------------------------------------------------------------------------------
