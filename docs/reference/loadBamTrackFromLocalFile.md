# Load a BAM Track from a Local File via HTTP Range Requests

Streams a local BAM file and its index directly from disk using HTTP 206
Partial Content requests handled by the Shiny session. This allows
viewing multi-gigabyte BAM files without loading them into R memory.

## Usage

``` r
loadBamTrackFromLocalFile(
  session,
  id,
  trackName,
  bamFile,
  indexFile = paste0(bamFile, ".bai"),
  deleteTracksOfSameName = TRUE,
  displayMode = "EXPANDED",
  trackConfig = list()
)
```

## Arguments

- session:

  an environment or list, provided and managed by shiny (ShinySession)

- id:

  character string, the html element id of this widget instance

- trackName:

  character string, display name for the track

- bamFile:

  character string, path to an existing, readable .bam file

- indexFile:

  character string, path to the corresponding .bai index file (default:
  `paste0(bamFile, ".bai")`)

- deleteTracksOfSameName:

  logical, whether to delete any existing track with the same name
  (default: TRUE)

- displayMode:

  character string, display mode for alignments ("EXPANDED",
  "COLLAPSED", or "SQUISHED"), default "EXPANDED"

- trackConfig:

  list, additional track options passed to igv.js

## Value

None, sends a message to the browser

## Examples

``` r
if (FALSE) { # \dontrun{
# Inside a Shiny server function:
bamFile <- system.file(package = "igvShiny", "extdata",
                       "A_2_A24_02_01_01.nanopore.minimap.sorted.bam")
baiFile <- paste0(bamFile, ".bai")
loadBamTrackFromLocalFile(session, "igvShiny_0", "Nanopore Reads",
                         bamFile, baiFile, displayMode = "SQUISHED")
} # }
```
