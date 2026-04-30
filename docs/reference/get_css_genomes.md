# get_css_genomes

a helper function for mostly internal use, obtains the genome codes
(e.g. 'hg38') supported by igv.js

## Usage

``` r
get_css_genomes(test = FALSE)
```

## Arguments

- test:

  logical(1) defaults to FALSE

## Value

an list of short genome codes, e.g., "hg38", "dm6", "tair10"

## Examples

``` r
css <- get_css_genomes(test = TRUE)
```
