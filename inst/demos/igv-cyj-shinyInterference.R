library(shiny)
library(igvShiny)
library(cyjShiny)
library(GenomicAlignments)

#cyjshiny object

tbl.nodes <- data.frame(id=c("A", "B", "C"),
                        type=c("kinase", "TF", "glycoprotein"),
                        lfc=c(-3, 1, 1),
                        count=c(0, 0, 0),
                        stringsAsFactors=FALSE)

tbl.edges <- data.frame(source=c("A", "B", "C"),
                        target=c("B", "C", "A"),
                        interaction=c("phosphorylates", "synthetic lethal", "unknown"),
                        stringsAsFactors=FALSE)

graph.json <- toJSON(dataFramesToJSON(tbl.edges, tbl.nodes), auto_unbox=TRUE)
#----------------------------------------------------------------------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))
print(dim(tbl.gwas))
printf <- function(...) print(noquote(sprintf(...)))
ns.sep <- "."
#----------------------------------------------------------------------------------------------------
igv_ui = function(id){

  ns <- NS(id)

  shinyUI(fluidPage(
      igvShinyOutput(ns('igvShiny_0')),
      cyjShiny::cyjShinyOutput(ns('cyjShiny')),
      width=10
  )
  )
}
#----------------------------------------------------------------------------------------------------
igv_server <-  function(input, output, session) {

   ns <- session$ns

   genomes <- c("hg38", "hg19", "mm10", "tair10", "rhos")
   loci <- c("chr5:88,466,402-89,135,305", "MEF2C", "Mef2c", "1:7,432,931-7,440,395", "NC_007494.2:370,757-378,078")
   i <- 2

   output$igvShiny_0 <- renderIgvShiny({
     genomeOptions <-
       parseAndValidateGenomeSpec(genomeName = genomes[i],  initialLocus = loci[i])
     igvShiny(genomeOptions, displayMode = "SQUISHED")
   })
   
   output$cyjShiny <- cyjShiny::renderCyjShiny({
     cyjShiny::cyjShiny(graph=graph.json, layoutName="cola")
   })

} # server
#----------------------------------------------------------------------------------------------------

server <- function(input, output, session){
  callModule(igv_server, "igv")
}

ui <- fluidPage(
  igv_ui(id="igv")
)

runApp(shinyApp(ui = ui, server = server), port=9834)
