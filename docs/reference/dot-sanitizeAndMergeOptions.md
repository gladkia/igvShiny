# Sanitize and merge track configuration options

Sanitize and merge track configuration options

## Usage

``` r
.sanitizeAndMergeOptions(
  baseOptions,
  userOptions,
  allowed = .validIgvTrackOptions
)
```

## Arguments

- baseOptions:

  A list of default options set by the R function.

- userOptions:

  A list of options provided by the user via trackConfig.

- allowed:

  character, the option names igv.js reads for this kind of track;
  defaults to the global allowlist

## Value

A merged and sanitized list of options ready to be sent to JavaScript.
