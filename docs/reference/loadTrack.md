# Display a track object in an igvShiny widget

`loadTrack` is the one loader for every track class: it turns `track`
into a payload with the builder of its class and sends it to the
browser, removing an earlier track of the same name first. Annotation
tracks are served as a bed file, quantitative tracks travel inline,
exactly as with
[`loadBedTrack`](https://gladkia.github.io/igvShiny/reference/loadBedTrack.md)
and
[`loadBedGraphTrack`](https://gladkia.github.io/igvShiny/reference/loadGenomeAnnotationTrack.md).

`track` can also be a plain igv.js track configuration, a named list
with at least `name`, `url` and one of `type` or `format`. It loads any
track type igv.js reads from a url, e.g. a bigBed file, without a
dedicated loader. Keys igv.js does not read are dropped with a warning,
as with `trackConfig`; a `trackConfig` passed with a config list is
ignored with a logged warning.

## Usage

``` r
loadTrack(session, id, track, ...)

# S4 method for class 'Track'
loadTrack(session, id, track, ...)

# S4 method for class 'igvAnnotationTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'QuantitativeTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'GenomicAlignmentTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'RemoteAlignmentTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'CramTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'VariantTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'GFF3Track'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'BedpeInteractionsTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'GWASTrack'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)

# S4 method for class 'list'
loadTrack(
  session,
  id,
  track,
  deleteTracksOfSameName = TRUE,
  trackConfig = list(),
  validateReference = TRUE
)
```

## Arguments

- session:

  an environment or list, provided and managed by shiny

- id:

  character string, the html element id of this widget instance

- track:

  an object of a Track subclass, e.g.
  [`DataFrameAnnotationTrack`](https://gladkia.github.io/igvShiny/reference/igvAnnotationTrack-class.md)
  or
  [`GRangesQuantitativeTrack`](https://gladkia.github.io/igvShiny/reference/QuantitativeTrack-class.md),
  or a named list holding an igv.js track configuration

- ...:

  arguments of the methods: `deleteTracksOfSameName` (logical, default
  TRUE), `trackConfig` (a named list of additional igv.js track
  configuration options, merged onto the track's own) and
  `validateReference` (logical, default TRUE: check the track contigs
  and coordinates against the active reference genome)

- deleteTracksOfSameName:

  logical, default TRUE

- trackConfig:

  a named list of additional igv.js track configuration options

- validateReference:

  logical flag, default TRUE

## Value

nothing

## Examples

``` r
tbl <- data.frame(chrom = "chr1", start = c(100, 300), end = c(200, 400),
                  stringsAsFactors = FALSE)
track <- DataFrameAnnotationTrack("demo", tbl, color = "red")
if (interactive()) {
  # inside a shiny server function, with an igvShiny output "igvShiny_0":
  # loadTrack(session, "igvShiny_0", track)
}

# any igv.js track type from a url, here a bigBed file; nothing is
# fetched until the browser draws the track
bigBed <- list(name = "genes", type = "annotation", format = "bigBed",
               url = "https://example.org/genes.bb")
if (interactive()) {
  # loadTrack(session, "igvShiny_0", bigBed)
}
```
