# remove tracks from the browser

delete tracks on the browser

## Usage

``` r
removeTracksByName(session, id, trackNames)

# S4 method for class 'ANY'
removeTracksByName(session, id, trackNames)
```

## Arguments

- session:

  an environment or list, provided and managed by shiny

- id:

  character string, the html element id of this widget instance

- trackNames:

  a vector of character strings

## Value

nothing

## Details

An S4 generic dispatching on `session`; the default method (signature
`"ANY"`) sends the message through a shiny session.

## Examples

``` r
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
