#-------------------------------------------------------------------------------
# S4 track classes, ported from igvR (R/Track.R and R/*Track.R).
#
# A track object only describes a track; turning it into what the browser
# needs is the job of the payload builders in igvShiny.R. Each class family
# has a .trackPayload() method that hands its slots to one of those builders,
# and loadTrack() is the sender: it gets a file path from .trackFile(), calls
# the builder and sends the message the matching igvShiny.js handler reads.
#-------------------------------------------------------------------------------

#' Track: the base class of igvShiny's S4 tracks
#'
#' @description \code{Track} holds the slots every igv.js track shares. It is
#' the parent of \code{\linkS4class{igvAnnotationTrack}} and
#' \code{\linkS4class{QuantitativeTrack}}; build tracks with their subclass
#' constructors, e.g. \code{\link{DataFrameAnnotationTrack}}, and display them
#' with \code{\link{loadTrack}}.
#'
#' @slot trackType character, e.g. "annotation" or "quantitative"
#' @slot sourceType character, e.g. "file" or "url"
#' @slot fileFormat character, e.g. "bed" or "bedGraph"
#' @slot trackName character, the track label
#' @slot onScreenOrder numeric, explicit placement of the track
#' @slot color character, a CSS color
#' @slot height numeric, track height in pixels
#' @slot autoTrackHeight logical
#' @slot minTrackHeight numeric, pixels
#' @slot maxTrackHeight numeric, pixels
#' @slot visibilityWindow numeric, base pairs
#'
#' @param trackType One of "annotation", "quantitative", "alignment",
#' "variant", "gwas", "genomicAlignment", "remoteAlignment",
#' "pairedEndAnnotation"
#' @param sourceType One of "file", "url", "gcs", "ga4gh"
#' @param fileFormat One of "bed", "gff", "gff3", "gtf", "wig", "bigWig",
#' "bedGraph", "bam", "vcf", "seg", "gwas", "cram", "bedpe"
#' @param trackName A character string, used as track label by igv; we
#' recommend unique names per track
#' @param onScreenOrder Numeric, for explicit placement of track within the
#' current set
#' @param color A CSS color name (e.g., "red" or "#FF0000"), or "random"
#' @param height track height in pixels
#' @param autoTrackHeight If TRUE, track height is adjusted dynamically,
#' within the bounds set by minTrackHeight and maxTrackHeight
#' @param minTrackHeight In pixels, minimum allowed
#' @param maxTrackHeight In pixels, maximum allowed
#' @param visibilityWindow Maximum window size in base pairs for which indexed
#' annotations or variants are displayed
#'
#' @return An object of class Track
#'
#' @references \url{https://igv.org/doc/igvjs/#tracks/Tracks/}
#'
#' @examples
#' track <- Track(trackType = "annotation", sourceType = "file",
#'                fileFormat = "bed", trackName = "demo", color = "red")
#' trackInfo(track)
#'
#' @keywords track_classes
#' @name Track-class
#' @rdname Track-class
#' @exportClass Track
.Track <- setClass(
  "Track",
  slots = c(
    trackType = "character",
    sourceType = "character",
    fileFormat = "character",
    trackName = "character",
    onScreenOrder = "numeric",
    color = "character",
    height = "numeric",
    autoTrackHeight = "logical",
    minTrackHeight = "numeric",
    maxTrackHeight = "numeric",
    visibilityWindow = "numeric"
  )
)

#' @rdname Track-class
#' @export
Track <- function(trackType = c("annotation", "quantitative", "alignment",
                                "variant", "gwas", "genomicAlignment",
                                "remoteAlignment", "pairedEndAnnotation"),
                  sourceType = c("file", "url", "gcs", "ga4gh"),
                  fileFormat = c("bed", "gff", "gff3", "gtf", "wig", "bigWig",
                                 "bedGraph", "bam", "vcf", "seg", "gwas",
                                 "cram", "bedpe"),
                  trackName,
                  onScreenOrder = NA_real_,
                  color = "gray",
                  height = 50,
                  autoTrackHeight = FALSE,
                  minTrackHeight = 50,
                  maxTrackHeight = 500,
                  visibilityWindow = 100000) {
  trackType <- match.arg(trackType)
  sourceType <- match.arg(sourceType)
  fileFormat <- match.arg(fileFormat)
  checkmate::assert_string(trackName, min.chars = 1L)
  checkmate::assert_number(onScreenOrder, na.ok = TRUE)
  checkmate::assert_string(color)
  checkmate::assert_number(height, lower = 1)
  checkmate::assert_flag(autoTrackHeight)
  checkmate::assert_number(minTrackHeight, lower = 0)
  checkmate::assert_number(maxTrackHeight, lower = 0)
  checkmate::assert_number(visibilityWindow, na.ok = TRUE)

  if (color == "random")
    color <- randomColors[sample(seq_along(randomColors), 1)]

  .Track(
    trackType = trackType,
    sourceType = sourceType,
    fileFormat = fileFormat,
    trackName = trackName,
    onScreenOrder = onScreenOrder,
    color = color,
    height = height,
    autoTrackHeight = autoTrackHeight,
    minTrackHeight = minTrackHeight,
    maxTrackHeight = maxTrackHeight,
    visibilityWindow = visibilityWindow
  )
} # Track

#-------------------------------------------------------------------------------
#' Basic facts about a track
#'
#' @param obj An object of base class Track
#'
#' @return \code{trackInfo}: a list with trackType, fileFormat, source and
#' class. \code{trackSize}: the number of features, or \code{NA} when the
#' track holds no data of its own
#'
#' @examples
#' tbl <- data.frame(chrom = "chr1", start = c(100, 300), end = c(200, 400),
#'                   stringsAsFactors = FALSE)
#' track <- DataFrameAnnotationTrack("demo", tbl)
#' trackInfo(track)
#' trackSize(track)
#'
#' @keywords track_classes
#' @rdname trackInfo
#' @export
setGeneric("trackInfo", signature = "obj",
           function(obj) standardGeneric("trackInfo"))

#' @rdname trackInfo
#' @export
setGeneric("trackSize", signature = "obj",
           function(obj) standardGeneric("trackSize"))

#' @rdname trackInfo
setMethod("trackInfo", "Track", function(obj) {
  list(
    trackType = obj@trackType,
    fileFormat = obj@fileFormat,
    source = obj@sourceType,
    class = as.character(class(obj))
  )
})

#' @rdname trackInfo
setMethod("trackSize", "Track", function(obj) {
  if (!methods::.hasSlot(obj, "coreObject"))
    return(NA_integer_)
  core <- obj@coreObject
  if (is.data.frame(core)) NROW(core) else length(core)
})

