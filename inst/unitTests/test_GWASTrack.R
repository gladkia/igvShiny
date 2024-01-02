library(igvShiny)
library(RUnit)
#----------------------------------------------------------------------------------------------------
runTests <- function()
{
   test_dataFrameConstructor()
   test_urlConstructor()
   test_illegalArguments()

} # runTests
#----------------------------------------------------------------------------------------------------
test_dataFrameConstructor <- function()
{
    message(sprintf("--- test_dataFrameConstructor"))

    f <- system.file(package="igvShiny", "extdata", "gwas.RData")
    tbl.gwas <- get(load(f))

    gwasTrack <- GWASTrack("data.frame gwas",
                           tbl.gwas,
                           chrom.col=3,
                           pos.col=4,
                           pval.col=10,
                           trackHeight=100)
    url <- getUrl(gwasTrack)  # e.g.  "tracks/file123ab627a0689.gwas"
    checkTrue(grepl("tracks.*\\.gwas", url))

} # test_dataFrameConstructor
#----------------------------------------------------------------------------------------------------
test_urlConstructor <- function()
{
    message(sprintf("--- test_urlConstructor"))

    url <- "https://s3.amazonaws.com/igv.org.demo/gwas_sample.tsv.gz"
    gwasTrack <- GWASTrack("remote url gwas",
                           url,
                           chrom.col=3,
                           pos.col=4,
                           pval.col=10,
                           trackHeight=100)
    url.retrieved <- getUrl(gwasTrack)
    checkEquals(url, url.retrieved)

} # test_urlConstructor
#----------------------------------------------------------------------------------------------------
test_illegalArguments <- function()
{
    message(sprintf("--- test_illegalArguments"))

    checkException(
        gwasTrack <- GWASTrack("bogus url",
                               data="https://bogus.org/nonexistent.gwas",
                               chrom.col=3,
                               pos.col=4,
                               pval.col=10,
                               color="darkgreen",
                               trackHeight=100),
        "bogus url", silent=TRUE)

    checkException(
        gwasTrack <- GWASTrack("bogus url",
                               data=42,
                               chrom.col=3,
                               pos.col=4,
                               pval.col=10,
                               color="darkgreen",
                               trackHeight=100),
        "nonsense data", silent=TRUE)


} # test_illegalArguments
#----------------------------------------------------------------------------------------------------
if(!interactive())
    runTests()
