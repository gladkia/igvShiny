# the url of the gwas table

the url of the gwas table

## Usage

``` r
# S4 method for class 'GWASTrack'
getUrl(obj)
```

## Arguments

- obj:

  An object of class GWASTrack

## Value

character

## Examples

``` r
file <-
  # a local gwas file
  system.file(package = "igvShiny", "extdata", "gwas-5k.tsv.gz")
tbl.gwas <- read.table(file,
                       sep = "\t",
                       header = TRUE,
                       quote = "")
track <-
  GWASTrack(
    "gwas 5k",
    tbl.gwas,
    chrom.col = 12,
    pos.col = 13,
    pval.col = 28
  )
getUrl(track)
#> [1] "/tmp/RtmpJ0TnBe/tracks/file1e66193d5b35.gwas"
```
