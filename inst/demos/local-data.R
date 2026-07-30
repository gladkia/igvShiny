# igvShiny — data that is already in R: the *FromLocalData loaders.
#
# These write a file into the tracks directory and have shiny serve it, so
# unlike the URL loaders they need the parsing package on the server side.
# Loaded on click rather than at startup: the app is a test fixture
# (tests/testthat/test-shinyApp.R drives the GFF3 buttons, whose ids are part
# of that contract) and a missing suggested package should grey out one button,
# not the whole app.

library(shiny)
library(bslib)
library(igvShiny)

gff3.colors <- list(processed_transcript = "blue", protein_coding = "darkgreen",
                    retained_intron = "brown", nonsense_mediated_decay = "orange",
                    miRNA = "darkred", default = "black")
gff3.url <- "https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz"

# Junctions as they arrive in R: one row each, attributes in their own columns.
# The loader packs them into the bed name field igv.js filters and labels on.
# Rows are real, taken from the STAR output igvteam ships as a test case
# (data/test/splice_junctions in igvteam/igv-data), so the counts are the ones
# the arcs are sized by.
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
    actionButton("addLocalGFF3TrackButtonWithBiotypeColors", "GFF3 local (colors)", class = "w-100 mb-2"),
    actionButton("addLocalJunctionsButton", "Splice junctions (data.frame)", class = "w-100 mb-2"),
    hr(),
    actionButton("addRemoteGFF3TrackButton", "GFF3 from URL", class = "w-100 mb-2"),
    actionButton("addRemoteGFF3TrackButtonWithBiotypeColors", "GFF3 from URL (colors)", class = "w-100 mb-2"),
    hr(),
    actionButton("removeUserTracksButton", "Remove user tracks", class = "btn-outline-danger w-100")
  ),
  card(full_screen = TRUE, card_body(class = "p-0",
                                     igvShinyOutput("igvShiny_0", height = "100%")))
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

  observeEvent(input$addLocalGFF3TrackButtonWithBiotypeColors, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:161,172,691-161,241,018")
    f <- system.file(package = "igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
    loadGFF3TrackFromLocalData(session, id = "igvShiny_0", trackName = "local gff3 (colors)",
                               tbl.gff3 = read.table(f, sep = "\t", as.is = TRUE, header = TRUE),
                               color = "brown", colorTable = gff3.colors,
                               colorByAttribute = "biotype", displayMode = "EXPANDED",
                               trackHeight = 200, visibilityWindow = 80000)
  })

  observeEvent(input$addLocalJunctionsButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr15:92,880,000-92,900,000")
    loadSpliceJunctionTrackFromLocalData(
      session, id = "igvShiny_0", trackName = "sampleA junctions",
      tbl = junctions, trackHeight = 150,
      trackConfig = list(colorBy = "motif", labelWith = "uniqueReadCount"))
  })

  observeEvent(input$addRemoteGFF3TrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "NDUFS2")
    # colorTable and colorByAttribute have no defaults - omitting them fails
    # inside the observer, where nothing surfaces the error to the browser
    loadGFF3TrackFromURL(session, id = "igvShiny_0", trackName = "url gff3",
                         gff3URL = gff3.url, indexURL = sprintf("%s.tbi", gff3.url),
                         color = "brown", colorTable = list(),
                         colorByAttribute = NA_character_, displayMode = "EXPANDED",
                         trackHeight = 200, visibilityWindow = 50000)
  })

  observeEvent(input$addRemoteGFF3TrackButtonWithBiotypeColors, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:161,172,691-161,241,018")
    loadGFF3TrackFromURL(session, id = "igvShiny_0", trackName = "url gff3 (colors)",
                         gff3URL = gff3.url, indexURL = sprintf("%s.tbi", gff3.url),
                         color = "brown", colorTable = gff3.colors,
                         colorByAttribute = "biotype", displayMode = "EXPANDED",
                         trackHeight = 200, visibilityWindow = 80000)
  })

  observeEvent(input$removeUserTracksButton, {
    removeUserAddedTracks(session, id = "igvShiny_0")
  })

  output$igvShiny_0 <- renderIgvShiny({
    igvShiny(parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = "NDUFS2"))
  })
}

shinyApp(ui = ui, server = server)
