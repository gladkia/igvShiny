# The BED columns 7-12 of a GRanges imported from BED12

rtracklayer keeps BED columns 7-12 as the metadata columns `thick`
(IRanges), `itemRgb` (character colors) and `blocks` (IRangesList,
positions relative to the feature start). Writing them back keeps the
exon structure of a transcript; without them igv.js draws one solid
feature. Missing columns get the BED defaults.

## Usage

``` r
.bed12Columns(gr, meta, tbl)
```

## Arguments

- gr:

  a GRanges

- meta:

  its metadata columns

- tbl:

  the BED6 table already built from `gr`

## Value

a data.frame with thickStart, thickEnd, itemRgb, blockCount, blockSizes,
blockStarts
