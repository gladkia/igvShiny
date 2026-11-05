# Alignment tracks: in-memory reads, a bam url or a cram url

`GenomicAlignmentTrack` holds a `GAlignments` object (GenomicAlignments,
written to a bam file at display time; needs the suggested packages
GenomicAlignments, rtracklayer and Rsamtools). `RemoteAlignmentTrack`
and `CramTrack` point igv.js at a served bam or cram file and its index.
Display them with
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md);
color, height and visibilityWindow are sent to igv.js.

## Usage

``` r
GenomicAlignmentTrack(
  trackName,
  alignment,
  trackHeight = 50,
  visibilityWindow = 30000,
  color = "gray"
)

RemoteAlignmentTrack(
  trackName,
  bamUrl,
  bamIndex = paste0(bamUrl, ".bai"),
  trackHeight = 50,
  visibilityWindow = 30000,
  color = "gray"
)

CramTrack(
  trackName,
  cramUrl,
  indexUrl,
  trackHeight = 50,
  visibilityWindow = 30000,
  color = "gray"
)
```

## Arguments

- trackName:

  A character string, used as track label by igv

- alignment:

  a `GAlignments` object

- trackHeight:

  track height in pixels

- visibilityWindow:

  Maximum window size in base pairs for which reads are displayed

- color:

  A CSS color name (e.g., "red" or "#FF0000"), or "random"

- bamUrl:

  url of a bam file

- bamIndex:

  url of its index; by default `bamUrl` with ".bai" appended

- cramUrl:

  url of a cram file

- indexUrl:

  url of its crai index

## Value

An object of the named class

## Slots

- `alignment`:

  a `GAlignments` object

- `bamUrl`:

  character, url of the bam file

- `bamIndex`:

  character, url of its index

- `cramUrl`:

  character, url of the cram file

- `indexUrl`:

  character, url of its crai index

## Examples

``` r
track <- CramTrack("cram demo", "https://example.com/reads.cram",
                   "https://example.com/reads.cram.crai")
trackInfo(track)
#> $trackType
#> [1] "alignment"
#> 
#> $fileFormat
#> [1] "cram"
#> 
#> $source
#> [1] "url"
#> 
#> $class
#> [1] "CramTrack"
#> 
```
