# Sanitize a list of startup track specifications

Sanitize a list of startup track specifications

## Usage

``` r
.sanitizeTracks(tracks, depth = 1L)
```

## Arguments

- tracks:

  A list of named lists, each an igv.js track configuration.

- depth:

  An integer, how deep this list sits in a merged track; 1 for the
  startup list itself.

## Value

A sanitized list of track configurations; invalid entries or keys are
dropped with a warning.
