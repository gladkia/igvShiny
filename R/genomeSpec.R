#' @import httr
#'
#----------------------------------------------------------------------------------------------------
log <- function(...)if(verbose) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
#' @description a helper function for mostly internal use, tests for availability of a url, modeled
#' after file.exists
#'
#' @rdname url.exists
#' @aliases url.exits
#'
#' @return logical TRUE or FALSE
#' @export
#'
url.exists <- function(url)
{
   response <- tolower(httr::http_status(httr::HEAD(url))$category)
   return(tolower(response) == "success")

} # url.exists
#----------------------------------------------------------------------------------------------------
#' @description a helper function for mostly internal use, obtains the genome codes (e.g. 'hg38')
#' supported by igv.js
#'
#' @rdname current.genomes
#' @aliases current.genomes
#'
#' @return an list of short genome codes, e.g., "hg38", "dm6", "tair10"
#' @export
#'
current.genomes <- function(test=FALSE)
{
    basic.offerings <-  c("hg38", "hg19", "mm10", "tair10", "rhos", "custom", "dm6", "sacCer3")
    if(test) return(basic.offerings)

    current.genomes.file <- "https://s3.amazonaws.com/igv.org.genomes/genomes.json"


    if(!url.exists(current.genomes.file))
        return(basic.offerings)

    current.genomes.raw <- readLines(current.genomes.file, warn=FALSE, skipNul=TRUE)
    genomes.raw <- grep('^    "id": ', current.genomes.raw, value=TRUE)
    supported.genomes <- sub(",", "", sub(" *id: ", "", gsub('"', '', genomes.raw)))
    return(supported.genomes)

} # current.genomes
#----------------------------------------------------------------------------------------------------
#' @description a helper function for internal use by the igvShiny constructor, but possible also
#' of use to those building an igvShiny app, to test their genome specification for validity
#'
#' @rdname parseAndValidateGenomeSpec
#' @aliases parseAndValidateGenomeSpec
#'
#' @param genomeSpec a list, with one required field 'genoneCode', and 3 optional: 'fasta', 'fasta.index'
#' genome.annotation, all of which use remote urls, or a full path to a local file
#'
#' @return an options list directly usable by igvApp.js, and thus igv.js
#' @export
#'
parseAndValidateGenomeSpec <- function(genomeSpec)
{
    supported.genomes <- c(current.genomes(), "customGenome")
    genomeCode <- genomeSpec$genomeCode
    browser()
    supported <-  genomeCode %in% supported.genomes
    if (!supported){
       s.1 <- sprintf("Your genome '%s' is not currently supported", code)
       s.2 <- sprintf("Currently supported: %s", paste(supported.genomes, collapse=","))
       msg <- sprintf("%s\n%s", s.1, s.2)
       stop(msg)
       }

    options <- list()
    return(options)

} # parseAndValidateGenomeSpec
#----------------------------------------------------------------------------------------------------
