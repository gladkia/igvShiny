# Merge track slot options over a user trackConfig

Drops NA slot values, then drops (with a warning) the trackConfig keys
the remaining slots set, so slot values win.

## Usage

``` r
.slotsOverConfig(slotOptions, trackConfig)
```

## Arguments

- slotOptions:

  named list of track options taken from slots

- trackConfig:

  named list of user track options

## Value

a named list, the slot options followed by the user options
