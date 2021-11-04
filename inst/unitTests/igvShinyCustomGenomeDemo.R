library(shiny)
library(igvShiny)
library(GenomicAlignments)
library(htmlwidgets)
#----------------------------------------------------------------------------------------------------
# we need a local directory to write files - for instance, a vcf file representing a genomic
# region of interest.  we then tell shiny about that directory, so that shiny's built-in http server
# can serve up files we write there, ultimately consumed by igv.js
if(!dir.exists("tracks"))
  dir.create("tracks")
addResourcePath("tracks", "tracks")
#----------------------------------------------------------------------------------------------------
f <- system.file(package = "igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
# print(dim(tbl.gwas))
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(
  sidebarLayout(
     sidebarPanel(
        actionButton("searchButton", "Search"),
        textInput("roi", label = ""),
        actionButton("addBamLocalFileButton", "BAM local data"),
        actionButton("removeUserTracksButton", "Remove User Tracks"),
        actionButton("getChromLocButton", "Get Region"),
        actionButton("clearChromLocButton", "Clear Region"),
        div(style = "background-color: white; width: 200px; height:30px; padding-left: 5px;
                   margin-top: 10px; border: 1px solid blue;",
            htmlOutput("chromLocDisplay")),
        hr(),
        width = 2
        ),
     mainPanel(
        igvShinyOutput('igvShiny_0'),
        # igvShinyOutput('igvShiny_1'),
        # igvShinyOutput('igvShiny_1'),
        width = 10
        )
     ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {

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
     igvShiny(list(
        genomeName = "local",
        fasta = system.file(package = "igvShiny", "extdata", "A24_02_01_01.fa"),
        index = system.file(package = "igvShiny", "extdata", "A24_02_01_01.fa.fai"),
        initialLocus = "",
        displayMode = "SQUISHED"
        ))
      )

} # server
#------------------------------------------------------------------------------------------------------------------------
runApp(shinyApp(ui, server), port=6868)