#-------------------------------------------------------------------------------
#' Annotation tracks: bed-like features from a data.frame, GRanges or UCSCData
#'
#' @description \code{igvAnnotationTrack} adds the slots of igv.js annotation
#' tracks to \code{\linkS4class{Track}}. Its subclasses carry the features in
#' a \code{coreObject} slot: \code{DataFrameAnnotationTrack} (a bed-like
#' data.frame, written as is), \code{GRangesAnnotationTrack} (a
#' \code{GRanges}; 1-based starts become 0-based bed starts) and
#' \code{UCSCBedAnnotationTrack} (an \code{rtracklayer} \code{UCSCData}, needs
#' the suggested package rtracklayer). Display one with
#' \code{\link{loadTrack}}; of the annotation slots, \code{displayMode} is
#' sent to igv.js.
#'
#' @slot classTypeOfSuppliedObject character
#' @slot displayMode character, "COLLAPSED", "SQUISHED" or "EXPANDED"
#' @slot expandedRowHeight numeric, row height in "EXPANDED" mode
#' @slot squishedRowHeight numeric, row height in "SQUISHED" mode
#' @slot nameField character
#' @slot maxRows numeric
#' @slot searchable logical
#' @slot coreObject the features: data.frame, GRanges or UCSCData
#'
#' @param trackName A character string, used as track label by igv; we
#' recommend unique names per track
#' @param annotation for \code{DataFrameAnnotationTrack}, a data.frame with at
#' least chrom (or chr), start and end columns, in bed (0-based) coordinates;
#' for \code{UCSCBedAnnotationTrack}, a \code{UCSCData} object, e.g. from
#' \code{rtracklayer::import(format = "bed")}
#' @param annotationData a \code{GRanges}; mcols "name" and "score", when
#' present, fill the bed name and score columns
#' @param color A CSS color name (e.g., "red" or "#FF0000"), or "random"; for
#' a data.frame, leave the default "" if supplying bed9 with itemRgb
#' @param displayMode "COLLAPSED", "SQUISHED" or "EXPANDED"
#' @param trackHeight track height in pixels
#' @param expandedRowHeight Height of each row of features in "EXPANDED" mode
#' @param squishedRowHeight Height of each row of features in "SQUISHED" mode
#' @param maxRows maximum number of feature rows to display
#' @param searchable If TRUE, labels on annotation elements may be used in
#' search
#' @param visibilityWindow Maximum window size in base pairs for which
#' features are displayed
#'
#' @return An object of the named class
#'
#' @examples
#' tbl <- data.frame(chrom = rep("chr5", 3),
#'                   start = c(88883100, 88883200, 88883350),
#'                   end = c(88883150, 88883220, 88883390),
#'                   name = c("a", "b", "c"),
#'                   stringsAsFactors = FALSE)
#' track <- DataFrameAnnotationTrack("data.frame demo", tbl, color = "red")
#' gr <- GenomicRanges::GRanges(c("chr5:100-149", "chr5:300-349"))
#' track2 <- GRangesAnnotationTrack("GRanges demo", gr)
#' trackSize(track2)
#'
#' @keywords track_classes
#' @name igvAnnotationTrack-class
#' @rdname igvAnnotationTrack-class
#' @aliases DataFrameAnnotationTrack-class GRangesAnnotationTrack-class
#' UCSCBedAnnotationTrack-class
#' @exportClass igvAnnotationTrack
.igvAnnotationTrack <- setClass(
  "igvAnnotationTrack",
  contains = "Track",
  slots = c(
    classTypeOfSuppliedObject = "character",
    displayMode = "character",
    expandedRowHeight = "numeric",
    squishedRowHeight = "numeric",
    nameField = "character",
    maxRows = "numeric",
    searchable = "logical"
  )
)

#' @rdname igvAnnotationTrack-class
#' @exportClass DataFrameAnnotationTrack
.DataFrameAnnotationTrack <- setClass(
  "DataFrameAnnotationTrack",
  contains = "igvAnnotationTrack",
  slots = c(coreObject = "data.frame")
)

#' @rdname igvAnnotationTrack-class
#' @exportClass GRangesAnnotationTrack
.GRangesAnnotationTrack <- setClass(
  "GRangesAnnotationTrack",
  contains = "igvAnnotationTrack",
  slots = c(coreObject = "GRanges")
)

# UCSCData is an rtracklayer class and rtracklayer is only suggested, so the
# slot is typed with its parent GRanges and the validity method checks the
# rest; is() needs no rtracklayer when the object is not a UCSCData.
#' @rdname igvAnnotationTrack-class
#' @exportClass UCSCBedAnnotationTrack
.UCSCBedAnnotationTrack <- setClass(
  "UCSCBedAnnotationTrack",
  contains = "igvAnnotationTrack",
  slots = c(coreObject = "GRanges"),
  validity = function(object) {
    if (is(object@coreObject, "UCSCData")) TRUE else
      "coreObject must be a UCSCData object (rtracklayer)"
  }
)

# The igvAnnotationTrack part every annotation constructor shares.
.annotationTrackBase <- function(trackName, color, displayMode, trackHeight,
                                 expandedRowHeight, squishedRowHeight,
                                 maxRows, searchable, visibilityWindow,
                                 suppliedClass) {
  checkmate::assert_choice(displayMode,
                           c("COLLAPSED", "SQUISHED", "EXPANDED"))
  checkmate::assert_number(expandedRowHeight, lower = 1)
  checkmate::assert_number(squishedRowHeight, lower = 1)
  checkmate::assert_number(maxRows, lower = 1)
  checkmate::assert_flag(searchable)

  .igvAnnotationTrack(
    Track(
      trackType = "annotation",
      sourceType = "file",
      fileFormat = "bed",
      trackName = trackName,
      color = color,
      height = trackHeight,
      visibilityWindow = visibilityWindow
    ),
    classTypeOfSuppliedObject = suppliedClass,
    displayMode = displayMode,
    expandedRowHeight = expandedRowHeight,
    squishedRowHeight = squishedRowHeight,
    maxRows = maxRows,
    searchable = searchable
  )
} # .annotationTrackBase

#' @rdname igvAnnotationTrack-class
#' @export
DataFrameAnnotationTrack <- function(trackName,
                                     annotation,
                                     color = "",
                                     displayMode = "SQUISHED",
                                     trackHeight = 50,
                                     expandedRowHeight = 30,
                                     squishedRowHeight = 15,
                                     maxRows = 500,
                                     searchable = FALSE,
                                     visibilityWindow = 100000) {
  checkmate::assert_class(annotation, "data.frame")
  checkmate::assert_true(NCOL(annotation) >= 3L)

  base <- .annotationTrackBase(trackName, color, displayMode, trackHeight,
                               expandedRowHeight, squishedRowHeight, maxRows,
                               searchable, visibilityWindow, "data.frame")

  # bed9 with itemRgb loses its colors when the strand is not + or -
  if (NCOL(annotation) >= 9L && "itemRgb" %in% colnames(annotation) &&
      "strand" %in% colnames(annotation) &&
      !all(annotation$strand %in% c("+", "-")))
    futile.logger::flog.warn(
      "bed9 format tables with itemRgb expect only '+' and '-' strand values")

  .DataFrameAnnotationTrack(base, coreObject = annotation)
} # DataFrameAnnotationTrack

#' @rdname igvAnnotationTrack-class
#' @export
GRangesAnnotationTrack <- function(trackName,
                                   annotationData,
                                   color = "darkGrey",
                                   displayMode = "SQUISHED",
                                   trackHeight = 50,
                                   expandedRowHeight = 30,
                                   squishedRowHeight = 15,
                                   maxRows = 500,
                                   searchable = FALSE,
                                   visibilityWindow = 100000) {
  checkmate::assert_class(annotationData, "GRanges")

  base <- .annotationTrackBase(trackName, color, displayMode, trackHeight,
                               expandedRowHeight, squishedRowHeight, maxRows,
                               searchable, visibilityWindow, "GRanges")

  .GRangesAnnotationTrack(base, coreObject = annotationData)
} # GRangesAnnotationTrack

