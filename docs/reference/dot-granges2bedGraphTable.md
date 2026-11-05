# GRanges with one numeric metadata column to a bedGraph data.frame

GRanges with one numeric metadata column to a bedGraph data.frame

## Usage

``` r
.granges2bedGraphTable(gr)
```

## Arguments

- gr:

  a GRanges (or UCSCData) with exactly one numeric metadata column

## Value

a data.frame with chr, start (0-based), end, value
