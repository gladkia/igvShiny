# igvShiny — flagship demo: most of the API in one app
#
# This is also what the public Posit Connect deploy serves
# (demo/posit-connect/app.R runs this very file) and what
# tests/testthat/test-shinyApp.R drives, so the input ids are part of the
# contract: renaming one breaks a test and the live demo at the same time.
#
# Deliberately no *FromLocalData loader here: those pull Rsamtools /
# GenomicAlignments / VariantAnnotation, heavy C-compiled Bioconductor deps
# that would have to be installed on the cloud host just to serve a demo
# button. They live in local-data.R instead. Everything below is either built
# from a data.frame or fetched client-side by igv.js from a URL.

library(shiny)
library(bslib)
library(igvShiny)
library(htmlwidgets)

#----------------------------------------------------------------------------
# sample data
#----------------------------------------------------------------------------
f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))

tbl.bed5 <- data.frame(chr = c("1", "1", "1"),
                       start = c(7432951, 7437000, 7438000),
                       end   = c(7436000, 7437500, 7440000),
                       value = c(-2.239, 3.0, 0.5),
                       sampleID = c("sample1", "sample2", "sample3"),
                       stringsAsFactors = FALSE)

base.loc <- 161200000
tbl.bed9 <- data.frame(chrom = rep("chr1", 3),
                       start = c(base.loc, base.loc + 100, base.loc + 250),
                       end = c(base.loc + 50, base.loc + 120, base.loc + 290),
                       name = c("red", "green", "blue"),
                       score = round(runif(3), 2),
                       strand = c("+", "-", "+"),
                       thickStart = c(base.loc + 10, base.loc + 110, base.loc + 260),
                       thickEnd = c(base.loc + 20, base.loc + 130, base.loc + 280),
                       itemRgb = c("255,0,128", "0,255,0", "0,0,255"),
                       stringsAsFactors = FALSE)

#----------------------------------------------------------------------------
# ui
#----------------------------------------------------------------------------
# a full-width action button with a leading icon, styled consistently
demoButton <- function(id, label, icon_name, class = "btn-outline-primary") {
  actionButton(id, label, icon = icon(icon_name),
               class = paste("w-100 mb-2 text-start", class))
}

theme <- bs_theme(
  version = 5,
  primary = "#2c6faa",
  base_font = font_google("Inter", local = FALSE),
  heading_font = font_google("Inter", local = FALSE)
)