#' @rdname igvAnnotationTrack-class
#' @export
UCSCBedAnnotationTrack <- function(trackName,
                                   annotation,
                                   color = "darkGrey",
                                   displayMode = "SQUISHED",
                                   trackHeight = 50,
                                   expandedRowHeight = 30,
                                   squishedRowHeight = 15,
                                   maxRows = 500,
                                   searchable = FALSE,
                                   visibilityWindow = 100000) {
  if (!requireNamespace("rtracklayer", quietly = TRUE))
    stop("UCSCBedAnnotationTrack needs the rtracklayer package")
  checkmate::assert_class(annotation, "UCSCData")

  base <- .annotationTrackBase(trackName, color, displayMode, trackHeight,
                               expandedRowHeight, squishedRowHeight, maxRows,
                               searchable, visibilityWindow, "UCSCData")

  annotation@trackLine@name <- trackName
  .UCSCBedAnnotationTrack(base, coreObject = annotation)
} # UCSCBedAnnotationTrack

#-------------------------------------------------------------------------------
#' Quantitative tracks: scored intervals from a data.frame, GRanges or
#' UCSCData
#'
#' @description \code{QuantitativeTrack} adds y-axis scaling to
#' \code{\linkS4class{Track}}; it carries no data, so build tracks with its
#' subclasses: \code{DataFrameQuantitativeTrack} (a data.frame of chrom,
#' start, end, value in bedGraph coordinates), \code{GRangesQuantitativeTrack}
#' (a \code{GRanges} with exactly one numeric metadata column) and
#' \code{UCSCBedGraphQuantitativeTrack} (an \code{rtracklayer} \code{UCSCData}
#' imported from bedGraph, needs the suggested package rtracklayer). Display
#' one with \code{\link{loadTrack}}.
#'
#' @slot autoscale logical, scale the track to the maximum value in view
#' @slot min numeric, y-axis minimum, used when autoscale is FALSE
#' @slot max numeric, y-axis maximum, used when autoscale is FALSE
#' @slot coreObject the scores: data.frame, GRanges or UCSCData
#'
#' @param trackName A character string, used as track label by igv; we
#' recommend unique names per track
#' @param quantitativeData the scored intervals; ignored by
#' \code{QuantitativeTrack}, which only builds the shared part
#' @param fileFormat One of "wig", "bigWig", "bedGraph", "gwas"
#' @param color A CSS color name (e.g., "red" or "#FF0000"), or "random"
#' @param sourceType "file" or "url"
#' @param trackHeight track height in pixels
#' @param autoscale Autoscale track to maximum value in view
#' @param min Sets the minimum value for the data (y-axis) scale
#' @param max Sets the maximum value for the data (y-axis) scale; ignored if
#' autoscale is TRUE
#' @param visibilityWindow Maximum window size in base pairs for which data
#' is displayed
#'
#' @return An object of the named class
#'
#' @examples
#' tbl <- data.frame(chrom = "chr1", start = c(100, 200), end = c(200, 300),
#'                   value = c(0.5, 2), stringsAsFactors = FALSE)
#' track <- DataFrameQuantitativeTrack("bedGraph demo", tbl, autoscale = TRUE)
#' gr <- GenomicRanges::GRanges(c("chr1:101-200", "chr1:201-300"),
#'                              score = c(0.5, 2))
#' track2 <- GRangesQuantitativeTrack("GRanges demo", gr)
#' trackSize(track2)
#'
#' @keywords track_classes
#' @name QuantitativeTrack-class
#' @rdname QuantitativeTrack-class
#' @aliases DataFrameQuantitativeTrack-class GRangesQuantitativeTrack-class
#' UCSCBedGraphQuantitativeTrack-class
#' @exportClass QuantitativeTrack
.QuantitativeTrack <- setClass(
  "QuantitativeTrack",
  contains = "Track",
  slots = c(
    autoscale = "logical",
    min = "numeric",
    max = "numeric"
  )
)

#' @rdname QuantitativeTrack-class
#' @exportClass DataFrameQuantitativeTrack
.DataFrameQuantitativeTrack <- setClass(
  "DataFrameQuantitativeTrack",
  contains = "QuantitativeTrack",
  slots = c(coreObject = "data.frame")
)

#' @rdname QuantitativeTrack-class
#' @exportClass GRangesQuantitativeTrack
.GRangesQuantitativeTrack <- setClass(
  "GRangesQuantitativeTrack",
  contains = "QuantitativeTrack",
  slots = c(coreObject = "GRanges")
)

#' @rdname QuantitativeTrack-class
#' @exportClass UCSCBedGraphQuantitativeTrack
.UCSCBedGraphQuantitativeTrack <- setClass(
  "UCSCBedGraphQuantitativeTrack",
  contains = "QuantitativeTrack",
  slots = c(coreObject = "GRanges"),
  validity = function(object) {
    if (is(object@coreObject, "UCSCData")) TRUE else
      "coreObject must be a UCSCData object (rtracklayer)"
  }
)

#' @rdname QuantitativeTrack-class
#' @export
QuantitativeTrack <- function(trackName,
                              quantitativeData,
                              fileFormat = c("wig", "bigWig", "bedGraph",
                                             "gwas"),
                              color = "gray",
                              sourceType = c("file", "url"),
                              trackHeight = 50,
                              autoscale = TRUE,
                              min = NA_real_,
                              max = NA_real_,
                              visibilityWindow = 100000) {
  checkmate::assert_flag(autoscale)
  checkmate::assert_number(min, na.ok = TRUE)
  checkmate::assert_number(max, na.ok = TRUE)

  .QuantitativeTrack(
    Track(
      trackType = "quantitative",
      sourceType = match.arg(sourceType),
      fileFormat = match.arg(fileFormat),
      trackName = trackName,
      color = color,
      height = trackHeight,
      visibilityWindow = visibilityWindow
    ),
    autoscale = autoscale,
    min = min,
    max = max
  )
} # QuantitativeTrack

#' @rdname QuantitativeTrack-class
#' @export
DataFrameQuantitativeTrack <- function(trackName,
                                       quantitativeData,
                                       color = "blue",
                                       trackHeight = 50,
                                       autoscale,
                                       min = NA_real_,
                                       max = NA_real_,
                                       visibilityWindow = 100000) {
  checkmate::assert_class(quantitativeData, "data.frame")
  checkmate::assert_true(NCOL(quantitativeData) >= 4L)
  checkmate::assert_character(quantitativeData[[1]])
  checkmate::assert_numeric(quantitativeData[[2]])
  checkmate::assert_numeric(quantitativeData[[3]])
  checkmate::assert_numeric(quantitativeData[[4]])

  base <- QuantitativeTrack(trackName, fileFormat = "bedGraph",
                            color = color, sourceType = "file",
                            trackHeight = trackHeight, autoscale = autoscale,
                            min = min, max = max,
                            visibilityWindow = visibilityWindow)

  .DataFrameQuantitativeTrack(base, coreObject = quantitativeData)
} # DataFrameQuantitativeTrack

#' @rdname QuantitativeTrack-class
#' @export
GRangesQuantitativeTrack <- function(trackName,
                                     quantitativeData,
                                     color = "blue",
                                     trackHeight = 50,
                                     autoscale = TRUE,
                                     min = NA_real_,
                                     max = NA_real_,
                                     visibilityWindow = 100000) {
  checkmate::assert_class(quantitativeData, "GRanges")

  base <- QuantitativeTrack(trackName, fileFormat = "bedGraph",
                            color = color, sourceType = "file",
                            trackHeight = trackHeight, autoscale = autoscale,
                            min = min, max = max,
                            visibilityWindow = visibilityWindow)

  .GRangesQuantitativeTrack(base, coreObject = quantitativeData)
} # GRangesQuantitativeTrack

