# igvShiny — GFF3 annotation tracks, from a local table and from a URL.
# colorTable and colorByAttribute have no defaults: omitting them fails inside
# the observer, where nothing surfaces the error to the browser.

library(shiny)
library(bslib)
library(igvShiny)

gff3.colors <- list(processed_transcript = "blue", protein_coding = "darkgreen",
                    retained_intron = "brown", nonsense_mediated_decay = "orange",
                    miRNA = "darkred", default = "black")
gff3.url <- "https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz"

ui <- page_sidebar(
  title = "igvShiny — GFF3 tracks",
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  fillable = TRUE,
  sidebar = sidebar(
    width = 280,
    actionButton("addLocalGFF3TrackButtonWithBiotypeColors", "GFF3 local (colors)",
                 class = "w-100 mb-2"),
    actionButton("addRemoteGFF3TrackButton", "GFF3 from URL", class = "w-100 mb-2"),
    actionButton("addRemoteGFF3TrackButtonWithBiotypeColors", "GFF3 from URL (colors)",
                 class = "w-100 mb-2")
  ),
  card(full_screen = TRUE,
       card_body(class = "p-0", igvShinyOutput("igvShiny_0", height = "100%")))
)

server <- function(input, output, session) {
  observeEvent(input$addLocalGFF3TrackButtonWithBiotypeColors, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:161,172,691-161,241,018")
    f <- system.file(package = "igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
    loadGFF3TrackFromLocalData(session, id = "igvShiny_0", trackName = "local gff3 (colors)",
                               tbl.gff3 = read.table(f, sep = "\t", as.is = TRUE, header = TRUE),
                               color = "brown", colorTable = gff3.colors, colorByAttribute = "biotype",
                               displayMode = "EXPANDED", trackHeight = 200, visibilityWindow = 80000)
  })
  observeEvent(input$addRemoteGFF3TrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "NDUFS2")
    loadGFF3TrackFromURL(session, id = "igvShiny_0", trackName = "url gff3",
                         gff3URL = gff3.url, indexURL = sprintf("%s.tbi", gff3.url),
                         color = "brown", colorTable = list(), colorByAttribute = NA_character_,
                         displayMode = "EXPANDED", trackHeight = 200, visibilityWindow = 50000)
  })
  observeEvent(input$addRemoteGFF3TrackButtonWithBiotypeColors, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:161,172,691-161,241,018")
    loadGFF3TrackFromURL(session, id = "igvShiny_0", trackName = "url gff3 (colors)",
                         gff3URL = gff3.url, indexURL = sprintf("%s.tbi", gff3.url),
                         color = "brown", colorTable = gff3.colors, colorByAttribute = "biotype",
                         displayMode = "EXPANDED", trackHeight = 200, visibilityWindow = 80000)
  })

  output$igvShiny_0 <- renderIgvShiny({
    igvShiny(parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "NDUFS2"))
  })
}

shinyApp(ui = ui, server = server)
