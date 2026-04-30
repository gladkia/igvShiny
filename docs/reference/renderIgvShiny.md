# draw the igv genome browser element

This function is called in the server function of your shiny app

## Usage

``` r
renderIgvShiny(expr, env = parent.frame(), quoted = FALSE)
```

## Arguments

- expr:

  an expression that generates an HTML widget

- env:

  the environment in which to evaluate expr

- quoted:

  logical flag indicating if expr a quoted expression

## Value

an output or render function that enables the use of the widget within
Shiny applications

## Examples

``` r
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