#' @rdname QuantitativeTrack-class
#' @export
UCSCBedGraphQuantitativeTrack <- function(trackName,
                                          quantitativeData,
                                          color = "blue",
                                          trackHeight = 50,
                                          autoscale = TRUE,
                                          min = NA_real_,
                                          max = NA_real_,
                                          visibilityWindow = 100000) {
  if (!requireNamespace("rtracklayer", quietly = TRUE))
    stop("UCSCBedGraphQuantitativeTrack needs the rtracklayer package")
  checkmate::assert_class(quantitativeData, "UCSCData")

  # igvR ignored trackHeight here and always used 50; it is honoured now
  base <- QuantitativeTrack(trackName, fileFormat = "bedGraph",
                            color = color, sourceType = "file",
                            trackHeight = trackHeight, autoscale = autoscale,
                            min = min, max = max,
                            visibilityWindow = visibilityWindow)

  .UCSCBedGraphQuantitativeTrack(base, coreObject = quantitativeData)
} # UCSCBedGraphQuantitativeTrack

#-------------------------------------------------------------------------------
# Payload builders for track objects. Internal generics: .trackTable() turns
# the coreObject into the data.frame the data.frame builders take, and
# .trackPayload() is the builder itself, returning list(config, files) like
# every .<kind>TrackPayload() in igvShiny.R.
#-------------------------------------------------------------------------------

#' A track's features as the data.frame its payload builder takes
#'
#' @description Annotation tracks give a bed table (chr, start, end, and for
#' GRanges name, score, strand), quantitative tracks a bedGraph table (chr,
#' start, end, value). GRanges starts are 1-based and become 0-based here.
#'
#' @param track an object of a Track subclass with a coreObject slot
#'
#' @return a data.frame
#'
#' @keywords internal
setGeneric(".trackTable", signature = "track",
           function(track) standardGeneric(".trackTable"))

setMethod(".trackTable", "Track", function(track) {
  stop(sprintf("igvShiny: no feature table for a track of class %s",
               class(track)[1]))
})

setMethod(".trackTable", "DataFrameAnnotationTrack", function(track) {
  .normalizeBedColumns(track@coreObject)
})

setMethod(".trackTable", "GRangesAnnotationTrack", function(track) {
  .granges2bedTable(track@coreObject)
})

setMethod(".trackTable", "UCSCBedAnnotationTrack", function(track) {
  .granges2bedTable(track@coreObject)
})

setMethod(".trackTable", "DataFrameQuantitativeTrack", function(track) {
  .normalizeBedGraphColumns(track@coreObject)
})

setMethod(".trackTable", "GRangesQuantitativeTrack", function(track) {
  .granges2bedGraphTable(track@coreObject)
})

setMethod(".trackTable", "UCSCBedGraphQuantitativeTrack", function(track) {
  .granges2bedGraphTable(track@coreObject)
})

#' GRanges to a six column bed data.frame
#'
#' @param gr a GRanges (or UCSCData)
#'
#' @return a data.frame with chr, start (0-based), end, name, score, strand
#'
#' @keywords internal
.granges2bedTable <- function(gr) {
  checkmate::assert_class(gr, "GRanges")
  meta <- GenomicRanges::mcols(gr)
  n <- length(gr)
  name <- if ("name" %in% colnames(meta)) as.character(meta$name) else
    rep(".", n)
  score <- if ("score" %in% colnames(meta)) as.numeric(meta$score) else
    rep(0, n)
  strand <- as.character(BiocGenerics::strand(gr))
  strand[strand == "*"] <- "."

  data.frame(
    chr = as.character(GenomicRanges::seqnames(gr)),
    start = BiocGenerics::start(gr) - 1L,
    end = BiocGenerics::end(gr),
    name = name,
    score = score,
    strand = strand,
    stringsAsFactors = FALSE
  )
} # .granges2bedTable

#' GRanges with one numeric metadata column to a bedGraph data.frame
#'
#' @param gr a GRanges (or UCSCData) with exactly one numeric metadata column
#'
#' @return a data.frame with chr, start (0-based), end, value
#'
#' @keywords internal
.granges2bedGraphTable <- function(gr) {
  checkmate::assert_class(gr, "GRanges")
  meta <- GenomicRanges::mcols(gr)
  if (NCOL(meta) != 1L)
    stop("igvShiny: a quantitative GRanges needs exactly one metadata column")
  value <- meta[[1]]
  if (!is.numeric(value))
    stop("igvShiny: the metadata column of a quantitative GRanges must be ",
         "numeric")

  data.frame(
    chr = as.character(GenomicRanges::seqnames(gr)),
    start = BiocGenerics::start(gr) - 1L,
    end = BiocGenerics::end(gr),
    value = value,
    stringsAsFactors = FALSE
  )
} # .granges2bedGraphTable

#' Build the payload of a track object
#'
#' @description The builder half of \code{\link{loadTrack}}: hands the slots
#' of \code{track} to the data.frame builder of its family
#' (\code{.bedTrackPayload} for annotation tracks, \code{.bedGraphTrackPayload}
#' for quantitative tracks) and returns its \code{list(config, files)}. It
#' touches no session; a builder that writes a file writes it to \code{path}.
#'
#' @param track an object of a Track subclass
#' @param path character string, the file to write, or NULL for builders that
#' write none
#' @param trackConfig a named list of additional igv.js track configuration
#' options; slot values win over it
#'
#' @return a list with \code{config}, the message body without
#' \code{elementID}, and \code{files}, the paths written
#'
#' @keywords internal
setGeneric(".trackPayload", signature = "track",
           function(track, path = NULL, trackConfig = list()) {
             standardGeneric(".trackPayload")
           })

setMethod(".trackPayload", "Track",
          function(track, path = NULL, trackConfig = list()) {
  stop(sprintf("igvShiny: no payload builder for a track of class %s",
               class(track)[1]))
})

setMethod(".trackPayload", "igvAnnotationTrack",
          function(track, path = NULL, trackConfig = list()) {
  # the slots igvR sent to the browser for this class: color, height (the
  # builder's own arguments) and displayMode
  slotOptions <- list(displayMode = track@displayMode)
  .bedTrackPayload(track@trackName, .trackTable(track), path,
                   color = track@color,
                   trackHeight = track@height,
                   trackConfig = .sanitizeAndMergeOptions(slotOptions,
                                                          trackConfig))
})

setMethod(".trackPayload", "QuantitativeTrack",
          function(track, path = NULL, trackConfig = list()) {
  .bedGraphTrackPayload(track@trackName, .trackTable(track),
                        color = track@color,
                        trackHeight = track@height,
                        autoscale = track@autoscale,
                        min = track@min,
                        max = track@max,
                        trackConfig = trackConfig)
})

#-------------------------------------------------------------------------------
#' Display a track object in an igvShiny widget
#'
#' @description \code{loadTrack} is the one loader for every track class: it
#' turns \code{track} into a payload with the builder of its class and sends
#' it to the browser, removing an earlier track of the same name first.
#' Annotation tracks are served as a bed file, quantitative tracks travel
#' inline, exactly as with \code{\link{loadBedTrack}} and
#' \code{\link{loadBedGraphTrack}}.
#'
#' @param session an environment or list, provided and managed by shiny
#' @param id character string, the html element id of this widget instance
#' @param track an object of a Track subclass, e.g.
#' \code{\link{DataFrameAnnotationTrack}} or
#' \code{\link{GRangesQuantitativeTrack}}
#' @param ... arguments of the methods: \code{deleteTracksOfSameName}
#' (logical, default TRUE), \code{trackConfig} (a named list of additional
#' igv.js track configuration options, merged onto the track's own) and
#' \code{validateReference} (logical, default TRUE: check the track contigs
#' and coordinates against the active reference genome)
#'
#' @return nothing
#'
#' @examples
#' tbl <- data.frame(chrom = "chr1", start = c(100, 300), end = c(200, 400),
#'                   stringsAsFactors = FALSE)
#' track <- DataFrameAnnotationTrack("demo", tbl, color = "red")
#' if (interactive()) {
#'   # inside a shiny server function, with an igvShiny output "igvShiny_0":
#'   # loadTrack(session, "igvShiny_0", track)
#' }
#'
#' @rdname loadTrack
#' @keywords track_loaders
#' @export
setGeneric("loadTrack", signature = "track",
           function(session, id, track, ...) standardGeneric("loadTrack"))

