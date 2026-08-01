# igvShiny — alignments and variants that are already in R: the *FromLocalData
# loaders write a file into the tracks directory and have shiny serve it, so
# unlike the URL loaders they need the parsing package on the server side.
# Loaded on click, not at startup: a missing suggested package should grey out
# one button rather than the whole app. Junctions are in junctions.R, GFF3 in
# gff3.R.

library(shiny)
library(bslib)
library(igvShiny)

needs <- function(pkg) {
  ok <- requireNamespace(pkg, quietly = TRUE)
  if (!ok) showNotification(sprintf("install %s to use this button", pkg),
                            type = "error")
  ok
}

ui <- page_sidebar(
  title = "igvShiny — tracks from local data",
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  fillable = TRUE,
  sidebar = sidebar(
    width = 280,
    actionButton("addLocalBamButton", "BAM (readGAlignments)", class = "w-100 mb-2"),
    actionButton("addLocalVcfButton", "VCF (readVcf)", class = "w-100 mb-2"),
    actionButton("removeUserTracksButton", "Remove user tracks",
                 class = "btn-outline-danger w-100")
  ),
  card(full_screen = TRUE,
       card_body(class = "p-0", igvShinyOutput("igvShiny_0", height = "100%")))
)

server <- function(input, output, session) {
  observeEvent(input$addLocalBamButton, {
    if (!needs("GenomicAlignments")) return()
    showGenomicRegion(session, id = "igvShiny_0", "chr21:10,397,614-10,423,341")
    bam <- system.file(package = "igvShiny", "extdata", "tumor.bam")
    loadBamTrackFromLocalData(session, id = "igvShiny_0", trackName = "tumor.bam",
                              data = GenomicAlignments::readGAlignments(bam))
  })

  observeEvent(input$addLocalVcfButton, {
    if (!needs("VariantAnnotation")) return()
    showGenomicRegion(session, id = "igvShiny_0", "chr19:33,298,144-33,301,107")
    f <- system.file(package = "igvShiny", "extdata", "chr19-cebpaRegion.vcf.gz")
    loadVcfTrack(session, id = "igvShiny_0", trackName = "vcf",
                 vcfData = VariantAnnotation::readVcf(f, "hg38"))
  })

  observeEvent(input$removeUserTracksButton,
               removeUserAddedTracks(session, id = "igvShiny_0"))

  output$igvShiny_0 <- renderIgvShiny({
    igvShiny(parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "NDUFS2"))
  })
}

shinyApp(ui = ui, server = server)
