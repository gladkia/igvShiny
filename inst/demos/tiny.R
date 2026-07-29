# igvShiny — the smallest app there is: a genome, a widget, nothing else.

library(shiny)
library(igvShiny)

options <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "NDUFS2")

ui <- fluidPage(igvShinyOutput("igvShiny"))

server <- function(input, output, session) {
  output$igvShiny <- renderIgvShiny(igvShiny(options))
}

shinyApp(ui = ui, server = server)