#' @rdname loadTrack
setMethod("loadTrack", "Track", function(session, id, track, ...) {
  stop(sprintf("igvShiny: loadTrack has no method for a track of class %s",
               class(track)[1]))
})

#' @rdname loadTrack
#' @param deleteTracksOfSameName logical, default TRUE
#' @param trackConfig a named list of additional igv.js track configuration
#' options
#' @param validateReference logical flag, default TRUE
setMethod("loadTrack", "igvAnnotationTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  .sendTrack(session, id, track, "loadBedTrackFromFile", ".bed",
             deleteTracksOfSameName, trackConfig, validateReference)
})

#' @rdname loadTrack
setMethod("loadTrack", "QuantitativeTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  .sendTrack(session, id, track, "loadBedGraphTrack", NULL,
             deleteTracksOfSameName, trackConfig, validateReference)
})

#' The sender shared by the loadTrack methods
#'
#' @param session a shiny session object
#' @param id character string, the html element id of this widget instance
#' @param track an object of a Track subclass
#' @param handler character string, the igvShiny.js message handler
#' @param ext character string, the extension of the file the builder writes,
#' or NULL when it writes none
#' @param deleteTracksOfSameName logical
#' @param trackConfig a named list of additional igv.js track options
#' @param validateReference logical
#'
#' @return nothing
#'
#' @keywords internal
.sendTrack <- function(session, id, track, handler, ext,
                       deleteTracksOfSameName, trackConfig,
                       validateReference) {
  checkmate::assert_string(id)
  checkmate::assert_class(track, "Track")
  checkmate::assert_string(handler)
  checkmate::assert_string(ext, null.ok = TRUE)
  checkmate::assert_flag(deleteTracksOfSameName)
  checkmate::assert_flag(validateReference)

  trackName <- track@trackName
  flog.debug("--- igvShiny::loadTrack %s (%s)", trackName, class(track)[1])

  # the reference data is built before anything is sent, so a bad coreObject
  # fails without removing the track it was meant to replace
  refData <- .trackReferenceData(track)

  if (deleteTracksOfSameName) {
    removeTracksByName(session, id, trackName)
  }

  state[["userAddedTracks"]] <-
    unique(c(state[["userAddedTracks"]], trackName))

  # url tracks have nothing local to check, as with their url loaders
  if (!is.null(refData))
    .validateTrackReference(session, id, trackName, refData,
                            validateReference = validateReference)

  path <- if (is.null(ext)) NULL else .trackFile(session, ext)
  payload <- .trackPayload(track, path = path, trackConfig = trackConfig)
  # files written next to path (the bam index) go at session end too
  for (extra in setdiff(payload$files, path))
    .registerTrackFile(session, extra)

  session$sendCustomMessage(handler, c(list(elementID = id), payload$config))
  invisible(NULL)
} # .sendTrack

#-------------------------------------------------------------------------------
# M1 stage 4: the remaining igvR classes. Classes from suggested packages
# (GAlignments, VCF) cannot type a slot here, so those slots are "ANY" and a
# validity function checks the class; the constructors requireNamespace().
#-------------------------------------------------------------------------------

#' Build an annotation track from whatever annotation object is at hand
#'
#' @description igvR's \code{igvAnnotationTrack()} built a track that held no
#' data. Here it picks the subclass that fits \code{annotation}: a data.frame
#' gives a \code{DataFrameAnnotationTrack}, a \code{UCSCData} a
#' \code{UCSCBedAnnotationTrack} and any other \code{GRanges} a
#' \code{GRangesAnnotationTrack}.
#'
#' @param trackName A character string, used as track label by igv
#' @param annotation a data.frame, \code{GRanges} or \code{UCSCData}
#' @param ... further arguments of the subclass constructor, e.g. color,
#' displayMode, trackHeight
#'
#' @return an object of a subclass of \code{igvAnnotationTrack}
#'
#' @examples
#' tbl <- data.frame(chrom = "chr1", start = 100, end = 200,
#'                   stringsAsFactors = FALSE)
#' class(igvAnnotationTrack("demo", tbl))
#'
#' @keywords track_classes
#' @export
igvAnnotationTrack <- function(trackName, annotation, ...) {
  checkmate::assert_multi_class(annotation, c("data.frame", "GRanges"))
  if (is.data.frame(annotation))
    return(DataFrameAnnotationTrack(trackName, annotation, ...))
  if (is(annotation, "UCSCData"))
    return(UCSCBedAnnotationTrack(trackName, annotation, ...))
  GRangesAnnotationTrack(trackName, annotation, ...)
} # igvAnnotationTrack

#-------------------------------------------------------------------------------
#' Alignment tracks: in-memory reads, a bam url or a cram url
#'
#' @description \code{GenomicAlignmentTrack} holds a \code{GAlignments}
#' object (GenomicAlignments, written to a bam file at display time; needs the
#' suggested packages GenomicAlignments, rtracklayer and Rsamtools).
#' \code{RemoteAlignmentTrack} and \code{CramTrack} point igv.js at a served
#' bam or cram file and its index. Display them with \code{\link{loadTrack}};
#' color, height and visibilityWindow are sent to igv.js.
#'
#' @slot alignment a \code{GAlignments} object
#' @slot bamUrl character, url of the bam file
#' @slot bamIndex character, url of its index
#' @slot cramUrl character, url of the cram file
#' @slot indexUrl character, url of its crai index
#'
#' @param trackName A character string, used as track label by igv
#' @param alignment a \code{GAlignments} object
#' @param bamUrl url of a bam file
#' @param bamIndex url of its index; by default \code{bamUrl} with ".bai"
#' appended
#' @param cramUrl url of a cram file
#' @param indexUrl url of its crai index
#' @param trackHeight track height in pixels
#' @param visibilityWindow Maximum window size in base pairs for which reads
#' are displayed
#' @param color A CSS color name (e.g., "red" or "#FF0000"), or "random"
#'
#' @return An object of the named class
#'
#' @examples
#' track <- CramTrack("cram demo", "https://example.com/reads.cram",
#'                    "https://example.com/reads.cram.crai")
#' trackInfo(track)
#'
#' @keywords track_classes
#' @name GenomicAlignmentTrack-class
#' @rdname GenomicAlignmentTrack-class
#' @aliases RemoteAlignmentTrack-class CramTrack-class
#' @exportClass GenomicAlignmentTrack
.GenomicAlignmentTrack <- setClass(
  "GenomicAlignmentTrack",
  contains = "Track",
  slots = c(alignment = "ANY"),
  validity = function(object) {
    if (is(object@alignment, "GAlignments")) TRUE else
      "alignment must be a GAlignments object (GenomicAlignments)"
  }
)

