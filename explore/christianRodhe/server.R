library(shiny)
library(igvShiny)
library(htmlwidgets)

##  Install the latest version of this package by entering the following in R: 
# install.packages("remotes")
# remotes::install_github("paul-shannon/igvShiny")

tbl.wig <- data.frame(
  chrom=c("8","8", "8","8","20","20","20","20"),
  start=c(127735432, 127736432, 127734632,127735632,32358060,32359060,32369060,32399960),
  end=  c(127735462, 127736632, 127734632,127735932,32358260,32359160,32369260,32401060),
  score=c(-2.239, 3.0, 0.5, 5, 1,2.5, 0.2, 2),
  stringsAsFactors=FALSE
)

shinyServer(function(input, output, session) {
  output$igvShiny_0 <- igvShiny::renderIgvShiny(
    igvShiny::igvShiny(
      list(
        genomeName="hg38",
        initialLocus="MYC",
        displayMode="SQUISHED"
      )
    )
  )
  
  ## observeEvent(input$igvReady, {
  ## observeEvent(input$addAutoscaledGroupBedGraphTrackButton, {
  observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
    loadBedGraphTrack(session, id="igvShiny_0", trackName="wig1a", tbl=tbl.wig, color="blue",
                      autoscale=TRUE, autoscaleGroup=1)
    tbl.wig1b <- tbl.wig
    tbl.wig1b$score <-tbl.wig1b$score * 10
    loadBedGraphTrack(session, id="igvShiny_0", trackName="wig1b", tbl=tbl.wig1b, color="brown",
                      autoscale=TRUE, autoscaleGroup=1)
  })
  
  observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
    newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
    output$chromLocDisplay <- renderText({newLoc})
  })
  
  observeEvent(input$removeUserTracksButton, {
    print("---- removeUserTracks")
    removeUserAddedTracks(session, id="igvShiny_0")
  })
  observeEvent(input$searchButton, {
    print("--- search")
    searchString = isolate(input$roi)
    if(base::nchar(searchString) > 0)
      showGenomicRegion(session, id="igvShiny_0", searchString)
  }) 
  
})
