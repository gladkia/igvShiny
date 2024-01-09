library(shiny)
library(igvShiny)
library(htmlwidgets)
# library(biomaRt)

#----------------------------------------------------------------------------------------------------
data.directory <- system.file(package="igvShiny", "extdata", "sarsGenome")
fasta.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.dna.toplevel.fa")
fastaIndex.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai")
annotation.file <- file.path(data.directory, "Sars_cov_2.ASM985889v3.101.gff3")

title <- "SARS-CoV-2"
genomeOptions <- parseAndValidateGenomeSpec(genomeName=title,
                                            initialLocus="all",
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
     return(x)
     })

} # server
#----------------------------------------------------------------------------------------------------
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