#' @rdname GenomicAlignmentTrack-class
#' @exportClass RemoteAlignmentTrack
.RemoteAlignmentTrack <- setClass(
  "RemoteAlignmentTrack",
  contains = "Track",
  slots = c(bamUrl = "character", bamIndex = "character")
)

#' @rdname GenomicAlignmentTrack-class
#' @exportClass CramTrack
.CramTrack <- setClass(
  "CramTrack",
  contains = "Track",
  slots = c(cramUrl = "character", indexUrl = "character")
)

# The Track part the three alignment constructors share.
.alignmentTrackBase <- function(trackName, trackType, fileFormat, sourceType,
                                trackHeight, visibilityWindow, color) {
  Track(
    trackType = trackType,
    sourceType = sourceType,
    fileFormat = fileFormat,
    trackName = trackName,
    onScreenOrder = 1,
    color = color,
    height = trackHeight,
    visibilityWindow = visibilityWindow
  )
} # .alignmentTrackBase

#' @rdname GenomicAlignmentTrack-class
#' @export
GenomicAlignmentTrack <- function(trackName,
                                  alignment,
                                  trackHeight = 50,
                                  visibilityWindow = 30000,
                                  color = "gray") {
  if (!requireNamespace("GenomicAlignments", quietly = TRUE))
    stop("GenomicAlignmentTrack needs the GenomicAlignments package")
  checkmate::assert_class(alignment, "GAlignments")

  base <- .alignmentTrackBase(trackName, "genomicAlignment", "bam", "file",
                              trackHeight, visibilityWindow, color)
  .GenomicAlignmentTrack(base, alignment = alignment)
} # GenomicAlignmentTrack

#' @rdname GenomicAlignmentTrack-class
#' @export
RemoteAlignmentTrack <- function(trackName,
                                 bamUrl,
                                 bamIndex = paste0(bamUrl, ".bai"),
                                 trackHeight = 50,
                                 visibilityWindow = 30000,
                                 color = "gray") {
  checkmate::assert_string(bamUrl, min.chars = 1L)
  checkmate::assert_string(bamIndex, min.chars = 1L)

  base <- .alignmentTrackBase(trackName, "remoteAlignment", "bam", "url",
                              trackHeight, visibilityWindow, color)
  .RemoteAlignmentTrack(base, bamUrl = bamUrl, bamIndex = bamIndex)
} # RemoteAlignmentTrack

#' @rdname GenomicAlignmentTrack-class
#' @export
CramTrack <- function(trackName,
                      cramUrl,
                      indexUrl,
                      trackHeight = 50,
                      visibilityWindow = 30000,
                      color = "gray") {
  checkmate::assert_string(cramUrl, min.chars = 1L)
  checkmate::assert_string(indexUrl, min.chars = 1L)

  base <- .alignmentTrackBase(trackName, "alignment", "cram", "url",
                              trackHeight, visibilityWindow, color)
  .CramTrack(base, cramUrl = cramUrl, indexUrl = indexUrl)
} # CramTrack

#-------------------------------------------------------------------------------
#' VariantTrack: variants from a VariantAnnotation VCF object
#'
#' @description A \code{VariantTrack} holds a \code{VCF} object (needs the
#' suggested package VariantAnnotation), written to a vcf file at display
#' time, or the urls of a served vcf and its index. Display it with
#' \code{\link{loadTrack}}; color (from \code{anchorColor}) and the three
#' genotype colors are sent to igv.js. Url tracks have no igvShiny browser
#' handler yet, so \code{loadTrack} refuses them.
#'
#' @slot displayMode character, "COLLAPSED", "SQUISHED" or "EXPANDED"
#' @slot vcf.obj a \code{VCF} object, or NULL for a url track
#' @slot vcf.url list with the urls \code{data} and \code{index}, or empty
#' @slot anchorColor character, the variant color
#' @slot homvarColor character, homozygous variant genotype color
#' @slot hetvarColor character, heterozygous variant genotype color
#' @slot homrefColor character, homozygous reference genotype color
#'
#' @param trackName A character string, used as track label by igv
#' @param vcf a \code{VCF} object, or a list with the urls \code{data} and
#' \code{index}
#' @param trackHeight track height in pixels
#' @param anchorColor CSS color of the variant row
#' @param homvarColor CSS color of homozygous variant genotypes
#' @param hetvarColor CSS color of heterozygous variant genotypes
#' @param homrefColor CSS color of homozygous reference genotypes
#' @param displayMode "COLLAPSED", "SQUISHED" or "EXPANDED"
#' @param visibilityWindow Maximum window size in base pairs for which
#' variants are displayed
#'
#' @return An object of class VariantTrack
#'
#' @examples
#' if (requireNamespace("VariantAnnotation", quietly = TRUE)) {
#'   f <- system.file(package = "igvShiny", "extdata",
#'                    "chr19-cebpaRegion.vcf.gz")
#'   vcf <- VariantAnnotation::readVcf(f, "hg38")
#'   track <- VariantTrack("cebpa variants", vcf)
#'   trackSize(track)
#' }
#'
#' @keywords track_classes
#' @name VariantTrack-class
#' @rdname VariantTrack-class
#' @exportClass VariantTrack
.VariantTrack <- setClass(
  "VariantTrack",
  contains = "Track",
  slots = c(
    displayMode = "character",
    vcf.obj = "ANY",
    vcf.url = "list",
    anchorColor = "character",
    homvarColor = "character",
    hetvarColor = "character",
    homrefColor = "character"
  ),
  validity = function(object) {
    if (is.null(object@vcf.obj) || is(object@vcf.obj, "VCF")) TRUE else
      "vcf.obj must be a VCF object (VariantAnnotation) or NULL"
  }
)

#' @rdname VariantTrack-class
#' @export
VariantTrack <- function(trackName,
                         vcf,
                         trackHeight = 50,
                         anchorColor = "pink",
                         homvarColor = "rgb(17,248,254)",
                         hetvarColor = "rgb(34,12,253)",
                         homrefColor = "rgb(200,200,200)",
                         displayMode = "EXPANDED",
                         visibilityWindow = 100000) {
  checkmate::assert_choice(displayMode,
                           c("COLLAPSED", "SQUISHED", "EXPANDED"))
  checkmate::assert_string(anchorColor)
  checkmate::assert_string(homvarColor)
  checkmate::assert_string(hetvarColor)
  checkmate::assert_string(homrefColor)

  vcf.obj <- NULL
  vcf.url <- list()
  if (is(vcf, "VCF")) {
    if (!requireNamespace("VariantAnnotation", quietly = TRUE))
      stop("VariantTrack needs the VariantAnnotation package")
    vcf.obj <- vcf
  } else if (is.list(vcf) && setequal(names(vcf), c("data", "index"))) {
    checkmate::assert_string(vcf$data, min.chars = 1L)
    checkmate::assert_string(vcf$index)
    vcf.url <- vcf
  } else {
    stop("vcf argument neither a VCF nor a list of data & index urls")
  }

  base <- Track(
    trackType = "variant",
    sourceType = if (is.null(vcf.obj)) "url" else "file",
    fileFormat = "vcf",
    trackName = trackName,
    onScreenOrder = 1,
    color = anchorColor,
    height = trackHeight,
    visibilityWindow = visibilityWindow
  )
  .VariantTrack(base,
                displayMode = displayMode,
                vcf.obj = vcf.obj,
                vcf.url = vcf.url,
                anchorColor = base@color,
                homvarColor = homvarColor,
                hetvarColor = hetvarColor,
                homrefColor = homrefColor)
} # VariantTrack

