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
  chromosomeColorMap = list(),
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

- chromosomeColorMap:

  a named list or character vector mapping chromosome names, as they are
  spelled in the data, to colors, e.g.
  `list("1" = "red", "2" = "blue")`. A `"*"` entry colors every
  chromosome not named explicitly. Empty by default, which leaves the
  igv.js chromosome palette in place

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
#> [1] "/tmp/RtmpjHrTio/tracks/file17565a77cf62.gwas"

# a remote gwas file: the constructor checks that the url resolves, so this
# block reaches the network and stays out of R CMD check
# \donttest{
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
# }

# colors picked per chromosome, with "*" covering the rest
track <- GWASTrack(
  "gwas 5k, custom colors",
  tbl.gwas,
  chrom.col = 12,
  pos.col = 13,
  pval.col = 28,
  chromosomeColorMap = list("1" = "red", "2" = "blue", "*" = "gray")
)

```
