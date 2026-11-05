# Track: the base class of igvShiny's S4 tracks

`Track` holds the slots every igv.js track shares. It is the parent of
[`igvAnnotationTrack`](https://gladkia.github.io/igvShiny/reference/igvAnnotationTrack-class.md)
and
[`QuantitativeTrack`](https://gladkia.github.io/igvShiny/reference/QuantitativeTrack-class.md);
build tracks with their subclass constructors, e.g.
[`DataFrameAnnotationTrack`](https://gladkia.github.io/igvShiny/reference/igvAnnotationTrack-class.md),
and display them with
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md).

## Usage

``` r
Track(
  trackType = c("annotation", "quantitative", "alignment", "variant", "gwas",
    "genomicAlignment", "remoteAlignment", "pairedEndAnnotation"),
  sourceType = c("file", "url", "gcs", "ga4gh"),
  fileFormat = c("bed", "gff", "gff3", "gtf", "wig", "bigWig", "bedGraph", "bam", "vcf",
    "seg", "gwas", "cram", "bedpe"),
  trackName,
  onScreenOrder = NA_real_,
  color = "gray",
  height = 50,
  autoTrackHeight = FALSE,
  minTrackHeight = 50,
  maxTrackHeight = 500,
  visibilityWindow = 1e+05
)
```

## Arguments

- trackType:

  One of "annotation", "quantitative", "alignment", "variant", "gwas",
  "genomicAlignment", "remoteAlignment", "pairedEndAnnotation"

- sourceType:

  One of "file", "url", "gcs", "ga4gh"

- fileFormat:

  One of "bed", "gff", "gff3", "gtf", "wig", "bigWig", "bedGraph",
  "bam", "vcf", "seg", "gwas", "cram", "bedpe"

- trackName:

  A character string, used as track label by igv; we recommend unique
  names per track

- onScreenOrder:

  Numeric, for explicit placement of track within the current set

- color:

  A CSS color name (e.g., "red" or "#FF0000"), or "random"

- height:

  track height in pixels

- autoTrackHeight:

  If TRUE, track height is adjusted dynamically, within the bounds set
  by minTrackHeight and maxTrackHeight

- minTrackHeight:

  In pixels, minimum allowed

- maxTrackHeight:

  In pixels, maximum allowed

- visibilityWindow:

  Maximum window size in base pairs for which indexed annotations or
  variants are displayed

## Value

An object of class Track

## Slots

- `trackType`:

  character, e.g. "annotation" or "quantitative"

- `sourceType`:

  character, e.g. "file" or "url"

- `fileFormat`:

  character, e.g. "bed" or "bedGraph"

- `trackName`:

  character, the track label

- `onScreenOrder`:

  numeric, explicit placement of the track

- `color`:

  character, a CSS color

- `height`:

  numeric, track height in pixels

- `autoTrackHeight`:

  logical; stored, not sent to igv.js yet

- `minTrackHeight`:

  numeric, pixels; stored, not sent to igv.js yet

- `maxTrackHeight`:

  numeric, pixels; stored, not sent to igv.js yet

- `visibilityWindow`:

  numeric, base pairs; sent to igv.js by the annotation and quantitative
  `loadTrack` methods (NA: not sent)

## References

<https://igv.org/doc/igvjs/#tracks/Tracks/>

## Examples

``` r
track <- Track(trackType = "annotation", sourceType = "file",
               fileFormat = "bed", trackName = "demo", color = "red")
trackInfo(track)
#> $trackType
#> [1] "annotation"
#> 
#> $fileFormat
#> [1] "bed"
#> 
#> $source
#> [1] "file"
#> 
#> $class
#> [1] "Track"
#> 
```