#-------------------------------------------------------------------------------
#' GFF3Track: gene models from a GFF3 data.frame or url
#'
#' @description A \code{GFF3Track} holds either a 9-column GFF3 table
#' (\code{tbl}), served as a file, or the url of a GFF3 file and optionally
#' its index. Features are colored by \code{trackColor}, or by the
#' \code{colorByAttribute} attribute through \code{colorTable}. Display it
#' with \code{\link{loadTrack}}.
#'
#' @slot tbl data.frame, the GFF3 table, or an empty data.frame
#' @slot url character, the GFF3 url, or NA
#' @slot indexURL character, the index url, or NA
#' @slot colorByAttribute character, a column 9 attribute, or NA
#' @slot colorTable list, attribute value to color; a "default" entry is
#' renamed "*", igv.js's fallback key
#'
#' @param trackName A character string, used as track label by igv
#' @param tbl.track a data.frame in standard 9-column GFF3 format
#' @param url url of a GFF3 file, used when \code{tbl.track} is empty
#' @param indexURL url of its index
#' @param trackColor A CSS color, used unless colorTable is given
#' @param colorByAttribute name of a GFF3 attribute in column 9, e.g. "biotype"
#' @param colorTable a named list mapping attribute values to colors
#' @param displayMode "COLLAPSED", "SQUISHED" or "EXPANDED"
#' @param trackHeight track height in pixels
#' @param visibilityWindow Maximum window size in base pairs for which
#' features are displayed
#'
#' @return An object of class GFF3Track
#'
#' @examples
#' f <- system.file(package = "igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
#' tbl <- utils::read.table(f, sep = "\t", header = FALSE, quote = "",
#'                          stringsAsFactors = FALSE)
#' track <- GFF3Track("NDUFS2", tbl, colorByAttribute = "biotype",
#'                    colorTable = list(protein_coding = "blue",
#'                                      default = "gray"))
#' trackSize(track)
#'
#' @keywords track_classes
#' @name GFF3Track-class
#' @rdname GFF3Track-class
#' @exportClass GFF3Track
.GFF3Track <- setClass(
  "GFF3Track",
  contains = "igvAnnotationTrack",
  slots = c(
    tbl = "data.frame",
    url = "character",
    indexURL = "character",
    colorByAttribute = "character",
    colorTable = "list"
  )
)

#' @rdname GFF3Track-class
#' @export
GFF3Track <- function(trackName,
                      tbl.track = data.frame(),
                      url = NA_character_,
                      indexURL = NA_character_,
                      trackColor = "black",
                      colorByAttribute = NA_character_,
                      colorTable = list(),
                      displayMode = "EXPANDED",
                      trackHeight = 50,
                      visibilityWindow = 100000) {
  checkmate::assert_class(tbl.track, "data.frame")
  checkmate::assert_string(url, na.ok = TRUE)
  checkmate::assert_string(indexURL, na.ok = TRUE)
  checkmate::assert_string(colorByAttribute, na.ok = TRUE)
  checkmate::assert_list(colorTable, names = "unique")
  checkmate::assert_choice(displayMode,
                           c("COLLAPSED", "SQUISHED", "EXPANDED"))
  if (NROW(tbl.track) == 0L && is.na(url))
    stop("GFF3Track needs a non-empty tbl.track or a url")
  if (NROW(tbl.track) > 0L && NCOL(tbl.track) != 9L)
    stop("GFF3Track: tbl.track must have the 9 GFF3 columns")

  if (length(colorTable) > 0L) {
    if (is.na(colorByAttribute) || nchar(colorByAttribute) < 3L)
      stop(sprintf(paste("GFF3Track error: colorTable provided, but",
                         "unusable 'colorByAttribute': %s"),
                   colorByAttribute))
    # igvR's version errored on a table without a default entry
    names(colorTable)[names(colorTable) == "default"] <- "*"
  }

  base <- .igvAnnotationTrack(
    Track(
      trackType = "annotation",
      sourceType = if (NROW(tbl.track) > 0L) "file" else "url",
      fileFormat = "gff3",
      trackName = trackName,
      color = trackColor,
      height = trackHeight,
      maxTrackHeight = 2000,
      visibilityWindow = visibilityWindow
    ),
    classTypeOfSuppliedObject = if (NROW(tbl.track) > 0L) "data.frame" else
      "character",
    displayMode = displayMode,
    expandedRowHeight = 30,
    squishedRowHeight = 15,
    maxRows = 500,
    searchable = FALSE
  )

  .GFF3Track(base,
             tbl = tbl.track,
             url = url,
             indexURL = indexURL,
             colorByAttribute = colorByAttribute,
             colorTable = colorTable)
} # GFF3Track

#-------------------------------------------------------------------------------
#' BedpeInteractionsTrack: paired-end interactions from a bedpe data.frame
#'
#' @description A \code{DataFrameAnnotationTrack} whose table is bedpe: chrom1,
#' start1, end1, chrom2, start2, end2 (0-based starts), optionally followed by
#' name and score. igv.js draws it as an "interact" track of arcs between the
#' two anchors. Display it with \code{\link{loadTrack}}; color and height are
#' sent to igv.js.
#'
#' @param trackName A character string, used as track label by igv
#' @param table a bedpe data.frame, at least 6 columns
#' @param color A CSS color name (e.g., "red" or "#FF0000"), or "random"
#' @param trackHeight track height in pixels
#' @param displayMode "COLLAPSED", "SQUISHED" or "EXPANDED"; stored, not sent
#' @param visibilityWindow Maximum window size in base pairs; stored, not sent
#'
#' @return An object of class BedpeInteractionsTrack
#'
#' @examples
#' f <- system.file(package = "igvShiny", "extdata", "sixColumn-demo1.bedpe")
#' tbl <- utils::read.table(f, sep = "\t", header = TRUE,
#'                          stringsAsFactors = FALSE)
#' track <- BedpeInteractionsTrack("interactions", tbl)
#' trackSize(track)
#'
#' @keywords track_classes
#' @name BedpeInteractionsTrack-class
#' @rdname BedpeInteractionsTrack-class
#' @exportClass BedpeInteractionsTrack
.BedpeInteractionsTrack <- setClass(
  "BedpeInteractionsTrack",
  contains = "DataFrameAnnotationTrack"
)

#' @rdname BedpeInteractionsTrack-class
#' @export
BedpeInteractionsTrack <- function(trackName,
                                   table,
                                   color = "darkBlue",
                                   trackHeight = 50,
                                   displayMode = "EXPANDED",
                                   visibilityWindow = 100000) {
  checkmate::assert_class(table, "data.frame")
  checkmate::assert_true(NCOL(table) >= 6L)
  for (column in c(2L, 3L, 5L, 6L))
    checkmate::assert_numeric(table[[column]],
                              .var.name = colnames(table)[column])

  obj <- .BedpeInteractionsTrack(
    DataFrameAnnotationTrack(trackName, table, color = color,
                             displayMode = displayMode,
                             trackHeight = trackHeight,
                             visibilityWindow = visibilityWindow)
  )
  obj@trackType <- "pairedEndAnnotation"
  obj@fileFormat <- "bedpe"
  obj
} # BedpeInteractionsTrack

#-------------------------------------------------------------------------------
#' @rdname trackInfo
setMethod("trackSize", "GenomicAlignmentTrack", function(obj) {
  length(obj@alignment)
})

#' @rdname trackInfo
setMethod("trackSize", "VariantTrack", function(obj) {
  if (is.null(obj@vcf.obj)) NA_integer_ else length(obj@vcf.obj)
})

