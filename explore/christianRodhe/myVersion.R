library(shiny)
library(igvShiny)
library(htmlwidgets)

ui <-
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        #actionButton("addAutoscaledGroupBedGraphTrackButton", "Update/Add bigwig"),
        actionButton("searchButton", "Search"),
        textInput("roi", label=""),
        hr(),
        div(style="background-color: white; width: 200px; height:30px; padding-left: 5px;
                   margin-top: 10px; border: 1px solid blue;",
            htmlOutput("chromLocDisplay"))
      ),
      mainPanel(
        igvShinyOutput('igvShiny_0')
      )
    ) # sidebarLayout
  )

tbl.wig <- data.frame(
  chrom=c("8","8", "8","8","20","20","20","20"),
  start=c(127735432, 127736432, 127734632,127735632,32358060,32359060,32369060,32399960),
  end=  c(127735462, 127736632, 127734632,127735932,32358260,32359160,32369260,32401060),
  score=c(-2.239, 3.0, 0.5, 5, 1,2.5, 0.2, 2),
  stringsAsFactors=FALSE
)

server <- function(input, output, session) {
  output$igvShiny_0 <- igvShiny::renderIgvShiny(
    igvShiny::igvShiny(
      list(
        genomeName="hg38",
        initialLocus="MYC",
        displayMode="SQUISHED"
        )
      )
    ) # renderIgvShiny


  ## observeEvent(input$igvReady, {
  ## observeEvent(input$addAutoscaledGroupBedGraphTrackButton, {
  newGenomicRegion <- reactive({
     printf("--- new GenomicREgion arrived")
     input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
     })

  #observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
  # newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
  #observeEvent(newGenomicRegion(), ignoreInit=TRUE, {
  observeEvent(newGenomicRegion(), ignoreInit=TRUE, {
    newLoc <- newGenomicRegion()
    #output$chromLocDisplay <- renderText({newLoc})
    printf("--- observing roi #1: %s", newLoc)
    tbl.wig1b <- tbl.wig
    tbl.wig1b$score <-tbl.wig1b$score * 10
    loadBedGraphTrack(session, id="igvShiny_0", trackName="wig1a", tbl=tbl.wig, color="blue",
                      autoscale=TRUE, autoscaleGroup=1, quiet=FALSE,
                      deleteTracksOfSameName=TRUE)
    loadBedGraphTrack(session, id="igvShiny_0", trackName="wig1b", tbl=tbl.wig1b, color="brown",
                      autoscale=TRUE, autoscaleGroup=1, quiet=FALSE,
                      deleteTracksOfSameName=TRUE)
    })

  #observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
  #  printf("--- observing roi #2")
  #  newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
  #})

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

} # server


app <- shinyApp(ui=ui, server=server)

