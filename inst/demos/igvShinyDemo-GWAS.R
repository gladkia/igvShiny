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
        actionButton("searchButton", "Search"),
        textInput("roi", label=""),
        shiny::uiOutput("features"),
        shiny::radioButtons("feature_action", "Select or Exclude?", choices = c("Select", "Exclude"), selected = "Exclude"),
        shiny::uiOutput("search_snp"),
        actionButton("addGwasTrackButton", "Add GWAS Track"),
        div(style="background-color: white; width: 200px; height:30px; padding-left: 5px;
            margin-top: 10px; border: 1px solid blue;",
            htmlOutput("chromLocDisplay")),
        hr(),
        width=2
        ),
     mainPanel(
        igvShinyOutput('igvShiny_0'),
        # igvShinyOutput('igvShiny_1'),
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
   immune_feat <- reactive({
      tbl.gwas.phenotype()$feature_display
   })
   
   output$features <- renderUI({
      shiny::selectizeInput('immunefeature', "Select phenotype of interest",
                            choices = immune_feat(),
                            selected =c("A", "T"),
                            multiple = TRUE)
   })
   
   #updating GWAS table with selections or exclusion of features
   gwas_df <- reactive({
      req(input$immunefeature)
      if(input$feature_action == "Exclude") tbl.gwas.phenotype() %>% dplyr::filter(!(feature_display %in% input$immunefeature))
      else tbl.gwas.phenotype() %>% dplyr::filter(feature_display %in% input$immunefeature) 
   })
   
   #generating the SNP id list
   output$search_snp <- renderUI({
      shiny::req(gwas_df())
      snp_options <- (gwas_df() %>% dplyr::filter(!is.na(SNPS)))$SNPS
      shiny::selectInput("snp_int", "Click on the plot or search for a SNP id:",
                         choices = c("", snp_options))
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
   
   observeEvent(input$trackClick, {
      printf("--- igv-trackClick popup")
      x <- input$trackClick
      
      attribute.name.positions <- grep("name", names(x))
      attribute.value.positions <- grep("value", names(x))
      attribute.names <- as.character(x)[attribute.name.positions]
      attribute.values <- as.character(x)[attribute.value.positions]
      tbl <- data.frame(name=attribute.names,
                        value=attribute.values,
                        stringsAsFactors=FALSE)
      dialogContent <- renderTable(tbl)
      html <- HTML(dialogContent())
      showModal(modalDialog(html, easyClose=TRUE))
   })
   
   shiny::observeEvent(input$igvReady, {
      loadGwasTrack(session, id="igvShiny_0", trackName="GWAS", tbl=gwas_df(), deleteTracksOfSameName=FALSE)
   })
   
   observeEvent(input$addGwasTrackButton, {
      loadGwasTrack(session, id="igvShiny_0", trackName="GWAS", tbl=gwas_df(), ymax = 1+max(-log10(gwas_df()$P.VALUE)), deleteTracksOfSameName=FALSE)
   })
   observeEvent(input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]], {
      newLoc <- input[[sprintf("currentGenomicRegion.%s", "igvShiny_0")]]
      #observeEvent(input$genomicRegionChanged, {
      #newLoc <- input$genomicRegionChanged
      printf("new chromLocString: %s", newLoc)
      output$chromLocDisplay <- renderText({newLoc})
   })
   
   output$igvShiny_0 <- renderIgvShiny({
      igvShiny(list(
         genomeName="hg19",
         initialLocus="all",
         displayMode="SQUISHED"
      ))
   })

} # server

#------------------------------------------------------------------------------------------------------------------------
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
runApp(shinyApp(ui, server), port=6867)