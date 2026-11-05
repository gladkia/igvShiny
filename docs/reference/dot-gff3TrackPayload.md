# Build the payload of a GFF3 track from a data.frame

The browser-free half of `loadGFF3TrackFromLocalData`: writes the table,
header line included as before, to `path` and returns the message body
the `loadGFF3TrackFromLocalData` handler in igvShiny.js reads.

## Usage

``` r
.gff3TrackPayload(
  trackName,
  tbl.gff3,
  path,
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

- tbl.gff3:

  data.frame in standard 9-column GFF3 format

- path:

  character string, the file to write; its basename is what the browser
  fetches from the `tracks/` resource path

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
the paths written (here: `path`)
