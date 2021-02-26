library(shiny)
library(igvShiny)
library(GenomicAlignments)
library(htmlwidgets)
library(VariantAnnotation)
library(biomaRt)
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
        textInput("roi", label="", placeholder="gene or chrN:start-end"),
        actionButton("searchButton", "Search"),
        br(), br(), br(),
        actionButton("addLocalVCFTrackButton", "Add 1kg VCF (local file)"),
        actionButton("addRemoteVCFTrackButton", "Add 1kg VCF (AWS)"),
        br(), br(),  br(),
        actionButton("removeUserTracksButton", "Remove User Tracks"),
        br(), br(),
        actionButton("getChromLocButton", "Get Region"),
        actionButton("clearChromLocButton", "Clear Region Readout"),
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
      searchString = isolate(input$roi)
      printf("--- search: %s", searchString)
      if(nchar(searchString) > 0)
        showGenomicRegion(session, id="igvShiny_0", searchString)
      })

    observeEvent(input$addLocalVCFTrackButton, {
       f <- system.file(package="igvShiny", "extdata", "chr19-cebpaRegion.vcf.gz")
       file.exists(f) # [1] TRUE
       vcf <- readVcf(f, "hg38")
       showGenomicRegion(session, id="igvShiny_0", sprintf("chr19:%d-%d", 33299144-1000, 33300107+1000))
       loadVcfTrack(session, id="igvShiny_0", trackName="vcf", vcf)
       })

    observeEvent(input$addRemoteVCFTrackButton, {
       rng <- GRanges(seqnames="22", ranges=IRanges(start=33298112+1000, end=33298112+2000))
         # tabix index file must also be there
       showGenomicRegion(session, id="igvShiny_0", sprintf("chr22:%d-%d", 33298112+1000, end=33298112+2000))
       url <-  "https://s3.amazonaws.com/1000genomes/release/20130502/ALL.chr22.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz";
       vcf <- readVcf(url, "hg38", rng)
       loadVcfTrack(session, id="igvShiny_0", trackName="vcf", vcf)
       })


   observeEvent(input$removeUserTracksButton, {
      printf("---- removeUserTracks")
      removeUserAddedTracks(session, id="igvShiny_0")
      })


  # observeEvent(input$trackClick, {
  #     printf("--- trackclick event")
  #     x <- input$trackClick
  #     print(x)
  #     })

   observeEvent(input[["igv-trackClick"]], {
       printf("--- igv-trackClick event")
       x <- input[["igv-trackClick"]]
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
   loci <- c("chr5:88,466,402-89,135,305", "MEF2C", "Mef2c", "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078")
   i <- 2

   output$igvShiny_0 <- renderIgvShiny(
     igvShiny(list(
        genomeName="hg38",
        initialLocus=loci[i],
        displayMode="SQUISHED"
        ))
      )

} # server
#----------------------------------------------------------------------------------------------------
deploy <-function()
{
   require(rsconnect)
   #rsconnect::setAccountInfo(name='hoodlab',
   #                          token='41E779ABC50F6A98036C95AEEA1A92F7',
   #                          secret='')
   setRepositories(addURLs=c(BioCsoft="https://bioconductor.org/packages/3.12/bioc",
                             BioCann="https://bioconductor.org/packages/3.12/data/annotation",
                             BioCexp="https://bioconductor.org/packages/3.12/data/experiment",
                             BioC="https://bioconductor.org/packages/3.12/bioc",
                             CRAN="https://cran.microsoft.com"),
                   graphics=FALSE)

   deployApp(account="hoodlab",
              appName="igvShinyDemo-VCF",
              appTitle="igvShiny Demo VCF",
              appFiles=c("igvShinyDemo-withVCF.R", "tracks/placeholder"),
              appPrimaryDoc="igvShinyDemo-withVCF.R"
              )

} # deploy
#------------------------------------------------------------------------------------------------------------------------
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
