library(igvShiny)
library(RUnit)
#----------------------------------------------------------------------------------------------------
runTests <- function()
{
    test_url.exists()
    test_availableGenomes()
    test_parseAndVAlidateGenomeSpec()

} # runTests
#----------------------------------------------------------------------------------------------------
test_url.exists <- function()
{
    message(sprintf("--- test_stockGenomes"))
    checkTrue(url.exists("https://google.com"))
    checkTrue(!url.exists("https://google.com/bogusAndImprobableFilename.txt"))

    checkTrue(url.exists("https://s3.amazonaws.com/igv.org.genomes/genomes.json"))

} # test_url.exists
#----------------------------------------------------------------------------------------------------
test_availableGenomes <- function()
{
    message(sprintf("--- test_availableGenomes"))

    cg <- current.genomes()
    checkTrue(length(cg) > 30)

    cg.minimal <- current.genomes(test=TRUE)
    checkEquals(cg.minimal, c("hg38", "hg19", "mm10", "tair10", "rhos", "custom", "dm6", "sacCer3"))

} # test_availableGenomes
#----------------------------------------------------------------------------------------------------
test_parseAndVAlidateGenomeSpec <- function()
{
    message(sprintf("--- test_parseAndVAlidateGenomeSpec"))

    spec <- list(genomeName="hg38",
                 initialLocus="all")

    options <- parseAndValidateGenomeSpec(spec)
    checkEquals(names(options), "name")
    checkEquals(options$name, "hg38")

    error.caught <- tryCatch({
        spec <- list(genomeName="fubar")
        options <- parseAndValidateGenomeSpec(spec)
        FALSE;
        },
    error = function(e){
        TRUE;
        })
    checkTrue(error.caught)

        #------------------------------------------------
        # now an http explicit genomeSpec on our server
        #------------------------------------------------

    spec <- list(genomeName="customGenome",
                 name="ribosome RNA",
                 dataMode="http",
                 fasta="https://igv-data.systemsbiology.net/testFiles/ribosomal-RNA-gene.fasta",
                 fastaIndex="https://igv-data.systemsbiology.net/testFiles/ribosomal-RNA-gene.fasta.fai",
                 annotation="https://igv-data.systemsbiology.net/testFiles/ribosomal-RNA-gene.gff3")

    options <- parseAndValidateGenomeSpec(spec)
    checkEquals(options$name, "ribosome RNA")
    checkEquals(options$fasta, "https://igv-data.systemsbiology.net/testFiles/ribosomal-RNA-gene.fasta")
    checkEquals(options$fastaIndex, "https://igv-data.systemsbiology.net/testFiles/ribosomal-RNA-gene.fasta.fai")
    checkEquals(options$annotation, "https://igv-data.systemsbiology.net/testFiles/ribosomal-RNA-gene.gff3")

        #----------------------------------------------------------------------------
        # now an http explicit genomeSpec on our server, with a mis-spelled filename
        #----------------------------------------------------------------------------

    error.caught <- FALSE
    spec$fasta <- sprintf("%s.bogus", spec$fasta)
    error.caught <- tryCatch({
        options <- parseAndValidateGenomeSpec(spec)
        FALSE;
        },
        error = function(e){
           TRUE;
           })
    checkTrue(error.caught)


        #--------------------------------------------------------------------
        # now n localFile explicit genomeSpec, files included in the package
        #--------------------------------------------------------------------

    data.dir <- system.file(package="igvShiny", "extdata")
    fasta.file <- file.path(data.dir, "ribosomal-RNA-gene.fasta")
    fasta.index.file <- file.path(data.dir, "ribosomal-RNA-gene.fasta.fai")
    annotation.file <- file.path(data.dir, "ribosomal-RNA-gene.gff3")

    spec <- list(genomeName="customGenome",
                 name="ribosome RNA",
                 dataMode="localFile",
                 fasta=fasta.file,
                 fastaIndex=fasta.index.file,
                 annotation=annotation.file)

    options <- parseAndValidateGenomeSpec(spec)
    checkEquals(options$name, "ribosome RNA")
    checkEquals(options$fasta, fasta.file)
    checkEquals(options$fastaIndex, fasta.index.file)
    checkEquals(options$annotation, annotation.file)

        #------------------------------------------------------------------------------------------
        # now n localFile explicit genomeSpec, files included in the package, mis-spelled filename
        #------------------------------------------------------------------------------------------

    error.caught <- FALSE
    spec$annotation <- sprintf("%s.bogus", spec$annotation)
    error.caught <- tryCatch({
        options <- parseAndValidateGenomeSpec(spec)
        FALSE;
        },
        error = function(e){
           TRUE;
           })
    checkTrue(error.caught)

} # test_parseAndVAlidateGenomeSpec
#----------------------------------------------------------------------------------------------------
if(!interactive())
    runTests()
