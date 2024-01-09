library(shiny)
library(igvShiny)
library(htmlwidgets)
# library(biomaRt)

#----------------------------------------------------------------------------------------------------
data.directory <- system.file(package="igvShiny", "extdata")
fasta.file      <- file.path(data.directory, "ribosomal-RNA-gene.fasta")
fastaIndex.file <- file.path(data.directory, "ribosomal-RNA-gene.fasta.fai")
annotation.file <- file.path(data.directory, "ribosomal-RNA-gene.gff3")

genomeOptions <- parseAndValidateGenomeSpec(genomeName="ribo local",
                                            initialLocus="U13369.1:7,276-8,225",
                                            stockGenome=FALSE,
                                            dataMode="localFiles",
                                            fasta=fasta.file,
                                            fastaIndex=fastaIndex.file,
                                            genomeAnnotation=annotation.file)

#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(
    igvShinyOutput('igvShiny_0'),
    ))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {


   output$igvShiny_0 <- renderIgvShiny({
     cat("--- starting renderIgvShiny\n");
     x <- igvShiny(genomeOptions,
                   displayMode="SQUISHED",
                   )
     cat("--- ending renderIgvShiny\n");
     return(x)
     })

} # server
#----------------------------------------------------------------------------------------------------
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
