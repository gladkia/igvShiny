# Display a short summary of a GWASTrack object

Display a short summary of a GWASTrack object

## Usage

``` r
# S4 method for class 'GWASTrack'
show(object)
```

## Arguments

- object:

  An object of class GWASTrack

## Value

nothing; called for the side effect of printing a summary

## Examples

``` r
file <-
  system.file(package = "igvShiny", "extdata", "gwas-5k.tsv.gz")
tbl.gwas <- read.table(file, sep = "\t", header = TRUE, quote = "")
track <-
  GWASTrack("gwas 5k", tbl.gwas, chrom.col = 12, pos.col = 13, pval.col = 28)
track
#> GWASTrack object
#>   trackName:  gwas 5k
#>   dataMode:   local.url
#>   url:        /tmp/Rtmp53gor2/tracks/file11582d9292b0.gwas
#>   columns:    chrom=12 pos=13 pval=28
#>   trackHeight: 50 
#>   autoscale:  TRUE
```
