# igvShiny — two browsers on one page.
#
# Each widget is addressed by its own element id, and each reports its own
# region: the currentGenomicRegion.<id> event carries the id it came from, so
# two widgets sitting at the same locus both report it (#126).

library(shiny)
library(bslib)
library(igvShiny)

tbl.bed <- data.frame(chr = c("1", "1", "1"),
                      start = c(7432951, 7437000, 7438000),
                      end   = c(7436000, 7437500, 7440000),
                      value = c(-2.239, 3.0, 0.5),
                      sampleID = c("sample1", "sample2", "sample3"),
                      stringsAsFactors = FALSE)

browserCard <- function(id, label) {
  card(
    card_header(label,
                tags$span(class = "small text-muted font-monospace ms-2",
                          textOutput(sprintf("region_%s", id), inline = TRUE))),
    card_body(class = "p-0", igvShinyOutput(id, height = "320px"))
  )
}

ui <- page_fillable(
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  layout_columns(
    col_widths = 12,
    div(class = "d-flex gap-2",
        actionButton("addTracks", "Add a BED track to both", class = "btn-primary"),
        actionButton("moveBoth", "Send both to MEF2C", class = "btn-outline-primary")),
    browserCard("igvShiny_0", "browser 0 — hg38"),
    browserCard("igvShiny_1", "browser 1 — hg38")
  )
)

server <- function(input, output, session) {
  ids <- c("igvShiny_0", "igvShiny_1")

  observeEvent(input$addTracks, {
    for (id in ids)
      loadBedTrack(session, id = id, trackName = "bed", tbl = tbl.bed, color = "green")
  })

  observeEvent(input$moveBoth, {
    for (id in ids) showGenomicRegion(session, id = id, "MEF2C")
  })

  for (id in ids) local({
    this.id <- id
    output[[sprintf("region_%s", this.id)]] <- renderText(
      input[[sprintf("currentGenomicRegion.%s", this.id)]])
  })

  options <- parseAndValidateGenomeSpec(genomeName = "hg38",
                                        initialLocus = "chr1:7,426,231-7,453,241")
  output$igvShiny_0 <- renderIgvShiny(igvShiny(options))
  output$igvShiny_1 <- renderIgvShiny(igvShiny(options))
}

shinyApp(ui = ui, server = server)
