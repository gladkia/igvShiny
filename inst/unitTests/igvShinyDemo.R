library(shiny)
library(igvShiny)
library(htmlwidgets)
#----------------------------------------------------------------------------------------------------
addResourcePath("tracks", "tracks")
addResourcePath("www", "www")
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
print(dim(tbl.gwas))
tbl.gwas <- get(load("~/github/lcApps/gwas/danEvans/incoming/tbl.99.hg38.05.RData"))
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        textInput("roi", label=""),
        actionButton("searchButton", "Search"),
        actionButton("addTrackButton", "Add Track"),
        actionButton("addGwasTrackButton", "Add GWAS Track"),
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
      tbl.bed <- data.frame(chr=c("1","1", "1"),
                            start=c(7432951, 7437000, 7438000),
                            end=  c(7436000, 7437500, 7440000),
                            value=c(-0.2239, 3.0, 0.5),
                            sampleID=c("sample1", "sample2", "sample3"),
                            stringsAsFactors=FALSE)
      loadBedTrack(session, "bed", tbl.bed, color="green");
      loadBedGraphTrack(session, "wig", tbl.bed, color="blue", autoscale=TRUE)
      loadSegTrack(session, "seg", tbl.bed)
      })

   observeEvent(input$addGwasTrackButton, {
      printf("---- addGWASTrack")
      printf("current working directory: %s", getwd())
      loadGwasTrack(session, "gwas", tbl.gwas, deleteTracksOfSameName=FALSE)
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
   i <- 1

   output$igvShiny.0 <- renderIgvShiny(
     igvShiny(list(
        genomeName=genomes[i],
        initialLocus=loci[i],
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
runApp(shinyApp(ui = ui, server = server), port=9876)
#shinyApp(ui = ui, server = server)
