# Sanitize a list of startup track specifications

Sanitize a list of startup track specifications

## Usage

``` r
.sanitizeTracks(tracks)
```

## Arguments

- tracks:

  A list of named lists, each an igv.js track configuration.

## Value

A sanitized list of track configurations; invalid entries or keys are
dropped with a warning.