#' @rdname trackInfo
setMethod("trackSize", "GFF3Track", function(obj) {
  if (NROW(obj@tbl) > 0L) NROW(obj@tbl) else NA_integer_
})

#-------------------------------------------------------------------------------
#' What loadTrack checks against the reference genome
#'
#' @description What \code{.validateTrackReference} gets for a track: the
#' feature table for the data.frame families, the Bioconductor object for
#' alignment and variant tracks, and NULL (nothing checked, as with the url
#' loaders) for tracks that only point at urls.
#'
#' @param track an object of a Track subclass
#'
#' @return a data.frame, a GAlignments or VCF object, or NULL
#'
#' @keywords internal
setGeneric(".trackReferenceData", signature = "track",
           function(track) standardGeneric(".trackReferenceData"))

setMethod(".trackReferenceData", "Track", function(track) .trackTable(track))

setMethod(".trackReferenceData", "GenomicAlignmentTrack",
          function(track) track@alignment)

setMethod(".trackReferenceData", "VariantTrack", function(track) {
  if (is.null(track@vcf.obj))
    stop("igvShiny: loadTrack cannot show a url VariantTrack yet; ",
         "only VCF objects have a browser handler")
  track@vcf.obj
})

setMethod(".trackReferenceData", "RemoteAlignmentTrack", function(track) NULL)
setMethod(".trackReferenceData", "CramTrack", function(track) NULL)
setMethod(".trackReferenceData", "GFF3Track", function(track) NULL)

# both anchors of every interaction, as one bed table
setMethod(".trackTable", "BedpeInteractionsTrack", function(track) {
  tbl <- track@coreObject
  data.frame(
    chr = as.character(c(tbl[[1]], tbl[[4]])),
    start = c(tbl[[2]], tbl[[5]]),
    end = c(tbl[[3]], tbl[[6]]),
    stringsAsFactors = FALSE
  )
})

#-------------------------------------------------------------------------------
# Builders of the stage 4 classes, each handing its slots to the loader
# builder in igvShiny.R. Slots are merged in as defaults, so trackConfig only
# adds keys, the same rule as the loaders.
#-------------------------------------------------------------------------------
setMethod(".trackPayload", "GenomicAlignmentTrack",
          function(track, path = NULL, trackConfig = list()) {
  options <- list(color = track@color,
                  visibilityWindow = track@visibilityWindow)
  trackConfig <- .sanitizeAndMergeOptions(options, trackConfig)
  .bamLocalDataTrackPayload(track@trackName, track@alignment, path,
                            trackHeight = track@height,
                            trackConfig = trackConfig)
})

setMethod(".trackPayload", "RemoteAlignmentTrack",
          function(track, path = NULL, trackConfig = list()) {
  options <- list(color = track@color,
                  visibilityWindow = track@visibilityWindow)
  trackConfig <- .sanitizeAndMergeOptions(options, trackConfig)
  .bamUrlTrackPayload(track@trackName, track@bamUrl, track@bamIndex,
                      trackHeight = track@height,
                      trackConfig = trackConfig)
})

setMethod(".trackPayload", "CramTrack",
          function(track, path = NULL, trackConfig = list()) {
  options <- list(color = track@color,
                  visibilityWindow = track@visibilityWindow)
  trackConfig <- .sanitizeAndMergeOptions(options, trackConfig)
  .cramUrlTrackPayload(track@trackName, track@cramUrl, track@indexUrl,
                       trackHeight = track@height,
                       trackConfig = trackConfig)
})

setMethod(".trackPayload", "VariantTrack",
          function(track, path = NULL, trackConfig = list()) {
  # displayMode, height and visibilityWindow are fixed by the loadVcfTrack
  # handler in igvShiny.js, so only the colors reach igv.js
  options <- list(color = track@anchorColor,
                  homvarColor = track@homvarColor,
                  hetvarColor = track@hetvarColor,
                  homrefColor = track@homrefColor)
  trackConfig <- .sanitizeAndMergeOptions(options, trackConfig)
  .vcfTrackPayload(track@trackName, .trackReferenceData(track), path,
                   trackConfig = trackConfig)
})

setMethod(".trackPayload", "GFF3Track",
          function(track, path = NULL, trackConfig = list()) {
  # the igvShiny.js handlers test the length of colorByAttribute and indexURL
  colorBy <- if (is.na(track@colorByAttribute)) "" else track@colorByAttribute
  if (NROW(track@tbl) > 0L) {
    return(.gff3TrackPayload(track@trackName, track@tbl, path,
                             color = track@color,
                             colorTable = track@colorTable,
                             colorByAttribute = colorBy,
                             displayMode = track@displayMode,
                             trackHeight = track@height,
                             visibilityWindow = track@visibilityWindow,
                             trackConfig = trackConfig))
  }
  .gff3UrlTrackPayload(track@trackName, track@url,
                       if (is.na(track@indexURL)) "" else track@indexURL,
                       color = track@color,
                       colorTable = track@colorTable,
                       colorByAttribute = colorBy,
                       displayMode = track@displayMode,
                       trackHeight = track@height,
                       visibilityWindow = track@visibilityWindow,
                       trackConfig = trackConfig)
})

setMethod(".trackPayload", "BedpeInteractionsTrack",
          function(track, path = NULL, trackConfig = list()) {
  .bedpeTrackPayload(track@trackName, track@coreObject, path,
                     color = track@color,
                     trackHeight = track@height,
                     trackConfig = trackConfig)
})

#-------------------------------------------------------------------------------
#' @rdname loadTrack
setMethod("loadTrack", "GenomicAlignmentTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  .sendTrack(session, id, track, "loadBamTrackFromLocalData", ".bam",
             deleteTracksOfSameName, trackConfig, validateReference)
})

#' @rdname loadTrack
setMethod("loadTrack", "RemoteAlignmentTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  .sendTrack(session, id, track, "loadBamTrackFromURL", NULL,
             deleteTracksOfSameName, trackConfig, validateReference)
})

#' @rdname loadTrack
setMethod("loadTrack", "CramTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  .sendTrack(session, id, track, "loadCramTrackFromURL", NULL,
             deleteTracksOfSameName, trackConfig, validateReference)
})

#' @rdname loadTrack
setMethod("loadTrack", "VariantTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  .sendTrack(session, id, track, "loadVcfTrack", ".vcf",
             deleteTracksOfSameName, trackConfig, validateReference)
})

#' @rdname loadTrack
setMethod("loadTrack", "GFF3Track",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  if (NROW(track@tbl) > 0L) {
    handler <- "loadGFF3TrackFromLocalData"
    ext <- ".gff3"
  } else {
    handler <- "loadGFF3TrackFromURL"
    ext <- NULL
  }
  .sendTrack(session, id, track, handler, ext,
             deleteTracksOfSameName, trackConfig, validateReference)
})

#' @rdname loadTrack
setMethod("loadTrack", "BedpeInteractionsTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE,
                   trackConfig = list(), validateReference = TRUE) {
  .sendTrack(session, id, track, "loadBedpeTrackFromFile", ".bedpe",
             deleteTracksOfSameName, trackConfig, validateReference)
})

# igvShiny's own GWASTrack is not a Track (see dev/m1-plan.md): loadTrack is
# display() under the M1 name, so both put the same message on the wire.
#' @rdname loadTrack
setMethod("loadTrack", "GWASTrack",
          function(session, id, track, deleteTracksOfSameName = TRUE) {
  display(track, session, id, deleteTracksOfSameName = deleteTracksOfSameName)
})
