# igvShiny — GWAS tracks, both ways of building one.
#
# loadGwasTrack() takes a data.frame and guesses the columns; the GWASTrack S4
# class takes either a data.frame or a URL and is told the columns explicitly,
# which is what a table with non-standard headers needs. The genome-wide view
# ("all") is the point of a GWAS track, so the app opens there.

library(shiny)
library(bslib)
library(igvShiny)

f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
tbl.gwas <- get(load(f))

# a largish gwas table hosted remotely - some p-values are zero, which -log10
# turns into Inf, so this one is displayed on a fixed scale, not autoscaled
url.gwasTrack <- GWASTrack("remote url gwas",
                           "https://gladki.pl/igvShiny/gwas_sample.tsv.gz",
                           chrom.col = 3, pos.col = 4, pval.col = 10,
                           trackHeight = 100,
                           autoscale = FALSE, minY = 0, maxY = 300)

tbl.gwasTrack <- GWASTrack("data.frame gwas", tbl.gwas,
                           chrom.col = 3, pos.col = 4, pval.col = 10,
                           trackHeight = 100)

ui <- page_sidebar(
  title = "igvShiny — GWAS tracks",
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  fillable = TRUE,
  sidebar = sidebar(
    width = 280,
    actionButton("loadSimpleGwasTrackButton", "loadGwasTrack(data.frame)", class = "w-100 mb-2"),
    actionButton("loadLocalTableGwasTrackButton", "GWASTrack(data.frame)", class = "w-100 mb-2"),
    actionButton("loadRemoteUrlGwasTrackButton", "GWASTrack(url)", class = "w-100 mb-2"),
    hr(),
    actionButton("showApoeButton", "APOE region", class = "btn-outline-dark w-100 mb-2"),
    actionButton("showAllButton", "Whole genome", class = "btn-outline-dark w-100")
  ),
  card(full_screen = TRUE, card_body(class = "p-0",
                                     igvShinyOutput("igvShiny_0", height = "100%")))
)

server <- function(input, output, session) {

  observeEvent(input$loadSimpleGwasTrackButton, {
    loadGwasTrack(session, id = "igvShiny_0", trackName = "gwas", tbl.gwas = tbl.gwas,
                  deleteTracksOfSameName = FALSE)
  })

  observeEvent(input$loadLocalTableGwasTrackButton, {
    display(tbl.gwasTrack, session, id = "igvShiny_0")
  })

  observeEvent(input$loadRemoteUrlGwasTrackButton, {
    display(url.gwasTrack, session, id = "igvShiny_0")
  })

  observeEvent(input$showApoeButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr19:45,303,720-45,463,047")
  })

  observeEvent(input$showAllButton, {
    showGenomicRegion(session, id = "igvShiny_0", "all")
  })

  output$igvShiny_0 <- renderIgvShiny({
    igvShiny(parseAndValidateGenomeSpec(genomeName = "hg19", initialLocus = "all"))
  })
}

shinyApp(ui = ui, server = server)
