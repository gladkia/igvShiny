# Build the payload of a GWASTrack object

The browser-free half of
[`display()`](https://gladkia.github.io/igvShiny/reference/display.md)
(and of
[`loadTrack()`](https://gladkia.github.io/igvShiny/reference/loadTrack.md)
for a GWASTrack): returns the message body the
`loadGwasTrackFlexibleSource` handler in igvShiny.js reads. The
constructor already wrote a data.frame to the tracks directory; a local
file is sent by its `tracks/` path. The builder writes nothing, so
`files` is empty.

## Usage

``` r
.gwasTrackObjectPayload(obj)
```

## Arguments

- obj:

  a GWASTrack object

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
