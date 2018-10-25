library(shiny)
library(igvShiny)
library(htmlwidgets)
library(VariantAnnotation)
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
        igvShinyOutput('igvShiny'),
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
      tbl.bed <- data.frame(chr=c("chr2","chr2", "chr2"),
                            start=c(23309652,  233120837, 233166880),
                            end=  c(233095808, 233124224, 233167046),
                            value=c(-0.2239, 3.0, 0.5),
                            sampleID=c("sample1", "sample2", "sample3"),
                            stringsAsFactors=FALSE)
      loadBedTrack(session, "bed", tbl.bed, color="green");
      loadBedGraphTrack(session, "wig", tbl.bed, color="blue", autoscale=TRUE)
      loadSegTrack(session, "seg", tbl.bed)
      vcfData <- readVcf(system.file(package="igvShiny", "extdata", "inpp5d.fragment.vcf"))
      loadVcfTrack(session, "vcf", vcfData)
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

   output$igvShiny <- renderIgvShiny(
     igvShiny(list(
        genomeName="hg38",
        initialLocus="INPP5D",
        displayMode="EXPANDED",
        trackHeight=300
        ))
      )


} # server
#----------------------------------------------------------------------------------------------------
app <- shinyApp(ui = ui, server = server)
