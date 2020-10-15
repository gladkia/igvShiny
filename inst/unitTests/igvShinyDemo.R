library(shiny)
library(igvShiny)
#----------------------------------------------------------------------------------------------------
# we need a local directory to write files - for instance, a vcf file representing a genomic
# region of interest.  we then tell shiny about that directory, so that shiny's built-in http server
# can serve up files we write there, ultimately consumed by igv.js
if(!dir.exists("tracks"))
  dir.create("tracks")
addResourcePath("tracks", "tracks")
#----------------------------------------------------------------------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
print(dim(tbl.gwas))
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        textInput("roi", label=""),
        actionButton("searchButton", "Search"),
        actionButton("addTrackButton", "Add Tracks"),
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
      printf("--- search")
      searchString = isolate(input$roi)
      if(nchar(searchString) > 0)
        showGenomicRegion(session, id="igvShiny.0", searchString)
      })

   observeEvent(input$addTrackButton, {
      printf("---- addTrack")
      printf("current working directory: %s", getwd())
      showGenomicRegion(session, id="igvShiny.0", "chr1:7,426,231-7,453,241")
      tbl.bed <- data.frame(chr=c("1","1", "1"),
                            start=c(7432951, 7437000, 7438000),
                            end=  c(7436000, 7437500, 7440000),
                            value=c(-0.2239, 3.0, 0.5),
                            sampleID=c("sample1", "sample2", "sample3"),
                            stringsAsFactors=FALSE)
      loadBedTrack(session, id="igvShiny.0", trackName="bed", tbl=tbl.bed, color="green");
      loadBedGraphTrack(session, id="igvShiny.0", trackName="wig", tbl=tbl.bed, color="blue", autoscale=TRUE)
      loadSegTrack(session, id="igvShiny.0", trackName="seg", tbl=tbl.bed)
      })

   observeEvent(input$addGwasTrackButton, {
      printf("---- addGWASTrack")
      printf("current working directory: %s", getwd())
      showGenomicRegion(session, id="igvShiny.0", "chr5:173,693,980-174,644,498")
      loadGwasTrack(session, id="igvShiny.0", trackName="gwas", tbl=tbl.gwas, deleteTracksOfSameName=FALSE)
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
      printf("--- getChromLoc event")
      output$chromLocDisplay <- renderText({" "})
      getGenomicRegion(session, id="igvShiny.0")
      })

   observeEvent(input$currentGenomicRegion, {
      printf("--- currentGenomicRegion event")
      chromLocRegion <- input$currentGenomicRegion
      output$chromLocDisplay <- renderText({
         chromLocRegion
         })
       })

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
