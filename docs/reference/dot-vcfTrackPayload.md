# Build the payload of a VCF track from a VariantAnnotation object

The browser-free half of `loadVcfTrack`: writes `vcfData` to `path` with
[`VariantAnnotation::writeVcf`](https://rdrr.io/pkg/VariantAnnotation/man/writeVcf-methods.html)
and returns the message body the `loadVcfTrack` handler in igvShiny.js
reads. Needs VariantAnnotation (Suggests).

## Usage

``` r
.vcfTrackPayload(trackName, vcfData, path, trackConfig = list())
```

## Arguments

- trackName:

  character string

- vcfData:

  a `VCF` object from VariantAnnotation

- path:

  character string, the file to write; its basename is what the browser
  fetches from the `tracks/` resource path

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
the paths written (here: `path`)
