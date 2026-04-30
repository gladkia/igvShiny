# create the UI for the widget

This function is called in the ui function of your shiny app

## Usage

``` r
igvShinyOutput(outputId, width = "100%", height = NULL)
```

## Arguments

- outputId:

  a character string, specifies the html element id

- width:

  a character string, standard css notations, either e.g., "1000px" or
  "95%", "100%" by default

- height:

  a character string, needs to be an explicit pixel measure, e.g.,
  "800px", "400px" by default

## Value

the created widget's html

## Examples

``` r
io <- igvShinyOutput("igvOut")
```
