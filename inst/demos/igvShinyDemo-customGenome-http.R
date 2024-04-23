library(shiny)
library(igvShiny)
library(htmlwidgets)
# library(biomaRt)

#----------------------------------------------------------------------------------------------------

  base.url <- "https://gladki.pl/igvr/testFiles"
  title <- "ribo remote"
  fasta.file <- sprintf("%s/%s", base.url, "ribosomal-RNA-gene.fasta")
  fastaIndex.file <- sprintf("%s/%s", base.url, "ribosomal-RNA-gene.fasta.fai")
  annotation.file <- sprintf("%s/%s", base.url, "ribosomal-RNA-gene.gff3")
  locus <- "U13369.1:7,276-8,225"

  #title <- "ensembl gz"
  #fasta.file <- "http://ftp.ensembl.org/pub/release-106/fasta/homo_sapiens/dna_index/Homo_sapiens.GRCh38.dna.toplevel.fa.gz"
  #fastaIndex.file <- "http://ftp.ensembl.org/pub/release-106/fasta/homo_sapiens/dna_index/Homo_sapiens.GRCh38.dna.toplevel.fa.gz.fai"
  #locus <- "all"

genomeOptions <- parseAndValidateGenomeSpec(genomeName=title,
                                            initialLocus=locus,
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
     cat("--- ending renderIgvShiny\n");
     return(x)
     })

} # server
#----------------------------------------------------------------------------------------------------
if(grepl("hagfish", Sys.info()[["nodename"]]) & !interactive()){
   runApp(shinyApp(ui, server), port=6867)
   } else {
   shinyApp(ui, server)
   }