ui <- page_sidebar(
  title = "igvShiny — interactive genome browser",
  theme = theme,
  fillable = TRUE,

  sidebar = sidebar(
    width = 300,
    title = "Controls",

    # keep the search box always visible above the accordion
    div(
      class = "mb-3",
      textInput("roi", label = "Search locus / gene",
                placeholder = "e.g. MEF2C or chr1:7,426,231-7,453,241"),
      actionButton("searchButton", "Search", icon = icon("magnifying-glass"),
                   class = "btn-primary w-100")
    ),

    accordion(
      open = c("Sample-data tracks", "Tracks from URL"),

      accordion_panel(
        "Sample-data tracks", icon = icon("table"),
        demoButton("addBedTrackButton", "BED", "align-left"),
        demoButton("addBedGraphTrackButton", "BedGraph", "chart-area"),
        demoButton("addBedGraphWithAltColorTrackButton", "BedGraph (AltColor)", "palette"),
        demoButton("addBed9TrackButton", "bed9", "grip-lines"),
        demoButton("addGwasTrackButton", "GWAS", "chart-column"),
        demoButton("addGwasCustomTrackButton", "GWAS (columns + colors)", "palette")
      ),

      accordion_panel(
        "Tracks from URL", icon = icon("cloud-arrow-down"),
        demoButton("addBedGraphTrackFromURLButton", "BedGraph (URL)", "chart-area", "btn-outline-secondary"),
        demoButton("addBamViaHttpButton", "BAM (URL)", "dna", "btn-outline-secondary"),
        demoButton("addCramViaHttpButton", "CRAM (URL)", "dna", "btn-outline-secondary"),
        demoButton("addSpliceJunctionTrackButton", "Splice junctions (URL)", "bezier-curve", "btn-outline-secondary")
      ),

      accordion_panel(
        "Region tools", icon = icon("location-crosshairs"),
        demoButton("getChromLocButton", "Get region", "crosshairs", "btn-outline-dark"),
        demoButton("clearChromLocButton", "Clear region", "eraser", "btn-outline-dark"),
        div(class = "small text-muted mt-1 mb-1", "Current region:"),
        div(class = "border rounded p-2 small bg-body-tertiary font-monospace",
            htmlOutput("chromLocDisplay"))
      ),

      accordion_panel(
        "Remove tracks", icon = icon("trash-can"),
        textInput("trackNameToRemove", label = NULL, value = "bed5",
                  placeholder = "track name"),
        demoButton("removeTrackByNameButton", "Remove by name", "eraser", "btn-outline-danger"),
        demoButton("removeUserTracksButton", "Remove all user tracks", "trash-can", "btn-outline-danger")
      )
    ),

    # footer: quick links back to the project
    tags$div(
      class = "mt-auto pt-2 small",
      tags$a(href = "https://github.com/gladkia/igvShiny", target = "_blank",
             class = "link-secondary text-decoration-none me-3",
             icon("github"), " GitHub"),
      tags$a(href = "https://gladkia.github.io/igvShiny/", target = "_blank",
             class = "link-secondary text-decoration-none",
             icon("book"), " Docs"),
      # the Connect deploy pins igvShiny to one commit, so this app can run
      # against an older package than the source tree - print which one
      tags$div(class = "text-muted mt-1 font-monospace",
               sprintf("igvShiny %s", utils::packageVersion("igvShiny")))
    )
  ),

  card(
    full_screen = TRUE,
    card_header(
      class = "d-flex align-items-center gap-2",
      icon("dna"), "Genome viewer",
      tags$span(class = "badge text-bg-light ms-auto", "hg38")
    ),
    card_body(
      class = "p-0",
      igvShinyOutput("igvShiny_0", height = "100%")
    )
  )
)

