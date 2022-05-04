#' @import httr
#'
#----------------------------------------------------------------------------------------------------
# log <- function(...)if(verbose) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
#' @description a helper function for mostly internal use, tests for availability of a url,
#'              modeled after file.exists
#'
#' @rdname url.exists
#' @aliases url.exists
#'
#' @param url character the http address to test
#'
#' @return logical TRUE or FALSE
#'
#' @export
url.exists <- function(url)
{
   response <- tolower(httr::http_status(httr::HEAD(url))$category)
   return(tolower(response) == "success")

} # url.exists
#----------------------------------------------------------------------------------------------------
#' @description a helper function for mostly internal use, obtains the genome codes (e.g. 'hg38')
#'       supported by igv.js
#'
#' @rdname currently.supported.genomes
#' @aliases currently.supported.genomes
#'
#' @return an list of short genome codes, e.g., "hg38", "dm6", "tair10"
#' @export
#'
currently.supported.genomes <- function(test=FALSE)
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

} # currently.supported.genomes
#----------------------------------------------------------------------------------------------------
#' @description a helper function for internal use by the igvShiny constructor, but possible also
#' of use to those building an igvShiny app, to test their genome specification for validity
#'
#' @rdname parseAndValidateGenomeSpec
#' @aliases parseAndValidateGenomeSpec
#'
#' @param genomeName character usually one short code of a supported ("stock") genome (e.g., "hg38") or for
#'        a user-supplied custom genome, the name you wish to use
#' @param initialLocus character default "all", otherwise "chrN:start-end" or a recognized gene symbol
#' @param stockGenome logical default FALSE
#' @param dataMode character either "stock", "localFile" or "http"
#' @param fasta character when supplying a custom (non-stock) genome, either a file path or a URL
#' @param fastaIndex character when supplying a custom (non-stock) genome, either a file path or a URL,
#'     essential for all but the very small custom genomes.
#' @param genomeAnnotation character when supplying a custom (non-stock) genome, a file path or URL pointing
#'    to a genome annotation file in a gff3 format
#'
#' @return an options list directly usable by igvApp.js, and thus igv.js
#' @export
#'
parseAndValidateGenomeSpec <- function(genomeName, initialLocus="all",
                                       stockGenome=TRUE, dataMode="stock",
                                       fasta=NA, fastaIndex=NA, genomeAnnotation=NA)
{
    options <- list()
    options[["validated"]] <- FALSE

    #--------------------------------------------------
    # first: is this a stock genome?  if so, we need
    # only check if the genomeName is recognized
    #--------------------------------------------------

    if(stockGenome){
       supported.genomes <- currently.supported.genomes()
       if(!genomeName %in% supported.genomes){
          s.1 <- sprintf("Your genome '%s' is not currently supported", genomeName)
          s.2 <- sprintf("Currently supported: %s", paste(supported.genomes, collapse=","))
          msg <- sprintf("%s\n%s", s.1, s.2)
          stop(msg)
          }
       options[["genomeName"]] <- genomeName
       options[["initialLocus"]] <- initialLocus
       options[["fasta"]] <- NA
       options[["fastaIndex"]] <- NA
       options[["annotation"]] <- NA
       options[["validated"]] <- TRUE
       } # stockGenome requested

    if(!stockGenome){
       stopifnot(!is.na(dataMode))
       stopifnot(!is.na(fasta))
       stopifnot(!is.na(fastaIndex))
         # genomeAnnotation is optional

       dataMode <- genomeSpec$dataMode
       recognized.modes <- c("localFile", "http")  # "direct" for an in-memory R data structure, deferred
       if(!dataMode %in% recognized.modes){
          msg <- sprintf("dataMode '%s' should be one of %s", paste(recognized.modes, collapse=","))
          stop(msg)
          }

       #---------------------------------------------------------------------
       # dataMode determines how to check for the existence of each resource
       #---------------------------------------------------------------------

       exists.function <- switch(dataMode,
                                 "localFile" = file.exists,
                                 "http" = url.exists
                                 )
       stopifnot(exists.function(genomeSpec$fasta))
       stopifnot(exists.function(genomeSpec$fastaIndex))
       if(!is.na(genomeAnnotation))
          stopifnot(exists.function(genomeSpec$annotation))

       options[["genomeName"]]  <- genomeName
       options[["fasta"]] <- fasta
       options[["fastaIndex"]] <- fastaIndex
       options[["annotation"]] <- genomeSpec$annotation
       }

    return(options)

} # parseAndValidateGenomeSpec
#----------------------------------------------------------------------------------------------------
