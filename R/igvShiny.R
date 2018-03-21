#----------------------------------------------------------------------------------------------------
igvShiny <- function(message, width = NULL, height = NULL, elementId = NULL)
{
  printf("--- ~/github/igvShiny/R/igvShiny ctor");
  x <- list(
    message = message
    )

  # create widget
  htmlwidgets::createWidget(
    name = 'igvShiny',
    x,
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

