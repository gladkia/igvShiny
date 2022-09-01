library(igvShiny)
#----------------------------------------------------------------------------------------------------
options <- parseAndValidateGenomeSpec(genomeName="hg19",  initialLocus="MYC",
                                      stockGenome=TRUE, dataMode="stock",
                                      fasta=NA, fastaIndex=NA, genomeAnnotation=NA)
#----------------------------------------------------------------------------------------------------
wig.size <- 100
values.100 <- runif(n=wig.size, min=-1, max=1)
starts.100 <- seq(from=7432951, to=7432951+(wig.size-1))
ends.100   <- starts.100 + 1
tbl.wig <- data.frame(chr=rep("1", wig.size),
                      start=starts.100,
                      end=ends.100,
                      value=values.100,
                      stringsAsFactors=FALSE)
roi <- "chr1:7432900-7433100"
#----------------------------------------------------------------------------------------------------
ui = shinyUI(

   fluidPage(
     actionButton("addWigTrackButton", "Add Track"),
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

    observeEvent(input$addWigTrackButton, {
       url <- 'https://www.encodeproject.org/files/ENCFF000ASF/@@download/ENCFF000ASF.bigWig'
       loadBedGraphTrackFromURL(session, id="igvShiny", trackName="wig1a", url=url, color="blue",
                                autoscale=TRUE, autoscaleGroup=1,
                                deleteTracksOfSameName=FALSE, quiet=FALSE)
       })

} # server
#----------------------------------------------------------------------------------------------------
runApp(shinyApp(ui=ui, server=server), port=9998)
