library(igvShiny)

#----------------------------------------------------------------------------------------------------
f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
# print(dim(tbl.gwas))
printf <- function(...) print(noquote(sprintf(...)))
genomeSpec <- parseAndValidateGenomeSpec(genomeName="danRer11",  initialLocus="all")
stock.genomes <- sort(get_css_genomes())
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput("genomeChooser", "Choose stock igv genome:", stock.genomes, selected = "danRer11"),
      actionButton("getChromLocButton", "Get Region"),
      actionButton("clearChromLocButton", "Clear Region"),
      div(style = "background-color: white; width: 140px; height:20px; padding-left: 5px;
                   margin-top: 30px; border: 1px solid blue; font-size: 10px;",
          htmlOutput("chromLocDisplay")),
      hr(),
      width = 3
    ),
    mainPanel(
      igvShinyOutput('igvShiny_0'),
      width = 9
    )
  ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {

  observeEvent(input$genomeChooser, ignoreInit=TRUE, {
     newGenome <- input$genomeChooser
     printf("new genome: %s", newGenome)
     genomeSpec <- parseAndValidateGenomeSpec(genomeName=newGenome,  initialLocus="all")
     output$igvShiny_0 <- renderIgvShiny(
       igvShiny(genomeSpec)
       )
     })

  observeEvent(input$searchButton, {
    printf("--- search")
    searchString = isolate(input$roi)
    if(nchar(searchString) > 0)
      showGenomicRegion(session, id = "igvShiny_0", searchString)
  })

  observeEvent(input$addBamLocalFileButton, {
    printf("---- addBamLocalFileButton")
    bamFile <- system.file(package = "igvShiny", "extdata", "A_2_A24_02_01_01.nanopore.minimap.sorted.bam")
    x <- readGAlignments(bamFile)
    loadBamTrackFromLocalData(session, id = "igvShiny_0", trackName = "A_2_A24_02_01_01.nanopore.minimap.sorted.bam",
                              data = x, displayMode = "squished")
  })

  observeEvent(input$removeUserTracksButton, {
    printf("---- removeUserTracks")
    removeUserAddedTracks(session, id = "igvShiny_0")
  })


  observeEvent(input$trackClick, {
    printf("--- trackclick event")
    x <- input$trackClick
    print(x)
  })

  observeEvent(input[["igv-trackClick"]], {
    printf("--- igv-trackClick event")
    x <- input[["igv-trackClick"]]
    print(x)
  })

  observeEvent(input$getChromLocButton, {
    # printf("--- getChromLoc event")
    # sends message to igv.js in browser; currentGenomicRegion.<id> event sent back
    # see below for how that can be captured and displayed
    getGenomicRegion(session, id = "igvShiny_0")
  })

  observeEvent(input$clearChromLocButton, {
    output$chromLocDisplay <- renderText({" "})
  })

  observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
    newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
    #printf("new chromLocString: %s", newLoc)
    output$chromLocDisplay <- renderText({newLoc})
  })

  ##ü TODO add fasta and bam files to inst
  output$igvShiny_0 <- renderIgvShiny(
    igvShiny(genomeSpec)
    )


} # server
#------------------------------------------------------------------------------------------------------------------------
runApp(shinyApp(ui, server), port=6868)
