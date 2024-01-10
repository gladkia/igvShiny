library(shiny)
library(igvShiny)
library(GenomicAlignments)

#----------------------------------------------------------------------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
print(dim(tbl.gwas))
printf <- function(...) print(noquote(sprintf(...)))
ns.sep <- "."
#----------------------------------------------------------------------------------------------------
tbl.bed <- data.frame(chr=c("1","1", "1"),
                      start=c(7432951, 7437000, 7438000),
                      end=  c(7436000, 7437500, 7440000),
                      value=c(-2.239, 3.0, 0.5),
                      sampleID=c("sample1", "sample2", "sample3"),
                      stringsAsFactors=FALSE)
#----------------------------------------------------------------------------------------------------
igv_ui = function(id){

  ns <- NS(id)
  printf("namespace: '%s'", ns("foo"))

  shinyUI(fluidPage(

    sidebarLayout(
      sidebarPanel(
        actionButton(ns("searchButton"), "Search"),
        textInput(ns("roi"), label=""),
        h5("One simple data.frame, three igv formats:"),
        actionButton(ns("addBedTrackButton"), "Add as Bed"),
        actionButton(ns("addBedGraphTrackButton"), "Add as BedGraph"),
        actionButton(ns("addSegTrackButton"), "Add as SEG"),
        br(),
        actionButton(ns("addGwasTrackButton"), "Add GWAS Track"),
        actionButton(ns("addBamViaHttpButton"), "BAM from URL"),
        actionButton(ns("addBamLocalFileButton"), "BAM local data"),
        actionButton(ns("addCramViaHttpButton"), "CRAM from URL"),
        actionButton(ns("removeUserTracksButton"), "Remove User Tracks"),
        actionButton(ns("getChromLocButton"), "Get Region"),
        actionButton(ns("clearChromLocButton"), "Clear Region"),
        div(style="background-color: white; width: 200px; height:30px; padding-left: 5px;
                   margin-top: 10px; border: 1px solid blue;",
            htmlOutput(ns("chromLocDisplay"))),
        hr(),
        width=2
      ),
      mainPanel(
        igvShinyOutput(ns('igvShiny_0')),
        # igvShinyOutput('igvShiny_1'),
        width=10
      )
    ) # sidebarLayout
  ))
}
#----------------------------------------------------------------------------------------------------
igv_server <-  function(input, output, session) {

   ns <- session$ns

   observeEvent(input$searchButton, {
      printf("--- search")
      searchString = isolate(input$roi)
      if(nchar(searchString) > 0)
        showGenomicRegion(session, id="igvShiny_0", searchString)
      })

   observeEvent(input$addBedTrackButton, {
      showGenomicRegion(session, id=ns("igvShiny_0"), "chr1:7,426,231-7,453,241")
      loadBedTrack(session, id=ns("igvShiny_0"), trackName="bed", tbl=tbl.bed, color="green");
      })

   observeEvent(input$addBedGraphTrackButton, {
      showGenomicRegion(session, id=ns("igvShiny_0"), "chr1:7,426,231-7,453,241")
      loadBedGraphTrack(session, id=ns("igvShiny_0"), trackName="wig", tbl=tbl.bed, color="blue", autoscale=TRUE)
      })

   observeEvent(input$addSegTrackButton, {
      showGenomicRegion(session, id=ns("igvShiny_0"), "chr1:7,426,231-7,453,241")
      loadSegTrack(session, id=ns("igvShiny_0"), trackName="seg", tbl=tbl.bed)
      })

   observeEvent(input$addGwasTrackButton, {
      printf("---- addGWASTrack")
      printf("current working directory: %s", getwd())
      showGenomicRegion(session, id=ns("igvShiny_0"), "chr19:45,248,108-45,564,645")
      loadGwasTrack(session, id=ns("igvShiny_0"), trackName="gwas", tbl=tbl.gwas, deleteTracksOfSameName=FALSE)
      })

   observeEvent(input$addBamViaHttpButton, {
      printf("---- addBamViaHttpTrack")
      showGenomicRegion(session, id=ns("igvShiny_0"), "chr5:88,733,959-88,761,606")
      base.url <- "https://1000genomes.s3.amazonaws.com/phase3/data/HG02450/alignment"
      url <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam")
      indexURL <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam.bai")
      loadBamTrackFromURL(session, id=ns("igvShiny_0"),trackName="1kg.bam", bamURL=url, indexURL=indexURL)
      })

   observeEvent(input$addBamLocalFileButton, {
      printf("---- addBamLocalFileButton")
      showGenomicRegion(session, id=ns("igvShiny_0"), "chr21:10,397,614-10,423,341")
      bamFile <- system.file(package="igvShiny", "extdata", "tumor.bam")
      x <- readGAlignments(bamFile)
      loadBamTrackFromLocalData(session, id=ns("igvShiny_0"), trackName="tumor.bam", data=x)
      })

   observeEvent(input$addCramViaHttpButton, {
      printf("---- addCramViaHttpTrack")
      showGenomicRegion(session, id=ns("igvShiny_0"), "chr5:88,733,959-88,761,606")
      base.url <- "https://s3.amazonaws.com/1000genomes"
      url <- sprintf("%s/%s", base.url, "1000G_2504_high_coverage/additional_698_related/data/ERR3989250/HG04160.final.cram")
      indexURL <- sprintf("%s.%s", url, "crai")
      loadCramTrackFromURL(session, id=ns("igvShiny_0"),trackName="CRAM", cramURL=url, indexURL=indexURL)
      
      })

   observeEvent(input$removeUserTracksButton, {
      printf("---- removeUserTracks")
      removeUserAddedTracks(session, id=ns("igvShiny_0"))
      })


   observeEvent(input$trackClick, {
       printf("--- trackclick event")
       x <- input$trackClick
       print(x)
   })

   observeEvent(input$getChromLocButton, {
      # printf("--- getChromLoc event")
      # sends message to igv.js in browser; currentGenomicRegion.<id> event sent back
      # see below for how that can be captured and displayed
      getGenomicRegion(session, id=ns("igvShiny_0"))
      print(sprintf("getChromLocButton, currentGenomicRegion.%s", ns("igvShiny_0")))
      })

   observeEvent(input$clearChromLocButton, {
       printf("clearing chromLocDisplay after clearChromLocButton click")
       printf("---- names(input)")
       print(names(input))
      output$chromLocDisplay <- renderText({" "})
      })

   observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
      newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
      #observeEvent(input$genomicRegionChanged, {
      #newLoc <- input$genomicRegionChanged
      printf("new chromLocString: %s", newLoc)
      output$chromLocDisplay <- renderText({newLoc})
      })

   genomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
   loci <- c("chr5:88,466,402-89,135,305", "MEF2C", "Mef2c", "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078")
   i <- 2

   output$igvShiny_0 <- renderIgvShiny({
     genomeOptions <- parseAndValidateGenomeSpec(genomeName=genomes[i], initialLocus=loci[i])
     igvShiny(genomeOptions)
     })

} # server
#----------------------------------------------------------------------------------------------------
print(sessionInfo())

server <- function(input, output, session){
  callModule(igv_server, "igv")
}

ui <- fluidPage(
  igv_ui(id="igv")
)

runApp(shinyApp(ui = ui, server = server), port=9834)
