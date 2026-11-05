# Build the payload of a track given as a plain igv.js track config

The browser-free half of `loadTrack(<list>)`. The config goes through
[`.sanitizeAndMergeOptions()`](https://gladkia.github.io/igvShiny/reference/dot-sanitizeAndMergeOptions.md)
like every loader's `trackConfig`: keys igv.js does not read are dropped
with a warning. The genotype colors are allowed for a variant track:
`type` `"variant"`, or no type and a vcf `format`, as igv.js infers it.

## Usage

``` r
.configListTrackPayload(track)
```

## Arguments

- track:

  a named list, an igv.js track configuration with at least `name`,
  `url` and one of `type` or `format`

## Value

list(config = the message body, files = character(0))
