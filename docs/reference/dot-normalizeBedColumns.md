# Give a bed-like data.frame the chr/start/end column names loaders expect

Renames a leading "chrom" column to "chr" and fails when the first three
columns are not chr, start and end.

## Usage

``` r
.normalizeBedColumns(tbl)
```

## Arguments

- tbl:

  data.frame, with at least "chrom" (or "chr") "start" "end" columns

## Value

the data.frame, its first column possibly renamed
