library(shiny)
library(igvShiny)
library(dplyr)
library(GenomicAlignments)

#----------------------------------------------------------------------------------------------------
# we need a local directory to write files - for instance, a vcf file representing a genomic
# region of interest.  we then tell shiny about that directory, so that shiny's built-in http server
# can serve up files we write there, ultimately consumed by igv.js
if(!dir.exists("tracks"))
  dir.create("tracks")
addResourcePath("tracks", "tracks")
#----------------------------------------------------------------------------------------------------
# a largish gwas file hosted remotely.  this appears to have some
# zero pvalues, which when transformed by -log10, become
# infinite, not conducive to autoscaled display.
#----------------------------------------------------------------
url <- "https://s3.amazonaws.com/igv.org.demo/gwas_sample.tsv.gz"
url.gwasTrack <- GWASTrack("remote url gwas",
                           url,
                           chrom.col=3,
                           pos.col=4,
                           pval.col=10,
                           color="darkgreen",
                           trackHeight=100,
                           autoscale=FALSE,
                           minY=0,
                           maxY=300,
                           visibilityWindow=100000)
#----------------------------------------------------------------------------------------------------
# a gwas file hosted locally
#----------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
tbl.gwas <- get(load(f))
tbl.gwasTrack <- GWASTrack("data.frame gwas",
                           tbl.gwas,
                           chrom.col=3,
                           pos.col=4,
                           pval.col=10,
                           color="brown",
                           trackHeight=100,
                           visibilityWindow=100000)
#----------------------------------------------------------------------------------------------------
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        actionButton("loadRemoteUrlGwasTrackButton", "Load remote url GWAS Track"),
        actionButton("loadLocalTableGwasTrackButton", "Load local table GWAS Track"),
        actionButton("showApoeButton", "APOE region"),
        actionButton("showAllButton",  "All Regions"),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny_0'),
        width=10
        )
     ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {


   output$igvShiny_0 <- renderIgvShiny({
     genomeOptions <- parseAndValidateGenomeSpec(genomeName="hg19",  initialLocus="all")
     igvShiny(genomeOptions)
     })

   observeEvent(input$loadRemoteUrlGwasTrackButton, {
      display(url.gwasTrack, session, id="igvShiny_0")
      })

   observeEvent(input$loadLocalTableGwasTrackButton, {
      display(tbl.gwasTrack, session, id="igvShiny_0")
      })

   observeEvent(input$showApoeButton, {
       showGenomicRegion(session, "igvShiny_0", "chr19:45,303,720-45,463,047")
       })

   observeEvent(input$showAllButton, {
       showGenomicRegion(session, "igvShiny_0", "all")
       })

   #shiny::observeEvent(input$igvReady, ignoreInit=TRUE, {
   #   tbl.gwas <- get(load("../extdata/gwas.RData"))
   #   containerID <- input$igvReady
   #   loadGwasTrack(session, id="igvShiny_0", trackName="demo", tbl=tbl.gwas, deleteTracksOfSameName=TRUE)
   #   })

} # server

#------------------------------------------------------------------------------------------------------------------------
runApp(shinyApp(ui, server), port=6869)
