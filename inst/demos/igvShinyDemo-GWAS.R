library(shiny)
library(igvShiny)
library(dplyr)
library(GenomicAlignments)

#----------------------------------------------------------------------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))

printf <- function(...) print(noquote(sprintf(...)))

#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        actionButton("loadGwasTrackButton", "Load GWAS Track"),
        actionButton("showApoeButton", "APOE region"),
        actionButton("showAllButton",  "All Regions"),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny_0'),
        width=10
        )
     ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {


   output$igvShiny_0 <- renderIgvShiny({
     genomeOptions <- parseAndValidateGenomeSpec(genomeName="hg19",  initialLocus="all")
     igvShiny(genomeOptions)
     })

   observeEvent(input$loadGwasTrackButton, {
      loadGwasTrack(session, id="igvShiny_0", trackName="demo", tbl=tbl.gwas, deleteTracksOfSameName=TRUE)
      })

   observeEvent(input$showApoeButton, {
       showGenomicRegion(session, "igvShiny_0", "chr19:45,303,720-45,463,047")
       })

   observeEvent(input$showAllButton, {
       showGenomicRegion(session, "igvShiny_0", "all")
       })

   #shiny::observeEvent(input$igvReady, ignoreInit=TRUE, {
   #   tbl.gwas <- get(load("../extdata/gwas.RData"))
   #   containerID <- input$igvReady
   #   loadGwasTrack(session, id="igvShiny_0", trackName="demo", tbl=tbl.gwas, deleteTracksOfSameName=TRUE)
   #   })

} # server

#------------------------------------------------------------------------------------------------------------------------
runApp(shinyApp(ui, server), port=6867)
