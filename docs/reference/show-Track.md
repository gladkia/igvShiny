# Print a summary of a track object

One method for the whole
[`Track`](https://gladkia.github.io/igvShiny/reference/Track-class.md)
hierarchy: class, name, type, format, source and, when the track holds
data, its size.

## Usage

``` r
# S4 method for class 'Track'
show(object)
```

## Arguments

- object:

  a `Track`

## Value

nothing; called for the side effect of printing a summary

## Examples

``` r
DataFrameAnnotationTrack("demo",
  data.frame(chr = "chr1", start = 10, end = 20))
#> DataFrameAnnotationTrack 'demo'
#>   type:   annotation
#>   format: bed
#>   source: file
#>   size:   1
```
