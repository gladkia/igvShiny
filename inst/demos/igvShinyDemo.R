library(shiny)
library(igvShiny)
library(GenomicAlignments)
library(later)
library(htmlwidgets)

#----------------------------------------------------------------------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
tbl.bed5 <- data.frame(chr=c("1","1", "1"),
                       start=c(7432951, 7437000, 7438000),
                       end=  c(7436000, 7437500, 7440000),
                       value=c(-2.239, 3.0, 0.5),
                       sampleID=c("sample1", "sample2", "sample3"),
                       stringsAsFactors=FALSE)

base.loc <- 161200000
tbl.bed9 <- data.frame(chrom=rep("chr1", 3),
                       start=c(base.loc, base.loc+100, base.loc + 250),
                       end=c(base.loc + 50, base.loc+120, base.loc+290),
                       name=c("red", "green", "blue"),
                       score=round(runif(3), 2),
                       strand=c("+", "-", "+"),
                       thickStart=c(base.loc+10, base.loc+110, base.loc+260),
                       thickEnd=c(base.loc+20, base.loc+130, base.loc+250),
                       itemRgb=c("255,0,128", "0,255,0", "0,0,255"),
                       stringsAsFactors=FALSE)

wig.size <- 100
values.100 <- runif(n=wig.size, min=-1, max=1)
starts.100 <- seq(from=7432951, to=7432951+(wig.size-1))
ends.100   <- starts.100 + 1
tbl.wig <- data.frame(chr=rep("1", wig.size),
                      start=starts.100,
                      end=ends.100,
                      value=values.100,
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
        actionButton("addBedGraphTrackFromURLButton", "Add BedGraph from URL"),
        # actionButton("addAutoscaledGroupBedGraphTrackButton", "Add Autoscaled Group BedGraphs"),
        # data immediate seg track apparently abandoned with igv.js 2.10.4 or before
        #actionButton("addSegTrackButton", "Add as SEG"),
        br(),
        actionButton("addBed9TrackButton", "bed9 track"),
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
      loadBedTrack(session, id="igvShiny_0", trackName="bed5", tbl=tbl.bed5);
      })

   observeEvent(input$addBed9TrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:161,199,757-161,201,277")
      loadBedTrack(session, id="igvShiny_0", trackName="bed9", tbl=tbl.bed9)
      })

   observeEvent(input$addBedGraphTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadBedGraphTrack(session, id="igvShiny_0", trackName="wig/bedGraph/local", tbl=tbl.bed5,
                        color="blue", autoscale=TRUE)
      })

   observeEvent(input$addAutoscaledGroupBedGraphTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,432,868-7,433,167")
      loadBedGraphTrack(session, id="igvShiny_0", trackName="wig1a", tbl=tbl.wig, color="blue",
                        autoscale=TRUE, autoscaleGroup=1)
      tbl.wig1b <- tbl.wig
      tbl.wig1b$value <-tbl.wig1b$value * 10
      loadBedGraphTrack(session, id="igvShiny_0", trackName="wig1b", tbl=tbl.wig1b, color="brown",
                        autoscale=TRUE, autoscaleGroup=1)
      })

    #

   observeEvent(input$addBedGraphTrackFromURLButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:154,946,914-155,080,475")
      url <- "https://www.encodeproject.org/files/ENCFF356YES/@@download/ENCFF356YES.bigWig"
      loadBedGraphTrackFromURL(session, id="igvShiny_0", trackName="bedGraph/remote",
                               url=url, color="brown",
                               trackHeight=50, autoscale=TRUE)
      })


   observeEvent(input$addSegTrackButton, {
      showGenomicRegion(session, id="igvShiny_0", "chr1:7,426,231-7,453,241")
      loadSegTrack(session, id="igvShiny_0", trackName="seg", tbl=tbl.bed5)
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
      base.url <- "https://s3.amazonaws.com/1000genomes"
      url <- sprintf("%s/%s", base.url, "1000G_2504_high_coverage/additional_698_related/data/ERR3989250/HG04160.final.cram")
      indexURL <- sprintf("%s.%s", url, "crai")
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
        loadBedTrack(session, id=containerID, trackName="bed5 loaded on ready", tbl=tbl.bed5, color="red");
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
     genomeOptions <- parseAndValidateGenomeSpec(genomeName="hg38",  initialLocus=loci[7])
     x <- igvShiny(genomeOptions,
                   displayMode="SQUISHED",
                   tracks=list()
                   )
     cat("--- ending renderIgvShiny\n");
     return(x)
     })

} # server
#----------------------------------------------------------------------------------------------------
deploy <-function()
{
   repos <- options("repos")[[1]]
   stopifnot(sort(names(repos)) == c("BioCann", "BioCsoft", "CRAN"))
   stopifnot(repos$BioCann=="https://bioconductor.org/packages/3.13/data/annotation")
   stopifnot(repos$BioCsoft=="https://bioconductor.org/packages/3.13/bioc")
   stopifnot(repos$CRAN=="https://cran.microsoft.com")
   require(devtools)

      # jim hester suggests, with reference
      # Setting R_REMOTES_NO_ERRORS_FROM_WARNINGS="false" will cause warning
      # messages during calls to install.packages() to become errors. Often warning
      # messages are caused by dependencies failing to install.
   Sys.setenv("R_REMOTES_NO_ERRORS_FROM_WARNINGS" = "true")

   install_github("paul-shannon/igvShiny", force=TRUE)

   require(rsconnect)

   deployApp(account="hoodlab",
              appName="igvShinyDemo",
              appTitle="igvShiny Demo",
              appFiles=c("igvShinyDemo.R", "tracks/file14c6569b08f1.bam"),
              appPrimaryDoc="igvShinyDemo.R"
              )

} # deploy
#------------------------------------------------------------------------------------------------------------------------
# shinyApp(ui = ui, server = server)
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
