# Build an annotation track from whatever annotation object is at hand

igvR's `igvAnnotationTrack()` built a track that held no data. Here it
picks the subclass that fits `annotation`: a data.frame gives a
`DataFrameAnnotationTrack`, a `UCSCData` a `UCSCBedAnnotationTrack` and
any other `GRanges` a `GRangesAnnotationTrack`.

## Usage

``` r
igvAnnotationTrack(trackName, annotation, ...)
```

## Arguments

- trackName:

  A character string, used as track label by igv

- annotation:

  a data.frame, `GRanges` or `UCSCData`

- ...:

  further arguments of the subclass constructor, e.g. color,
  displayMode, trackHeight

## Value

an object of a subclass of `igvAnnotationTrack`

## Examples

``` r
tbl <- data.frame(chrom = "chr1", start = 100, end = 200,
                  stringsAsFactors = FALSE)
class(igvAnnotationTrack("demo", tbl))
#> [1] "DataFrameAnnotationTrack"
#> attr(,"package")
#> [1] "igvShiny"
```
