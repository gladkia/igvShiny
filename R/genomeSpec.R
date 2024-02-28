
#' @title get_basic_genomes
#' @description a helper function for basic genomes, 
#' obtains the genome codes (e.g. 'hg38')
#'
#' @rdname get_basic_genomes
#' @aliases get_basic_genomes
#'
#' @return an list of short genome codes, e.g., "hg38", "dm6"
#'
#' @examples
#' bs <- get_basic_genomes()
#'
#' @keywords utils
#' @export
#'
get_basic_genomes <- function() {
  BASIC_GENOMES
  
} # get_basic_genomes
#-------------------------------------------------------------------------------
#' @title get_cas_genomes
#' @description a helper function for common always available stock genomes,
#' obtains the genome codes (e.g. 'hg38')
#'
#' @rdname get_cas_genomes
#' @aliases get_cas_genomes
#'
#' @return an list of short genome codes, e.g., "hg38", "dm6"
#'
#' @examples
#' cas <- get_cas_genomes()
#'
#' @keywords utils
#' @export
#'
get_cas_genomes <- function() {
  CAS_GENOMES
  
} # get_cas_genomes
#-------------------------------------------------------------------------------
#' @title get_css_genomes
#' @description a helper function for mostly internal use, 
#' obtains the genome codes (e.g. 'hg38') supported by igv.js
#'
#' @rdname get_css_genomes
#' @aliases get_css_genomes
#' @param test logical(1) defaults to FALSE
#'
#' @return an list of short genome codes, e.g., "hg38", "dm6", "tair10"
#'
#' @examples
#' css <- get_css_genomes(test = TRUE)
#'
#' @keywords utils
#' @export
#'
get_css_genomes <- function(test = FALSE) {
  if (test)
    return(get_basic_genomes())
  
  current.genomes.file <-
    "https://s3.amazonaws.com/igv.org.genomes/genomes.json"
  
  if (!RCurl::url.exists(current.genomes.file))
    return(get_basic_genomes())
  
  current.genomes.raw <-
    readLines(current.genomes.file, warn = FALSE, skipNul = TRUE)
  tbl.genomes <- jsonlite::fromJSON(current.genomes.raw)
  tbl.genomes$id
  
} # get_css_genomes
#-------------------------------------------------------------------------------
#' @title parseAndValidateGenomeSpec
#' @description a helper function for internal use by the igvShiny constructor, 
#' but possible also of use to those building an igvShiny app, 
#' to test their genome specification for validity
#'
#' @rdname  parseAndValidateGenomeSpec
#' @aliases parseAndValidateGenomeSpec
#'
#' @param genomeName character usually one short code of a supported ("stock") 
#' genome (e.g., "hg38") or for a user-supplied custom genome, 
#' the name you wish to use
#' @param initialLocus character default "all", otherwise "chrN:start-end" 
#' or a recognized gene symbol
#' @param stockGenome logical default TRUE
#' @param dataMode character either "stock", "localFile" or "http"
#' @param fasta character when supplying a custom (non-stock) genome, 
#' either a file path or a URL
#' @param fastaIndex character when supplying a custom (non-stock) genome, 
#' either a file path or a URL,
#' essential for all but the very small custom genomes.
#' @param genomeAnnotation character when supplying a custom (non-stock) genome,
#' a file path or URL pointing to a genome annotation file in
#' a gff3 format
#'
#' @examples
#' genomeSpec <-
#'   parseAndValidateGenomeSpec("hg38", "APOE")  # the simplest case
#' base.url <-
#'   "https://igv-data.systemsbiology.net/testFiles/sarsGenome"
#' fasta.file <-
#'   sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.dna.toplevel.fa")
#' fastaIndex.file <-
#'   sprintf("%s/%s",
#'           base.url,
#'           "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai")
#' annotation.file <-
#'   sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.101.gff3")
#' custom.genome.title <- "SARS-CoV-2"
#' genomeOptions <-
#'   parseAndValidateGenomeSpec(
#'     genomeName = custom.genome.title,
#'     initialLocus = "all",
#'     stockGenome = FALSE,
#'     dataMode = "http",
#'     fasta = fasta.file,
#'     fastaIndex = fastaIndex.file,
#'     genomeAnnotation = annotation.file
#'   )
#'
#' @seealso [get_css_genomes()] for stock genomes we support.
#'
#' @return an options list directly usable by igvApp.js, and thus igv.js
#' @keywords igvShiny
#' @export
#'
parseAndValidateGenomeSpec <- function(genomeName,
                                       initialLocus = "all",
                                       stockGenome = TRUE,
                                       dataMode = NA,
                                       fasta = NA,
                                       fastaIndex = NA,
                                       genomeAnnotation = NA) {
  options <- list()
  options[["stockGenome"]] <- stockGenome
  options[["dataMode"]] <- dataMode
  options[["validated"]] <- FALSE
  
  
  #--------------------------------------------------
  # first: is this a stock genome?  if so, we need
  # only check if the genomeName is recognized
  #--------------------------------------------------
  
  if (stockGenome) {
    if (!genomeName %in% get_cas_genomes()) {
      supported.stock.genomes <- get_css_genomes()
      if (!genomeName %in% supported.stock.genomes) {
        s.1 <-
          sprintf("Your genome '%s' is not currently supported",
                  genomeName)
        s.2 <-
          sprintf("Currently supported: %s",
                  paste(supported.stock.genomes, collapse = ","))
        msg <- sprintf("%s\n%s", s.1, s.2)
        stop(msg)
      }
    } # if not common & always available
    options[["genomeName"]] <- genomeName
    options[["initialLocus"]] <- initialLocus
    options[["fasta"]] <- NA
    options[["fastaIndex"]] <- NA
    options[["annotation"]] <- NA
    options[["validated"]] <- TRUE
  }# stockGenome requested
  
  if (!stockGenome) {
    stopifnot(!is.na(dataMode))
    stopifnot(!is.na(fasta))
    stopifnot(!is.na(fastaIndex))
    # genomeAnnotation is optional
    
    # "direct" for an in-memory R data structure, deferred
    recognized.modes <- c("localFiles", "http")  
    if (!dataMode %in% recognized.modes) {
      msg <-
        sprintf(
          "dataMode '%s' should be one of %s",
          dataMode,
          paste(recognized.modes, collapse = ",")
        )
      stop(msg)
    }
    #---------------------------------------------------------------------
    # dataMode determines how to check for the existence of each resource
    #---------------------------------------------------------------------
    
    exists.function <- switch(dataMode,
                              "localFiles" = file.exists,
                              "http" = RCurl::url.exists)
    stopifnot(exists.function(fasta))
    stopifnot(exists.function(fastaIndex))
    if (!is.na(genomeAnnotation))
      stopifnot(exists.function(genomeAnnotation))
    
    options[["genomeName"]]  <- genomeName
    options[["fasta"]] <- fasta
    options[["fastaIndex"]] <- fastaIndex
    options[["initialLocus"]] <- initialLocus
    options[["annotation"]] <- genomeAnnotation
    options[["validated"]] <- TRUE
  } # if !stockGenome
  
  return(options)
  
} # parseAndValidateGenomeSpec
#-------------------------------------------------------------------------------
