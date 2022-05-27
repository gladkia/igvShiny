library(shiny)
library(igvShiny)
library(htmlwidgets)
# library(biomaRt)
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
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        textInput("roi", label="", placeholder="gene or chrN:start-end"),
        actionButton("searchButton", "Search"),
        br(), br(), br(),
        #actionButton("addLocalVCFTrackButton", "Add 1kg VCF (local file)"),
        actionButton("addRemoteGFF3TrackButton", "Add Remote GFF3 Track (AWS)"),
        br(),
        actionButton("addRemoteGFF3TrackButtonWithBiotypeColors", "GFF3 Track (AWS) - colors"),
        br(),
        actionButton("addLocalGFF3TrackButton", "GFF3 Track (local)"),
        br(),
        actionButton("addLocalGFF3TrackButtonWithBiotypeColors", "GFF3 Track (local) - colors"),

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

    observeEvent(input$addRemoteGFF3TrackButton, {
       showGenomicRegion(session, id="igvShiny_0", "NDUFS2")
       url <- "https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz"
       indexURL <- "https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz.tbi"
       printf("--- about to call loadGFF3TrackFromURL")
       loadGFF3TrackFromURL(session,
                            id="igvShiny_0",
                            trackName="url gff3",
                            gff3URL=url,
                            indexURL=indexURL,
                            color="brown",
                            colorTable=list(),
                            colorByAttribute=NA_character_,
                            displayMode="EXPANDED",
                            trackHeight=200,
                            visibilityWindow=50000,
                            deleteTracksOfSameName=TRUE)
       })


    observeEvent(input$addRemoteGFF3TrackButtonWithBiotypeColors, {
       showGenomicRegion(session, id="igvShiny_0", "chr1:161,172,691-161,241,018")
       url <- "https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz"
       indexURL <- "https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz.tbi"
       printf("--- about to call loadGFF3TrackFromURL")
       color.table <- list(processed_transcript="blue",
                           protein_coding="darkgreen",
                           retained_intron="brown",
                           nonsense_mediated_decay="orange",
                           miRNA="darkred",
                           default="black")

       colorByAttribute <- "biotype"
       loadGFF3TrackFromURL(session,
                            id="igvShiny_0",
                            trackName="url gff3",
                            gff3URL=url,
                            indexURL=indexURL,
                            color="brown",
                            colorTable=color.table,
                            colorByAttribute=colorByAttribute,
                            displayMode="EXPANDED",
                            trackHeight=200,
                            visibilityWindow=80000,
                            deleteTracksOfSameName=TRUE)
       })


    observeEvent(input$addoLcalGFF3TrackButton, {
       showGenomicRegion(session, id="igvShiny_0", "chr1:161,172,691-161,241,018")
       full.path <- system.file(package="igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
       tbl.gff3 <- read.table(full.path, sep="\t", as.is=TRUE, header=TRUE)
       printf("--- about to call loadGFF3rackFromLocalData, dim: %d, %d", nrow(tbl.gff3), ncol(tbl.gff3))

       loadGFF3TrackFromLocalData(session,
                                  id="igvShiny_0",
                                  trackName="local gff3",
                                  tbl.gff3=tbl.gff3,
                                  colorTable=list(),
                                  colorByAttribute=NA_character_,
                                  color="magenta",
                                  displayMode="EXPANDED",
                                  trackHeight=200,
                                  visibilityWindow=80000,
                                  deleteTracksOfSameName=TRUE)
       }) # addLocalGFF3TrackButtonWithBiotypeColors


    observeEvent(input$addLocalGFF3TrackButtonWithBiotypeColors, {
       showGenomicRegion(session, id="igvShiny_0", "chr1:161,172,691-161,241,018")
       full.path <- system.file(package="igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
       tbl.gff3 <- read.table(full.path, sep="\t", as.is=TRUE, header=TRUE)
       printf("--- about to call loadGFF3rackFromLocalData, dim: %d, %d", nrow(tbl.gff3), ncol(tbl.gff3))
       color.table <- list(processed_transcript="blue",
                           protein_coding="darkgreen",
                           retained_intron="brown",
                           nonsense_mediated_decay="orange",
                           miRNA="darkred",
                           default="black")

       colorByAttribute <- "biotype"
       loadGFF3TrackFromLocalData(session,
                                  id="igvShiny_0",
                                  trackName="local gff3 (colors)",
                                  tbl.gff3=tbl.gff3,
                                  color="brown",
                                  colorTable=color.table,
                                  colorByAttribute=colorByAttribute,
                                  displayMode="EXPANDED",
                                  trackHeight=200,
                                  visibilityWindow=80000,
                                  deleteTracksOfSameName=TRUE)
       }) # addLocalGFF3TrackButtonWithBiotypeColors


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
