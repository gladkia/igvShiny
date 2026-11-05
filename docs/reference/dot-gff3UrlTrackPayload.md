# Build the payload of a GFF3 track read by url

The browser-free half of `loadGFF3TrackFromURL`: returns the message
body the `loadGFF3TrackFromURL` handler in igvShiny.js reads. Nothing is
written, so `files` is empty. Like the loader, it has no defaults for
the colour, display and window arguments.

## Usage

``` r
.gff3UrlTrackPayload(
  trackName,
  gff3URL,
  indexURL,
  color = "gray",
  colorTable,
  colorByAttribute,
  displayMode,
  trackHeight = 50,
  visibilityWindow,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- gff3URL:

  character string, url of the gff3 file

- indexURL:

  character string, url of its index

- color:

  character \#RGB or a recognized color name. ignored if colorTable and
  colorByAttribute provided

- colorTable:

  list, mapping a gff3 attribute, typically biotype, to a color

- colorByAttribute:

  character, name of a gff3 attribute in column 9, typically "biotype"

- displayMode:

  character, "EXPANDED", "SQUISHED" or "COLLAPSED"

- trackHeight:

  numeric defaults to 50

- visibilityWindow:

  numeric, Maximum window size in base pairs for which indexed
  annotations or variants are displayed

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
