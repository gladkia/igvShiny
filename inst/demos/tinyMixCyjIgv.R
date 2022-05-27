library(igvShiny)
library(cyjShiny)
#----------------------------------------------------------------------------------------------------
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
ui = shinyUI(

   fluidPage(
     div(id="igvBox",
         igvShinyOutput('igvShiny')
         ),
     #igvShinyOutput('igvShiny_0'),
     #cyjShinyOutput('cyjShiny_0'),
     div(id="cyjBox",
         cyjShinyOutput('cyjShiny')
         ),
     width=10
     )

) # ui
#----------------------------------------------------------------------------------------------------
server = function(input, output, session)
{
   output$igvShiny <- renderIgvShiny({
      options <- list(genomeName="hg38", initialLocus="NDUFS2")
      igvShiny(options)
      })

   #output$igvShiny_0 <- renderIgvShiny({
   #  options <- list(genomeName="hg38", initialLocus="NDUFS2")
   #   igvShiny(options)
   #   })

   output$cyjShiny <- renderCyjShiny({
     cyjShiny(graph=graph.json, layoutName="cola")
     })

   #output$cyjShiny_0 <- renderCyjShiny({
#      cyjShiny(graph=graph.json, layoutName="random")
#      })


} # server
#----------------------------------------------------------------------------------------------------
runApp(shinyApp(ui=ui, server=server), port=9997)