#----------------------------------------------------------------------------
# server
#----------------------------------------------------------------------------
server <- function(input, output, session) {

  observeEvent(input$searchButton, {
    searchString <- isolate(input$roi)
    if (nchar(searchString) > 0)
      showGenomicRegion(session, id = "igvShiny_0", searchString)
  })

  observeEvent(input$addBedTrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:7,426,231-7,453,241")
    loadBedTrack(session, id = "igvShiny_0", trackName = "bed5", tbl = tbl.bed5)
  })

  observeEvent(input$addBed9TrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:161,199,757-161,201,277")
    loadBedTrack(session, id = "igvShiny_0", trackName = "bed9", tbl = tbl.bed9)
  })

  observeEvent(input$addBedGraphTrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:7,426,231-7,453,241")
    loadBedGraphTrack(session, id = "igvShiny_0", trackName = "wig/bedGraph/local",
                      tbl = tbl.bed5, color = "blue", autoscale = TRUE)
  })

  observeEvent(input$addBedGraphWithAltColorTrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:7,426,231-7,453,241")
    loadBedGraphTrack(session, id = "igvShiny_0", trackName = "wig/bedGraph/local/alt",
                      tbl = tbl.bed5, color = "blue",
                      trackConfig = list(altColor = "red"), autoscale = TRUE)
  })

  observeEvent(input$addBedGraphTrackFromURLButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:154,946,914-155,080,475")
    url <- "https://www.encodeproject.org/files/ENCFF356YES/@@download/ENCFF356YES.bigWig"
    loadBedGraphTrackFromURL(session, id = "igvShiny_0", trackName = "bedGraph/remote",
                             url = url, color = "brown",
                             trackHeight = 50, autoscale = TRUE)
  })

  observeEvent(input$addGwasTrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr19:45,248,108-45,564,645")
    loadGwasTrack(session, id = "igvShiny_0", trackName = "gwas", tbl.gwas = tbl.gwas,
                  deleteTracksOfSameName = FALSE)
  })

  observeEvent(input$addGwasCustomTrackButton, {
    # headers igv.js has no chance of guessing: the same table draws an empty
    # track unless the column numbers are spelled out
    tbl <- tbl.gwas
    names(tbl)[c(3, 4, 10)] <- c("chromosome_label", "bp_location", "significance")
    showGenomicRegion(session, id = "igvShiny_0", "chr19:45,248,108-45,564,645")
    track <- GWASTrack("gwas, custom columns", tbl,
                       chrom.col = 3, pos.col = 4, pval.col = 10,
                       trackHeight = 200,
                       chromosomeColorMap = list("19" = "purple", "*" = "gray"))
    display(track, session, id = "igvShiny_0", deleteTracksOfSameName = FALSE)
  })

  observeEvent(input$addBamViaHttpButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr5:88,733,959-88,761,606")
    base.url <- "https://1000genomes.s3.amazonaws.com/phase3/data/HG02450/alignment"
    url <- sprintf("%s/%s", base.url,
                   "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam")
    loadBamTrackFromURL(session, id = "igvShiny_0", trackName = "1kg.bam",
                        bamURL = url, indexURL = sprintf("%s.bai", url))
  })

  observeEvent(input$addCramViaHttpButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr5:88,733,959-88,761,606")
    url <- paste0("https://s3.amazonaws.com/1000genomes/1000G_2504_high_coverage/",
                  "additional_698_related/data/ERR3989250/HG04160.final.cram")
    loadCramTrackFromURL(session, id = "igvShiny_0", trackName = "CRAM",
                         cramURL = url, indexURL = sprintf("%s.crai", url))
  })

  observeEvent(input$addSpliceJunctionTrackButton, {
    # junctions read as arcs only against the coverage they were spliced out
    # of, so load the sample's bigWig underneath: that pairing is what a
    # sashimi plot shows, and igv.js has no sashimi of its own
    showGenomicRegion(session, id = "igvShiny_0", "chr15:92,835,700-93,031,800")
    base.url <- paste0("https://raw.githubusercontent.com/igvteam/igv-data/",
                       "main/data/test/splice_junctions")
    stem <- "splice_junction_track_test_cases_sampleA.chr15-92835700-93031800"
    loadBedGraphTrackFromURL(session, id = "igvShiny_0", trackName = "sampleA coverage",
                             url = sprintf("%s/%s.bigWig", base.url, stem),
                             color = "gray", trackHeight = 60, autoscale = TRUE)
    loadSpliceJunctionTrackFromURL(
      session, id = "igvShiny_0", trackName = "sampleA junctions",
      url = sprintf("%s/%s.SJ.out.bed.gz", base.url, stem),
      indexURL = sprintf("%s/%s.SJ.out.bed.gz.tbi", base.url, stem),
      trackConfig = list(colorBy = "motif", labelWith = "uniquelyMapped"))
  })

  observeEvent(input$removeTrackByNameButton, {
    name <- isolate(input$trackNameToRemove)
    if (nchar(name) > 0)
      removeTracksByName(session, id = "igvShiny_0", trackNames = name)
  })

  observeEvent(input$removeUserTracksButton, {
    removeUserAddedTracks(session, id = "igvShiny_0")
  })

  observeEvent(input[["igv-trackClick"]], {
    x <- input[["igv-trackClick"]]
    tbl <- data.frame(name = as.character(x)[grep("name", names(x))],
                      value = as.character(x)[grep("value", names(x))],
                      stringsAsFactors = FALSE)
    showModal(modalDialog(HTML(renderTable(tbl)()), easyClose = TRUE))
  })

  observeEvent(input$getChromLocButton, {
    getGenomicRegion(session, id = "igvShiny_0")
  })

  observeEvent(input$clearChromLocButton, {
    output$chromLocDisplay <- renderText({ " " })
  })

  observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
    newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
    output$chromLocDisplay <- renderText({ newLoc })
  })

  output$igvShiny_0 <- renderIgvShiny({
    genomeOptions <- parseAndValidateGenomeSpec(
      genomeName = "hg38", initialLocus = "chr1:6,575,383-8,304,088")
    igvShiny(genomeOptions, displayMode = "SQUISHED", tracks = list())
  })

} # server

shinyApp(ui = ui, server = server)
