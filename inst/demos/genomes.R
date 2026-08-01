# igvShiny — the three ways to specify a genome: a stock name igv.js streams
# itself, your own fasta + index + annotation from disk, or the same three
# files fetched from a URL. Only the first needs the igv.js registry, so an
# outage there leaves the stock genomes blank and the custom ones working.

library(shiny)
library(bslib)
library(igvShiny)

data.dir <- system.file(package = "igvShiny", "extdata")
base.url <- "https://gladki.pl/igvr/testFiles"
genomeSpec <- function(mode, stockName = "danRer11") {
  switch(
    mode,
    stock = parseAndValidateGenomeSpec(genomeName = stockName, initialLocus = "all"),
    localFiles = parseAndValidateGenomeSpec(
      genomeName = "ribosomal RNA gene (local)",
      initialLocus = "U13369.1:7,276-8,225",
      stockGenome = FALSE, dataMode = "localFiles",
      fasta = file.path(data.dir, "ribosomal-RNA-gene.fasta"),
      fastaIndex = file.path(data.dir, "ribosomal-RNA-gene.fasta.fai"),
      genomeAnnotation = file.path(data.dir, "ribosomal-RNA-gene.gff3")),
    http = parseAndValidateGenomeSpec(
      genomeName = "ribosomal RNA gene (url)",
      initialLocus = "U13369.1:7,276-8,225",
      stockGenome = FALSE, dataMode = "http",
      fasta = sprintf("%s/ribosomal-RNA-gene.fasta", base.url),
      fastaIndex = sprintf("%s/ribosomal-RNA-gene.fasta.fai", base.url),
      genomeAnnotation = sprintf("%s/ribosomal-RNA-gene.gff3", base.url))
  )
}

ui <- page_sidebar(
  title = "igvShiny — stock and custom genomes",
  theme = bs_theme(version = 5, primary = "#2c6faa"),
  fillable = TRUE,
  sidebar = sidebar(
    width = 300,
    radioButtons("mode", "Genome source",
                 c("stock (igv.js registry)" = "stock",
                   "custom, local files" = "localFiles",
                   "custom, files by URL" = "http")),
    conditionalPanel("input.mode == 'stock'",
                     selectInput("genomeChooser", "Stock genome",
                                 sort(get_css_genomes()), selected = "danRer11"))
  ),
  card(full_screen = TRUE,
       card_body(class = "p-0", igvShinyOutput("igvShiny_0", height = "100%")))
)

server <- function(input, output, session) {
  # re-rendering rebuilds the browser: a live igv.js instance cannot swap genome
  output$igvShiny_0 <- renderIgvShiny({
    req(input$mode, input$genomeChooser)
    igvShiny(genomeSpec(input$mode, input$genomeChooser))
  })
}

shinyApp(ui = ui, server = server)
