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
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))

printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
fasta.file <- system.file(package="igvShiny", "extdata", "ribosomal-RNA-gene.fasta")
file.exists(fasta.file)

optional.fasta.indexFile <- system.file(package="igvShiny", "extdata", "ribosomal-RNA-gene.fasta.fai")
file.exists(optional.fasta.indexFile)

gff3.full.path <- system.file(package="igvShiny", "extdata", "ribosomal-RNA-gene.gff3")
stopifnot(file.exists(gff3.full.path))

tbl.gff3 <- read.table(gff3.full.path, sep="\t", as.is=TRUE, header=TRUE)
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(


  # sidebarLayout(
  #    sidebarPanel(
  #       shiny::uiOutput("features"),
  #       shiny::radioButtons("feature_action", "Select or Exclude from Manhattan plot?", choices = c("Select", "Exclude"), selected = "Exclude"),
  #       actionButton("addGwasTrackButton", "Add GWAS Track"),
  #       div(style="background-color: white; width: 200px; height:30px; padding-left: 5px;
  #           margin-top: 10px; border: 1px solid blue;",
  #           htmlOutput("chromLocDisplay")),
  #       hr(),
  #       width=2
  #       ),
  #    mainPanel(
        igvShinyOutput('igvShiny_0'),
  #       width=10
  #       )
  #   ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {

   output$igvShiny_0 <- renderIgvShiny({
      igvShiny(list(
         genomeName="local",
         initialLocus="all",
         fasta=fasta.file,
         index=optional.fasta.indexFile
         ))
      })

   shiny::observeEvent(input$igvReady, {
       loadGFF3TrackFromLocalData(session,
                                  id="igvShiny_0",
                                  trackName="gff3",
                                  tbl.gff3=tbl.gff3,
                                  color="darkBlue",
                                  colorTable=list(),
                                  colorByAttribute=NA_character_,
                                  displayMode="EXPANDED",
                                  trackHeight=200,
                                  visibilityWindow=80000,
                                  deleteTracksOfSameName=TRUE)
       }) # igvReady

} # server
#------------------------------------------------------------------------------------------------------------------------
runApp(shinyApp(ui, server), port=6867)
