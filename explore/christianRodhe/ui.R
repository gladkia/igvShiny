library(shiny)
library(igvShiny)
library(htmlwidgets)

shinyUI(
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
)