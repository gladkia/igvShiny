library(shiny)
library(igvShiny)
library(htmlwidgets)
# library(biomaRt)
#----------------------------------------------------------------------------------------------------
# we need a local directory to write files - for instance, a vcf file representing a genomic
# region of interest.  we then tell shiny about that directory, so that shiny's built-in http server
# can serve up files we write there, ultimately consumed by igv.js
if(!dir.exists("tracks"))
  dir.create("tracks")
addResourcePath("tracks", "tracks")
#----------------------------------------------------------------------------------------------------
base.url <- "https://igv-data.systemsbiology.net/testFiles/sarsGenome"
fasta.file <- sprintf("%s/%s", base.url,"Sars_cov_2.ASM985889v3.dna.toplevel.fa")
fastaIndex.file <-  sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai")
annotation.file <-  sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.101.gff3")

title <- "SARS-CoV-2"
genomeOptions <- parseAndValidateGenomeSpec(genomeName=title,
                                            initialLocus="all",
                                            stockGenome=FALSE,
                                            dataMode="http",
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
