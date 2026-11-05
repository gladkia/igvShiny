# A track's features as the data.frame its payload builder takes

Annotation tracks give a bed table (chr, start, end, and for GRanges
name, score, strand), quantitative tracks a bedGraph table (chr, start,
end, value). GRanges starts are 1-based and become 0-based here.

## Usage

``` r
.trackTable(track)
```

## Arguments

- track:

  an object of a Track subclass with a coreObject slot

## Value

a data.frame
