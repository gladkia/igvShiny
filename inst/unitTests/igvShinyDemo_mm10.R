library(shiny)
library(igvShiny)
library(htmlwidgets)
#----------------------------------------------------------------------------------------------------
addResourcePath("tracks", "tracks")
addResourcePath("www", "www")
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        textInput("roi", label=""),
        actionButton("searchButton", "Search"),
        actionButton("addTrackButton", "Add Track"),
        actionButton("getChromLoc", "Get Region"),
        htmlOutput("chromLocDisplay"),
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

   observeEvent(input$addTrackButton, {
      printf("---- addTrack")
      printf("current working directory: %s", getwd())
      starts=c(83573552+10, 83573552+100, 83573552+1000)
      ends <- starts + 5000

      tbl.bed <- data.frame(chr=c("13","13", "13"),
                            start=starts,
                            end=ends,
                            value=c(-0.2239, 3.0, 0.5),
                            sampleID=c("sample1", "sample2", "sample3"),
                            stringsAsFactors=FALSE)
      loadBedTrack(session, "bed", tbl.bed, color="green");
      loadBedGraphTrack(session, "wig", tbl.bed, color="blue", autoscale=TRUE)
      loadSegTrack(session, "seg", tbl.bed)
      })

   observeEvent(input$getChromLoc, {
      session$sendCustomMessage(type="getGenomicRegion", message=list())
      output$chromLocDisplay <- renderText({" "})
      getGenomicRegion(session)
      })

   observeEvent(input$currentGenomicRegion, {
      chromLocRegion <- input$currentGenomicRegion
      output$chromLocDisplay <- renderText({
         chromLocRegion
         })
       })

   output$value <- renderPrint({ input$action })

   genomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
   loci <- c("chr5:88,466,402-89,135,305", "MEF2C", "Mef2c", "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078")
   i <- 4

   output$igvShiny.0 <- renderIgvShiny(
     igvShiny(list(
        genomeName="mm10",
        initialLocus=loci[3],
        displayMode="SQUISHED"
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
runApp(shinyApp(ui = ui, server = server))
