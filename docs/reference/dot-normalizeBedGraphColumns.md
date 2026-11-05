# Give a bedGraph-like data.frame the chr/start/end/value column names

Renames a leading "chrom" column to "chr" and the fourth column to
"value", then applies the chr/start/end check of `.normalizeBedColumns`.

## Usage

``` r
.normalizeBedGraphColumns(tbl)
```

## Arguments

- tbl:

  data.frame, with at least four columns: chrom (or chr), start, end and
  a numeric score

## Value

the data.frame, with its columns renamed
