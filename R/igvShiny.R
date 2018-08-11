library(jsonlite)
#----------------------------------------------------------------------------------------------------
igvShiny <- function(options, width = NULL, height = NULL, elementId = NULL)
{
  supportedOptions <- c("genomeName", "initialLocus")
  stopifnot(all(supportedOptions %in% names(options)))
  supportedGenomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
  stopifnot(options$genomeName %in% supportedGenomes)

  printf("--- ~/github/igvShiny/R/igvShiny ctor");
  #x <- list(
  #  message = message
  #  )

  # create widget
  htmlwidgets::createWidget(
    name = 'igvShiny',
    options,
    width = width,
    height = height,
    package = 'igvShiny',
    elementId = elementId
    )

} # igvShiny constructor
#----------------------------------------------------------------------------------------------------
igvShinyOutput <- function(outputId, width = '100%', height = '400px')
{
  htmlwidgets::shinyWidgetOutput(outputId, 'igvShiny', width, height, package = 'igvShiny')
}
#----------------------------------------------------------------------------------------------------
renderIgvShiny <- function(expr, env = parent.frame(), quoted = FALSE)
{
   if (!quoted){
      expr <- substitute(expr)
      } # force quoted

  htmlwidgets::shinyRenderWidget(expr, igvShinyOutput, env, quoted = TRUE)

}
#----------------------------------------------------------------------------------------------------
loadBedTrack <- function(tbl)
{
   message <- list(tbl=jsonlite::toJSON(tbl))
   session <- shiny::getDefaultReactiveDomain()
   session$sendCustomMessage("loadBedTrack", message)

} # loadBedTrack
#------------------------------------------------------------------------------------------------------------------------

