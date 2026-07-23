# igvShiny — public demo app for Posit Connect Cloud
#
# Trimmed variant of inst/demos/igvShinyDemo.R for lightweight cloud deploy:
#   - "BAM local data" button removed -> drops GenomicAlignments + Rsamtools
#     (heavy Bioconductor C-compile deps, only ever used by readGAlignments()).
#   - BAM-from-URL / CRAM-from-URL kept: igv.js fetches these client-side,
#     so they demo alignment tracks with zero server-side dependency.
#
# UI uses bslib (Bootstrap 5): a page_sidebar layout with the IGV viewer in a
# full-screen-able card and the track/navigation controls grouped into an
# accordion. The server logic is unchanged from the classic demo — same input
# ids — only the UI layer is restyled.

library(shiny)
library(bslib)
library(igvShiny)
library(htmlwidgets)

#----------------------------------------------------------------------------------------------------
f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
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

wig.size <- 100
values.100 <- runif(n = wig.size, min = -1, max = 1)
starts.100 <- seq(from = 7432951, to = 7432951 + (wig.size - 1))
ends.100   <- starts.100 + 1
tbl.wig <- data.frame(chr = rep("1", wig.size),
                      start = starts.100,
                      end = ends.100,
                      value = values.100,
                      stringsAsFactors = FALSE)
#----------------------------------------------------------------------------------------------------
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
      textInput("roi", label = "Search locus / gene", placeholder = "e.g. MEF2C or chr1:7,426,231-7,453,241"),
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
        demoButton("addGwasTrackButton", "GWAS", "chart-column")
      ),

      accordion_panel(
        "Tracks from URL", icon = icon("cloud-arrow-down"),
        demoButton("addBedGraphTrackFromURLButton", "BedGraph (URL)", "chart-area", "btn-outline-secondary"),
        demoButton("addBamViaHttpButton", "BAM (URL)", "dna", "btn-outline-secondary"),
        demoButton("addCramViaHttpButton", "CRAM (URL)", "dna", "btn-outline-secondary")
      ),

      accordion_panel(
        "Region tools", icon = icon("location-crosshairs"),
        demoButton("getChromLocButton", "Get region", "crosshairs", "btn-outline-dark"),
        demoButton("clearChromLocButton", "Clear region", "eraser", "btn-outline-dark"),
        demoButton("removeUserTracksButton", "Remove user tracks", "trash-can", "btn-outline-danger"),
        div(class = "small text-muted mt-1 mb-1", "Current region:"),
        div(class = "border rounded p-2 small bg-body-tertiary font-monospace",
            htmlOutput("chromLocDisplay"))
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
             icon("book"), " Docs")
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
      igvShinyOutput('igvShiny_0', height = "100%")
    )
  )
)
#----------------------------------------------------------------------------------------------------
server <- function(input, output, session) {

  observeEvent(input$searchButton, {
    printf("--- search")
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
    loadBedGraphTrack(session, id = "igvShiny_0", trackName = "wig/bedGraph/local", tbl = tbl.bed5,
                      color = "blue", autoscale = TRUE)
  })

  observeEvent(input$addBedGraphWithAltColorTrackButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:7,426,231-7,453,241")
    loadBedGraphTrack(session, id = "igvShiny_0", trackName = "wig/bedGraph/local/alt", tbl = tbl.bed5,
                      color = "blue", trackConfig = list(altColor = "red"), autoscale = TRUE)
  })

  observeEvent(input$addBedGraphTrackFromURLButton, {
    showGenomicRegion(session, id = "igvShiny_0", "chr1:154,946,914-155,080,475")
    url <- "https://www.encodeproject.org/files/ENCFF356YES/@@download/ENCFF356YES.bigWig"
    loadBedGraphTrackFromURL(session, id = "igvShiny_0", trackName = "bedGraph/remote",
                             url = url, color = "brown",
                             trackHeight = 50, autoscale = TRUE)
  })

  observeEvent(input$addGwasTrackButton, {
    printf("---- addGWASTrack")
    showGenomicRegion(session, id = "igvShiny_0", "chr19:45,248,108-45,564,645")
    loadGwasTrack(session, id = "igvShiny_0", trackName = "gwas", tbl = tbl.gwas, deleteTracksOfSameName = FALSE)
  })

  observeEvent(input$addBamViaHttpButton, {
    printf("---- addBamViaHttpTrack")
    showGenomicRegion(session, id = "igvShiny_0", "chr5:88,733,959-88,761,606")
    base.url <- "https://1000genomes.s3.amazonaws.com/phase3/data/HG02450/alignment"
    url <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam")
    indexURL <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam.bai")
    loadBamTrackFromURL(session, id = "igvShiny_0", trackName = "1kg.bam", bamURL = url, indexURL = indexURL)
  })

  observeEvent(input$addCramViaHttpButton, {
    printf("---- addCramViaHttpTrack")
    showGenomicRegion(session, id = "igvShiny_0", "chr5:88,733,959-88,761,606")
    base.url <- "https://s3.amazonaws.com/1000genomes"
    url <- sprintf("%s/%s", base.url, "1000G_2504_high_coverage/additional_698_related/data/ERR3989250/HG04160.final.cram")
    indexURL <- sprintf("%s.%s", url, "crai")
    loadCramTrackFromURL(session, id = "igvShiny_0", trackName = "CRAM", cramURL = url, indexURL = indexURL)
  })

  observeEvent(input$removeUserTracksButton, {
    printf("---- removeUserTracks")
    removeUserAddedTracks(session, id = "igvShiny_0")
  })

  observeEvent(input$igvReady, {
    printf("--- igvReady")
    containerID <- input$igvReady
    printf("igv ready, %s", containerID)
  })

  observeEvent(input[["igv-trackClick"]], {
    printf("--- igv-trackClick event")
    x <- input[["igv-trackClick"]]
    print(x)
    attribute.name.positions <- grep("name", names(x))
    attribute.value.positions <- grep("value", names(x))
    attribute.names <- as.character(x)[attribute.name.positions]
    attribute.values <- as.character(x)[attribute.value.positions]
    tbl <- data.frame(name = attribute.names,
                      value = attribute.values,
                      stringsAsFactors = FALSE)
    dialogContent <- renderTable(tbl)
    html <- HTML(dialogContent())
    showModal(modalDialog(html, easyClose = TRUE))
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

  loci <- c("chr5:88,466,402-89,135,305", "chr1:7,426,231-7,453,241", "MEF2C", "Mef2c",
            "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078",
            "chr1:6,575,383-8,304,088")

  output$igvShiny_0 <- renderIgvShiny({
    cat("--- starting renderIgvShiny\n")
    genomeOptions <- parseAndValidateGenomeSpec(genomeName = "hg38", initialLocus = loci[7])
    x <- igvShiny(genomeOptions,
                  displayMode = "SQUISHED",
                  tracks = list())
    cat("--- ending renderIgvShiny\n")
    return(x)
  })

} # server
#----------------------------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
