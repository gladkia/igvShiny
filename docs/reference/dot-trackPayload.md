# Build the payload of a track object

The builder half of
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md):
hands the slots of `track` to the data.frame builder of its family
(`.bedTrackPayload` for annotation tracks, `.bedGraphTrackPayload` for
quantitative tracks) and returns its `list(config, files)`. It touches
no session; a builder that writes a file writes it to `path`.

## Usage

``` r
.trackPayload(track, path = NULL, trackConfig = list())
```

## Arguments

- track:

  an object of a Track subclass

- path:

  character string, the file to write, or NULL for builders that write
  none

- trackConfig:

  a named list of additional igv.js track configuration options; slot
  values win over it

## Value

a list with `config`, the message body without `elementID`, and `files`,
the paths written
