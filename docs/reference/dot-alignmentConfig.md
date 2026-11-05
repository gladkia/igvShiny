# Slot options and display mode of a BAM alignment track

The BAM builders set `displayMode` themselves, with "EXPANDED" as
default, so a `displayMode` in trackConfig would be a conflict there and
get dropped. It goes to the builder argument instead; the remaining keys
are merged under the slot options once, by `.slotsOverConfig`, and
sanitized once, by the builder.

## Usage

``` r
.alignmentConfig(options, trackConfig)
```

## Arguments

- options:

  named list of slot options

- trackConfig:

  named list of user track options

## Value

a list with `displayMode` and `trackConfig`
