# The sender shared by the loadTrack methods

The sender shared by the loadTrack methods

## Usage

``` r
.sendTrack(
  session,
  id,
  track,
  handler,
  ext,
  deleteTracksOfSameName,
  trackConfig,
  validateReference
)
```

## Arguments

- session:

  a shiny session object

- id:

  character string, the html element id of this widget instance

- track:

  an object of a Track subclass

- handler:

  character string, the igvShiny.js message handler

- ext:

  character string, the extension of the file the builder writes, or
  NULL when it writes none

- deleteTracksOfSameName:

  logical

- trackConfig:

  a named list of additional igv.js track options

- validateReference:

  logical

## Value

nothing
