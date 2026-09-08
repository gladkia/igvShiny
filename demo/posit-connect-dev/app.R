# igvShiny — Dev demo on Posit Connect Cloud: Custom Genome & Local BAM Streaming.
#
# Runs inst/demos/custom-genome-bam.R out of the installed package.
# Demonstrates custom non-stock reference genome (HLA-A*24:02:01:01)
# and streaming of local BAM and BAI alignment files directly from disk
# via HTTP 206 Partial Content range requests.

library(igvShiny)

app.file <- system.file("demos", "custom-genome-bam.R", package = "igvShiny")
if (!nzchar(app.file))
  stop(sprintf("igvShiny %s ships no demos/custom-genome-bam.R - bump the pinned SHA in manifest.json",
               utils::packageVersion("igvShiny")))

shiny::shinyAppFile(app.file)
