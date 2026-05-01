# Constructor for GWASTrack

`GWASTrack` creates an `IGV` manhattan track from GWAS data

## Usage

``` r
GWASTrack(
  trackName,
  data,
  chrom.col,
  pos.col,
  pval.col,
  trackHeight = 50,
  autoscale = TRUE,
  minY = 0,
  maxY = 30
)
```

## Arguments

- trackName:

  A character string, used as track label by igv, we recommend unique
  names per track.

- data:

  a data.frame or a url pointing to one, whose structure is described by
  chrom.col, pos.col, pval.col

- chrom.col:

  numeric, the column number of the chromosome column

- pos.col:

  numeric, the column number of the position column

- pval.col:

  numeric, the column number of the GWAS pvalue column

- trackHeight:

  numeric in pixels

- autoscale:

  logical

- minY:

  numeric for explicit (non-auto) scaling

- maxY:

  numeric for explicit (non-auto) scaling

## Value

A GWASTrack object

## Examples

``` r
file <-
  # a local gwas file
  system.file(package = "igvShiny", "extdata", "gwas-5k.tsv.gz")
tbl.gwas <- read.table(file,
                       sep = "\t",
                       header = TRUE,
                       quote = "")
dim(tbl.gwas)
#> [1] 4949   34
track <-
  GWASTrack(
    "gwas 5k",
    tbl.gwas,
    chrom.col = 12,
    pos.col = 13,
    pval.col = 28
  )
getUrl(track)
#> [1] "/tmp/RtmpiPWPX8/tracks/file128e6cf0693b.gwas"

url <- "https://gladki.pl/igvShiny/gwas_sample.tsv.gz"
track <- GWASTrack(
  "remote url gwas",
  url,
  chrom.col = 3,
  pos.col = 4,
  pval.col = 10,
  autoscale = FALSE,
  minY = 0,
  maxY = 300,
  trackHeight = 100
)
getUrl(track)
#> [1] "https://gladki.pl/igvShiny/gwas_sample.tsv.gz"

```
