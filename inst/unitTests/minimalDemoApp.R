library(shiny)
library(igvShiny)
library(htmlwidgets)
#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  # includeScript("message-handler.js"),

  #tags$head(
  #        tags$link(rel = "stylesheet", type = "text/css",
  #                  href = "http://maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css")),
  sidebarLayout(
     sidebarPanel(
        textInput("roi", label=""),
        actionButton("searchButton", "Search"),
        hr(),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny'),
        width=10
        )
     ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {

   observeEvent(input$searchButton, {
      printf("---- input$roi")
      searchString = isolate(input$roi)
      session$sendCustomMessage(type="showGenomicRegion", message=list(roi=searchString))
      })

  output$value <- renderPrint({ input$action })
  output$igvShiny <- renderIgvShiny(
    igvShiny(list(roi="chr5:88,466,402-89,135,305"))
    )

} # server
#----------------------------------------------------------------------------------------------------
showRegion <- function(roi)
{

} # showRegion
#----------------------------------------------------------------------------------------------------
# shinyApp(ui = ui, server = server)
