library(shiny)
library(igvShiny)
library(dplyr)
library(GenomicAlignments)

#----------------------------------------------------------------------------------------------------
# we need a local directory to write files - for instance, a vcf file representing a genomic
# region of interest.  we then tell shiny about that directory, so that shiny's built-in http server
# can serve up files we write there, ultimately consumed by igv.js
if(!dir.exists("tracks"))
  dir.create("tracks")
addResourcePath("tracks", "tracks")
#----------------------------------------------------------------------------------------------------
f <- system.file(package="igvShiny", "extdata", "gwas.RData")
stopifnot(file.exists(f))
tbl.gwas <- get(load(f))

printf <- function(...) print(noquote(sprintf(...)))

#----------------------------------------------------------------------------------------------------
ui = shinyUI(fluidPage(

  sidebarLayout(
     sidebarPanel(
        shiny::uiOutput("features"),
        shiny::radioButtons("feature_action", "Select or Exclude from Manhattan plot?", choices = c("Select", "Exclude"), selected = "Exclude"),
        actionButton("addGwasTrackButton", "Add GWAS Track"),
        div(style="background-color: white; width: 200px; height:30px; padding-left: 5px;
            margin-top: 10px; border: 1px solid blue;",
            htmlOutput("chromLocDisplay")),
        hr(),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny_0'),
        width=10
        )
     ) # sidebarLayout
))
#----------------------------------------------------------------------------------------------------
server = function(input, output, session) {
   
   #we will add a column with a random letter to "represent" a phenotype, that will be an additional selection option 
   tbl.gwas.phenotype <- reactive({
      tbl.gwas$feature_display <- sample(LETTERS, size = nrow(tbl.gwas), TRUE)
      tbl.gwas
   })
   
   #generating list of features
   phenotype <- reactive({
      tbl.gwas.phenotype()$feature_display
   })
   
   output$features <- renderUI({
      shiny::selectizeInput('feature', "Select phenotype of interest",
                            choices = phenotype(),
                            selected =c("A", "T"),
                            multiple = TRUE)
   })
   
   #updating GWAS table with selections or exclusion of features
   gwas_df <- reactive({
      shiny::req(input$feature)
      if(input$feature_action == "Exclude") tbl.gwas.phenotype() %>% dplyr::filter(!(feature_display %in% input$feature))
      else tbl.gwas.phenotype() %>% dplyr::filter(feature_display %in% input$feature) 
   })
   
   trackname <- shiny::reactive({
      shiny::req(gwas_df())
      if(is.null(input$feature)) "GWAS"
      else paste("GWAS -",
                 input$feature_action,
                 paste(input$feature, collapse = ", "))
   })
   
   observeEvent(input$searchButton, {
      printf("--- search")
      searchString = isolate(input$roi)
      if(nchar(searchString) > 0)
         showGenomicRegion(session, id="igvShiny_0", searchString)
   })
   observeEvent(input$trackClick, {
      printf("--- trackclick event")
      x <- input$trackClick
      print(x)
   })
   
   observeEvent(input$trackClick, { #add popup window when a SNP is clicked
      printf("--- igv-trackClick popup")
      x <- input$trackClick
      if(x[1] == "SNP"){ #checking that the click was on a SNP
         attribute.name.positions <- grep("name", names(x))
         attribute.value.positions <- grep("value", names(x))
         attribute.names <- as.character(x)[attribute.name.positions][1:12] #if different SNPs points overlap, one click will list several of them
         attribute.values <- as.character(x)[attribute.value.positions][1:12]
         tbl <- data.frame(name=attribute.names,
                           value=attribute.values,
                           stringsAsFactors=FALSE)
         dialogContent <- renderTable(tbl)
         html <- HTML(dialogContent())
         showModal(modalDialog(html, easyClose=TRUE))
      }
   })
   
   observeEvent(input$addGwasTrackButton, {
      loadGwasTrack(session, id="igvShiny_0", trackName=trackname(), tbl=gwas_df(), deleteTracksOfSameName=FALSE)
   })
   
   output$igvShiny_0 <- renderIgvShiny({
      igvShiny(list(
         genomeName="hg19",
         initialLocus="all"
      ))
   })
   
   shiny::observeEvent(input$igvReady, {
      shiny::req(gwas_df())
      containerID <- input$igvReady
      loadGwasTrack(session, id="igvShiny_0", trackName = trackname(), tbl=gwas_df(), deleteTracksOfSameName=TRUE)
   })

} # server

#------------------------------------------------------------------------------------------------------------------------
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
runApp(shinyApp(ui, server), port=6867)