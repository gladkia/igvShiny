# igvShiny — splice junctions held in R, written as the bed igv.js reads.
#
# One row per junction, attributes in their own columns; the loader packs them
# into the bed name field igv.js filters and labels on. Coordinates are bed
# coordinates already, read off the converted bed igvteam ships as a test case
# (data/test/splice_junctions in igvteam/igv-data).

library(shiny)
library(bslib)
library(igvShiny)

junctions <- data.frame(
  chrom = "chr15",
  start = c(92883186, 92883186, 92883778, 92885584, 92886254, 92892072),
  end = c(92883584, 92885514, 92885514, 92886168, 92892003, 92897723),
  motif = "GT/AG",
  uniquely_mapped = c(56, 222, 95, 555, 415, 1202),
  multi_mapped = c(2, 9, 10, 11, 13, 10),
  maximum_spliced_alignment_overhang = c(35, 37, 38, 37, 37, 38),
  annotated_junction = TRUE,
  strand = "+",
  stringsAsFactors = FALSE
)

ui <- page_sidebar(
  title = "igvShiny — splice junctions",
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  fillable = TRUE,
  sidebar = sidebar(
    width = 280,
    actionButton("addLocalJunctionsButton", "Splice junctions (data.frame)",
                 class = "w-100 mb-2"),
    actionButton("removeUserTracksButton", "Remove user tracks",
                 class = "btn-outline-danger w-100")
  ),
  card(full_screen = TRUE,
       card_body(class = "p-0", igvShinyOutput("igvShiny_0", height = "100%")))
)

server <- function(input, output, session) {
  observeEvent(input$addLocalJunctionsButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr15:92,880,000-92,900,000")
    loadSpliceJunctionTrackFromLocalData(
      session, id = "igvShiny_0", trackName = "sampleA junctions",
      tbl = junctions, trackHeight = 150,
      trackConfig = list(colorBy = "motif", labelWith = "uniqueReadCount"))
  })

  observeEvent(input$removeUserTracksButton,
               removeUserAddedTracks(session, id = "igvShiny_0"))

  output$igvShiny_0 <- renderIgvShiny({
    igvShiny(parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "NDUFS2"))
  })
}

shinyApp(ui = ui, server = server)
