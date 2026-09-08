# Serve a local file via HTTP Range Requests from the Shiny session

Registers a local file with the active Shiny session so that `igv.js`
can stream chunks of the file using HTTP 206 Partial Content requests.
This allows random-access binary formats (such as BAM, BAI, CRAM, CRAI,
BigWig, and Tabix-indexed files) of arbitrary size to be viewed in
`igvShiny` without loading them into R memory or copying them to
temporary directories.

## Usage

``` r
serveLocalFile(session, filePath)
```

## Arguments

- session:

  Shiny session object (must be an active Shiny session)

- filePath:

  character string, path to an existing, readable local file

## Value

A character string containing the relative URL to access the file from
the browser (e.g. `"session/<token>/dataobj/<filename>?..."`)

## Details

The returned URL is relative to the Shiny application root and is routed
through the same HTTP port as the Shiny session, ensuring compatibility
with Posit Connect, shinyapps.io, reverse proxies, and local
development.

## Examples

``` r
if (FALSE) { # \dontrun{
# Inside a Shiny server function:
server <- function(input, output, session) {
  bam_url <- serveLocalFile(session, "data/sample.bam")
  bai_url <- serveLocalFile(session, "data/sample.bam.bai")

  tracks <- list(
    list(
      name = "Sample BAM",
      type = "alignment",
      format = "bam",
      url = bam_url,
      indexURL = bai_url
    )
  )
  output$igv <- renderIgvShiny({
    igvShiny(genomeOptions, tracks = tracks)
  })
}
} # }
```
