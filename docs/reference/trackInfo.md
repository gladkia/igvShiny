# Basic facts about a track

Basic facts about a track

## Usage

``` r
trackInfo(obj)

trackSize(obj)

# S4 method for class 'Track'
trackInfo(obj)

# S4 method for class 'Track'
trackSize(obj)

# S4 method for class 'GenomicAlignmentTrack'
trackSize(obj)

# S4 method for class 'VariantTrack'
trackSize(obj)

# S4 method for class 'GFF3Track'
trackSize(obj)
```

## Arguments

- obj:

  An object of base class Track

## Value

`trackInfo`: a list with trackType, fileFormat, source and class.
`trackSize`: the number of features, or `NA` when the track holds no
data of its own

## Examples

``` r
tbl <- data.frame(chrom = "chr1", start = c(100, 300), end = c(200, 400),
                  stringsAsFactors = FALSE)
track <- DataFrameAnnotationTrack("demo", tbl)
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
#> [1] "DataFrameAnnotationTrack"
#> 
trackSize(track)
#> [1] 2
```
