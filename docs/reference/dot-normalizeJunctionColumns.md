# Give a junction data.frame the chr/start/end column names and check them

Renames a "chrom" column to "chr" and fails when chr, start or end is
missing or of the wrong type.

## Usage

``` r
.normalizeJunctionColumns(tbl)
```

## Arguments

- tbl:

  data.frame, with at least "chrom" (or "chr") "start" "end" columns

## Value

the data.frame, its "chrom" column possibly renamed
