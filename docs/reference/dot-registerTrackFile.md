# Have a path removed when the session ends

The companion of `.trackFile`, for the files a loader does not name
itself: `rtracklayer::export(format = "BAM")` writes an index next to
the bam it was given, and that index is served and leaks the same way.
The path need not exist yet, or ever -
[`unlink()`](https://rdrr.io/r/base/unlink.html) does not mind.

## Usage

``` r
.registerTrackFile(session, path)
```

## Arguments

- session:

  a shiny session object

- path:

  character string, the path to remove when the session ends

## Value

the path, unchanged
