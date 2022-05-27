library(igvShiny)
#----------------------------------------------------------------------------------------------------
options <- parseAndValidateGenomeSpec(genomeName="hg38",  initialLocus="NDUFS2",
                                      stockGenome=TRUE, dataMode="stock",
                                      fasta=NA, fastaIndex=NA, genomeAnnotation=NA)
#----------------------------------------------------------------------------------------------------
ui = shinyUI(

   fluidPage(
     igvShinyOutput('igvShiny'),
     width=10
     )

) # ui
#----------------------------------------------------------------------------------------------------
server = function(input, output, session)
{
   output$igvShiny <- renderIgvShiny({
      # options <- list(genomeName="hg38", initialLocus="NDUFS2")
      igvShiny(options)
      })

} # server
#----------------------------------------------------------------------------------------------------
runApp(shinyApp(ui=ui, server=server), port=9998)


