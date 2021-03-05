library(shiny)
library(igvShiny)
library(GenomicAlignments)
library(later)
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
# print(dim(tbl.gwas))
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
tbl.bed <- data.frame(chr=c("1","1", "1"),
                      start=c(7432951, 7437000, 7438000),
                      end=  c(7436000, 7437500, 7440000),
                      value=c(-2.239, 3.0, 0.5),
                      sampleID=c("sample1", "sample2", "sample3"),
                      stringsAsFactors=FALSE)
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        actionButton("searchButton", "Search"),
        textInput("roi", label=""),
        h5("One simple data.frame, three igv formats:"),
        actionButton("addBedTrackButton", "Add as Bed"),
        actionButton("addBedGraphTrackButton", "Add as BedGraph"),
        actionButton("addSegTrackButton", "Add as SEG"),
        br(),
        actionButton("addGwasTrackButton", "Add GWAS Track"),
        actionButton("addBamViaHttpButton", "BAM from URL"),
        actionButton("addBamLocalFileButton", "BAM local data"),
        actionButton("addCramViaHttpButton", "CRAM from URL"),
        actionButton("removeUserTracksButton", "Remove User Tracks"),
        actionButton("getChromLocButton", "Get Region"),
        actionButton("clearChromLocButton", "Clear Region"),
        div(style="background-color: white; width: 200px; height:30px; padding-left: 5px;
                   margin-top: 10px; border: 1px solid blue;",
            htmlOutput("chromLocDisplay")),
        hr(),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny_0'),
        # igvShinyOutput('igvShiny_1'),
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
        showGenomicRegion(session, id="igvShiny_0", searchString)
      })

   observeEvent(input$addBedTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadBedTrack(session, id="igvShiny_0", trackName="bed", tbl=tbl.bed, color="green");
      })

   observeEvent(input$addBedGraphTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadBedGraphTrack(session, id="igvShiny_0", trackName="wig", tbl=tbl.bed, color="blue", autoscale=TRUE)
      })

   observeEvent(input$addSegTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadSegTrack(session, id="igvShiny_0", trackName="seg", tbl=tbl.bed)
      })

   observeEvent(input$addGwasTrackButton, {
      printf("---- addGWASTrack")
      printf("current working directory: %s", getwd())
      showGenomicRegion(session, id="igvShiny_0", "chr19:45,248,108-45,564,645")
      loadGwasTrack(session, id="igvShiny_0", trackName="gwas", tbl=tbl.gwas, deleteTracksOfSameName=FALSE)
      })

   observeEvent(input$addBamViaHttpButton, {
      printf("---- addBamViaHttpTrack")
      showGenomicRegion(session, id="igvShiny_0", "chr5:88,733,959-88,761,606")
      base.url <- "https://1000genomes.s3.amazonaws.com/phase3/data/HG02450/alignment"
      url <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam")
      indexURL <- sprintf("%s/%s", base.url, "HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam.bai")
      loadBamTrackFromURL(session, id="igvShiny_0",trackName="1kg.bam", bamURL=url, indexURL=indexURL)
      })

   observeEvent(input$addBamLocalFileButton, {
      printf("---- addBamLocalFileButton")
      showGenomicRegion(session, id="igvShiny_0", "chr21:10,397,614-10,423,341")
      bamFile <- system.file(package="igvShiny", "extdata", "tumor.bam")
      x <- readGAlignments(bamFile)
      loadBamTrackFromLocalData(session, id="igvShiny_0", trackName="tumor.bam", data=x)
      })

   observeEvent(input$addCramViaHttpButton, {
      printf("---- addCramViaHttpTrack")
      showGenomicRegion(session, id="igvShiny_0", "chr5:88,733,959-88,761,606")
      base.url <- "https://s3.amazonaws.com/1000genomes/phase3/data/HG00096/exome_alignment"
      url <- sprintf("%s/%s", base.url, "HG00096.mapped.ILLUMINA.bwa.GBR.exome.20120522.bam.cram")
      indexURL <- sprintf("%s/%s", base.url, "HG00096.mapped.ILLUMINA.bwa.GBR.exome.20120522.bam.cram.crai")
      loadCramTrackFromURL(session, id="igvShiny_0",trackName="CRAM", cramURL=url, indexURL=indexURL)
      })

   observeEvent(input$removeUserTracksButton, {
      printf("---- removeUserTracks")
      removeUserAddedTracks(session, id="igvShiny_0")
      })

    observeEvent(input$igvReady, {
        printf("--- igvReady")
        containerID <- input$igvReady
        printf("igv ready, %s", containerID)
        loadBedTrack(session, id=containerID, trackName="bed.ready", tbl=tbl.bed, color="red");
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
       attribute.name.positions <- grep("name", names(x))
       attribute.value.positions <- grep("value", names(x))
       attribute.names <- as.character(x)[attribute.name.positions]
       attribute.values <- as.character(x)[attribute.value.positions]
       tbl <- data.frame(name=attribute.names,
                         value=attribute.values,
                         stringsAsFactors=FALSE)
       dialogContent <- renderTable(tbl)
       html <- HTML(dialogContent())
       showModal(modalDialog(html, easyClose=TRUE))
       })

   observeEvent(input$getChromLocButton, {
      # printf("--- getChromLoc event")
      # sends message to igv.js in browser; currentGenomicRegion.<id> event sent back
      # see below for how that can be captured and displayed
      getGenomicRegion(session, id="igvShiny_0")
      })

   observeEvent(input$clearChromLocButton, {
      output$chromLocDisplay <- renderText({" "})
      })

   observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
      newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
      #printf("new chromLocString: %s", newLoc)
      output$chromLocDisplay <- renderText({newLoc})
      })

   genomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
   loci <- c("chr5:88,466,402-89,135,305",  "chr1:7,426,231-7,453,241", "MEF2C", "Mef2c",
             "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078",
             "chr1:6,575,383-8,304,088")

   output$igvShiny_0 <- renderIgvShiny({
     cat("--- starting renderIgvShiny\n");
     x <- igvShiny(list(genomeName=genomes[2],
                        initialLocus=loci[7],
                        displayMode="SQUISHED",
                        tracks=list()
                        ))
     cat("--- ending renderIgvShiny\n");
     #later(function() {
     #    loadBedTrack(session, id="igvShiny_0", trackName="bed.start", tbl=tbl.bed, color="red");
     #    }, 8)
     return(x)
     })

   #output$igvShiny.1 <- renderIgvShiny(
   #  igvShiny(list(
   #     genomeName="hg38",
   #     initialLocus="chr2:232,983,999-233,283,872"
   #     ))
   #)

} # server
#----------------------------------------------------------------------------------------------------
deploy <-function()
{
   repos <- options("repos")[[1]]
   stopifnot(sort(names(repos)) == c("BioCann", "BioCsoft", "CRAN"))
   stopifnot(repos$BioCann=="https://bioconductor.org/packages/3.12/data/annotation")
   stopifnot(repos$BioCsoft=="https://bioconductor.org/packages/3.12/bioc")
   stopifnot(repos$CRAN=="https://cran.microsoft.com")
   require(devtools)

   Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS=FALSE)

   install_github("paul-shannon/igvShiny", force=TRUE)

   require(rsconnect)

   deployApp(account="hoodlab",
              appName="igvShinyDemo",
              appTitle="igvShiny Demo",
              appFiles=c("igvShinyDemo.R", "tracks/file4b764ed3abae.bam"),
              appPrimaryDoc="igvShinyDemo.R"
              )

} # deploy
#------------------------------------------------------------------------------------------------------------------------
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
