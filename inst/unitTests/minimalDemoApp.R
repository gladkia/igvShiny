library(shiny)
library(igvShiny)
library(htmlwidgets)
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        textInput("roi", label=""),
        actionButton("searchButton", "Search"),
        hr(),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny.0'),
        # igvShinyOutput('igvShiny.1'),
        width=10
        )
     ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {

   observeEvent(input$searchButton, {
      printf("---- input$roi")
      searchString = isolate(input$roi)
      session$sendCustomMessage(type="showGenomicRegion", message=list(roi=searchString))
      })

   output$value <- renderPrint({ input$action })

   genomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
   loci <- c("chr5:88,466,402-89,135,305", "MEF2C", "Mef2c", "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078")
   i <- 4

   output$igvShiny.0 <- renderIgvShiny(
     igvShiny(list(
        genomeName=genomes[i],
        initialLocus=loci[i]
        ))
      )

   #output$igvShiny.1 <- renderIgvShiny(
   #  igvShiny(list(
   #     genomeName="hg38",
   #     initialLocus="chr2:232,983,999-233,283,872"
   #     ))
   #)

} # server
#----------------------------------------------------------------------------------------------------
# shinyApp(ui = ui, server = server)
