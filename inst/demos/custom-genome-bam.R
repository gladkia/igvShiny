# igvShiny — Custom genome with local BAM streaming via HTTP Range requests
# Demonstrates loading a non-stock reference genome (HLA-A*24:02:01:01)
# along with a local BAM file and index served with zero in-memory overhead
# via session$registerDataObj() and HTTP 206 Partial Content.

library(shiny)
library(bslib)
library(igvShiny)

extdata <- system.file(package = "igvShiny", "extdata")
fa_file <- file.path(extdata, "A24_02_01_01.fa")
fai_file <- file.path(extdata, "A24_02_01_01.fa.fai")
gff3_file <- file.path(extdata, "A24_02_01_01.gff3")
bam_file <- file.path(extdata, "A_2_A24_02_01_01.nanopore.minimap.sorted.bam")
bai_file <- paste0(bam_file, ".bai")

genome_opts <- parseAndValidateGenomeSpec(
  genomeName = "HLA-A*24:02:01:01",
  initialLocus = "A24_02_01_01:1-3502",
  stockGenome = FALSE,
  dataMode = "localFiles",
  fasta = fa_file,
  fastaIndex = fai_file,
  genomeAnnotation = gff3_file
)

ui <- page_sidebar(
  title = "igvShiny — Custom Genome & Local BAM Streaming",
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  fillable = TRUE,
  sidebar = sidebar(
    width = 300,
    p(tags$small(
      "Demonstrates custom genome (HLA-A*24:02:01:01) with local BAM/BAI ",
      "streamed directly from disk via HTTP 206 Partial Content."
    )),
    hr(),
    actionButton("btnExon2", "Jump: Exon 2 (504-773)", class = "w-100 mb-2 btn-outline-primary"),
    actionButton("btnExon3", "Jump: Exon 3 (1015-1290)", class = "w-100 mb-2 btn-outline-primary"),
    actionButton("btnAll", "Jump: Entire Gene (1-3502)", class = "w-100 mb-3 btn-outline-secondary"),
    hr(),
    actionButton("addDynamicBamBtn", "Load Dynamic BAM Track", class = "w-100 mb-2 btn-success"),
    actionButton("removeTracksBtn", "Remove User Tracks", class = "btn-outline-danger w-100")
  ),
  card(
    full_screen = TRUE,
    card_body(class = "p-0", igvShinyOutput("igvShiny_0", height = "100%"))
  )
)

server <- function(input, output, session) {
  # Register startup track with HTTP 206 Range streaming
  bam_url <- serveLocalFile(session, bam_file)
  bai_url <- serveLocalFile(session, bai_file)

  startup_tracks <- list(
    list(
      name = "Nanopore Reads (Startup Track)",
      type = "alignment",
      format = "bam",
      url = bam_url,
      indexURL = bai_url,
      displayMode = "EXPANDED",
      height = 300
    )
  )

  output$igvShiny_0 <- renderIgvShiny({
    igvShiny(genome_opts, tracks = startup_tracks)
  })

  # Dynamic track loader demonstration
  observeEvent(input$addDynamicBamBtn, {
    loadBamTrackFromLocalFile(
      session = session,
      id = "igvShiny_0",
      trackName = "Nanopore Reads (Dynamic)",
      bamFile = bam_file,
      indexFile = bai_file,
      trackConfig = list(color = "#107c41", displayMode = "SQUISHED", height = 200)
    )
  })

  # Navigation buttons
  observeEvent(input$btnExon2, {
    showGenomicRegion(session, id = "igvShiny_0", "A24_02_01_01:504-773")
  })

  observeEvent(input$btnExon3, {
    showGenomicRegion(session, id = "igvShiny_0", "A24_02_01_01:1015-1290")
  })

  observeEvent(input$btnAll, {
    showGenomicRegion(session, id = "igvShiny_0", "A24_02_01_01:1-3502")
  })

  observeEvent(input$removeTracksBtn, {
    removeUserAddedTracks(session, id = "igvShiny_0")
  })
}

shinyApp(ui = ui, server = server)
