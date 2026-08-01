# igvShiny — inside a Shiny module. The widget takes its namespace from the
# session, so igvShinyOutput(ns("igv")) is all the UI needs. The catch is on the
# server side: loaders address the browser by its HTML element id, the
# namespaced ns("igv") and never "igv", while the region event comes back on the
# unnamespaced name, since it is named after the element inside the module.

library(shiny)
library(bslib)
library(igvShiny)

tbl.bed <- data.frame(chr = c("1", "1", "1"),
                      start = c(7432951, 7437000, 7438000),
                      end   = c(7436000, 7437500, 7440000),
                      value = c(-2.239, 3.0, 0.5),
                      sampleID = c("sample1", "sample2", "sample3"),
                      stringsAsFactors = FALSE)

igvModuleUI <- function(id) {
  ns <- NS(id)
  card(
    full_screen = TRUE,
    card_header(sprintf("module id: %s", id)),
    card_body(
      actionButton(ns("addTrack"), "Add BED track", class = "mb-2"),
      div(class = "small text-muted font-monospace", textOutput(ns("region"))),
      igvShinyOutput(ns("igv"), height = "400px")
    )
  )
}

igvModuleServer <- function(id, genomeOptions, tbl) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$igv <- renderIgvShiny(igvShiny(genomeOptions))

    observeEvent(input$addTrack, {
      loadBedTrack(session, id = ns("igv"), trackName = "regions", tbl = tbl,
                   color = "green")
    })

    # the region input keeps its unnamespaced name inside the module
    output$region <- renderText(input[["currentGenomicRegion.igv"]])
  })
}

ui <- page_fillable(
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  igvModuleUI("browserA")
)

server <- function(input, output, session) {
  options <- parseAndValidateGenomeSpec(genomeName = "hg38",
                                        initialLocus = "chr1:7,426,231-7,453,241")
  igvModuleServer("browserA", options, tbl.bed)
}

shinyApp(ui = ui, server = server)
