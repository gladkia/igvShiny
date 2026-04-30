# igvShiny: a wrapper of IGV in the Shiny apps

## igvShiny

The `igvShiny` package is a wrapper of Integrative Genomics Viewer
(IGV). It comprises an htmlwidget version of IGV. It can be used as a
module in Shiny apps.

## Installation

``` r

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("igvShiny")
```

## Loading the package

``` r

library(igvShiny)
```

## Running minimal Shiny app

Running the minimal Shiny app with igvShiny is as simple as:

- providing genome details via `parseAndValidateGenomeSpec`
- using `igvShinyOutput` as the UI function
- using `renderIgvShiny` as the server function

The he minimal Shiny app make look like:

``` r

library(igvShiny)
options <- parseAndValidateGenomeSpec(genomeName="hg38",  initialLocus="NDUFS2")
if (interactive()) {
    ui <- shinyUI(fluidPage(igvShinyOutput('igvShiny'), width = 10))
    server <-
        function(input, output, session) {
            output$igvShiny <- renderIgvShiny({
                igvShiny(options)
            })
            }
    runApp(shinyApp(ui = ui, server = server))
    }
```

## Providing genome details

Multiple genomes are currently supported by IGV:
[link](https://s3.amazonaws.com/igv.org.genomes/genomes.json). In
igvShiny this set of genomes is called stock genomes. One can select any
stock genome easily by running `parseAndValidateGenomeSpec` with single
`genomeName` value properly assigned. For example to use the most
popular mouse genome one need to run:

``` r

igvShiny::parseAndValidateGenomeSpec("mm10")
#> $stockGenome
#> [1] TRUE
#> 
#> $dataMode
#> [1] NA
#> 
#> $validated
#> [1] TRUE
#> 
#> $genomeName
#> [1] "mm10"
#> 
#> $initialLocus
#> [1] "all"
#> 
#> $fasta
#> [1] NA
#> 
#> $fastaIndex
#> [1] NA
#> 
#> $annotation
#> [1] NA
```

The list of available stock genomes in igvShiny can be found with:

``` r

igvShiny::get_css_genomes()
#>  [1] "hs1"             "chm13v1.1"       "hg38"            "hg38_1kg"       
#>  [5] "hg19"            "hg18"            "mm39"            "mm10"           
#>  [9] "mm9"             "rn7"             "rn6"             "gorGor6"        
#> [13] "gorGor4"         "panTro6"         "panTro5"         "panTro4"        
#> [17] "macFas5"         "GCA_011100615.1" "panPan2"         "canFam6"        
#> [21] "canFam5"         "canFam4"         "canFam3"         "bosTau9"        
#> [25] "bosTau8"         "susScr11"        "galGal6"         "GCF_016699485.2"
#> [29] "danRer11"        "danRer10"        "ce11"            "dm6"            
#> [33] "dm3"             "dmel_r5.9"       "sacCer3"         "ASM294v2"       
#> [37] "ASM985889v3"     "tair10"          "GCA_003086295.2" "GCF_001433935.1"
#> [41] "NC_016856.1"     "GCA_000182895.1"
```

See also demo app for stock genomes when one can select genome of
interest and familiarize with the basic functionalities provided via
igvShiny:

``` r

library(igvShiny)
demo_app_file <- system.file(package= "igvShiny", "demos", "stockGenomesDemo.R")
    if (interactive()) {
        shiny::runApp(demo_app_file)
        }
```

It’s also possible to use custom genomes (i.e. non-stock genomes). In
such cases one has to provide data for: `FASTA file`, `FASTA index file`
and `genome annotation file`. The files can provided as local paths
(`dataMode` = `localFiles` or via URLs (`dataMode = http`). See below
the examples for both cases.

``` r

library(igvShiny)

# defining custom genome with data provided via URLs
base_url <- "https://gladki.pl/igvr/testFiles"
title <- "ribo remote"
fasta_file <- sprintf("%s/%s", base_url, "ribosomal-RNA-gene.fasta")
fastaIndex_file <- sprintf("%s/%s", base_url, "ribosomal-RNA-gene.fasta.fai")
annotation_file <- sprintf("%s/%s", base_url, "ribosomal-RNA-gene.gff3")
locus <- "U13369.1:7,276-8,225"
genomeOptions <- parseAndValidateGenomeSpec(
    genomeName = title,
    initialLocus = locus,
    stockGenome = FALSE,
    dataMode = "http",
    fasta = fasta_file,
    fastaIndex = fastaIndex_file,
    genomeAnnotation = annotation_file
    )
genomeOptions
#> $stockGenome
#> [1] FALSE
#> 
#> $dataMode
#> [1] "http"
#> 
#> $validated
#> [1] TRUE
#> 
#> $genomeName
#> [1] "ribo remote"
#> 
#> $fasta
#> [1] "https://gladki.pl/igvr/testFiles/ribosomal-RNA-gene.fasta"
#> 
#> $fastaIndex
#> [1] "https://gladki.pl/igvr/testFiles/ribosomal-RNA-gene.fasta.fai"
#> 
#> $initialLocus
#> [1] "U13369.1:7,276-8,225"
#> 
#> $annotation
#> [1] "https://gladki.pl/igvr/testFiles/ribosomal-RNA-gene.gff3"

# defining custom genome with data provided with local files
data_directory <- system.file(package = "igvShiny", "extdata")
fasta_file      <- file.path(data_directory, "ribosomal-RNA-gene.fasta")
fastaIndex_file <- file.path(data_directory, "ribosomal-RNA-gene.fasta.fai")
annotation_file <- file.path(data_directory, "ribosomal-RNA-gene.gff3")
genomeOptions2 <- parseAndValidateGenomeSpec(
    genomeName = "ribo local",
    initialLocus = "U13369.1:7,276-8,225",
    stockGenome = FALSE,
    dataMode = "localFiles",
    fasta = fasta_file,
    fastaIndex = fastaIndex_file,
    genomeAnnotation = annotation_file
    )
genomeOptions2
#> $stockGenome
#> [1] FALSE
#> 
#> $dataMode
#> [1] "localFiles"
#> 
#> $validated
#> [1] TRUE
#> 
#> $genomeName
#> [1] "ribo local"
#> 
#> $fasta
#> [1] "/__w/_temp/Library/igvShiny/extdata/ribosomal-RNA-gene.fasta"
#> 
#> $fastaIndex
#> [1] "/__w/_temp/Library/igvShiny/extdata/ribosomal-RNA-gene.fasta.fai"
#> 
#> $initialLocus
#> [1] "U13369.1:7,276-8,225"
#> 
#> $annotation
#> [1] "/__w/_temp/Library/igvShiny/extdata/ribosomal-RNA-gene.gff3"
```

See also demo apps for custom genomes with data provided via URLs:

``` r

library(igvShiny)
demo_app_file <- system.file(
    package = "igvShiny", 
    "demos", 
    "igvShinyDemo-customGenome-http.R"
    )
if (interactive()) {
    shiny::runApp(demo_app_file)
    }
```

as well as data provided via local files:

``` r

library(igvShiny)
demo_app_file <-
    system.file(
        package = "igvShiny", 
        "demos", 
        "igvShinyDemo-customGenome-localFiles.R")
if (interactive()) {
    shiny::runApp(demo_app_file)
    }
```

## Main functionalities

In principle igvShiny provides the same functionalities that one can
find in igv.js. In summary following actions are currently possible
(wrapped as the R helpers):

- load tracks with the following formats/data types:
  - Bed
  - BedGraph
  - Seg
  - GWAS
  - Bam
  - Cram
  - Vcf
  - GFF3
- showGenomicRegion (zoom in or out to show the nominated region, by
  chromosome locus or gene symbol)
- getGenomicRegion (return the current IGV region)
- removeUserAddedTracks (remove tracks from the browser, added during
  the session by the user)

See also demo app to familiarize with the basic functionalities provided
by igvShiny:

``` r

library(igvShiny)
demo_app_file <- system.file(package= "igvShiny", "demos", "igvShinyDemo.R")
if (interactive()) {
    shiny::runApp(demo_app_file)
    }
```

## Session Info

``` r

sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
#>  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
#>  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
#>  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
#>  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
#> [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats4    stats     graphics  grDevices utils     datasets  methods  
#> [8] base     
#> 
#> other attached packages:
#> [1] igvShiny_1.9.2       shiny_1.13.0         GenomicRanges_1.62.1
#> [4] Seqinfo_1.0.0        IRanges_2.44.0       S4Vectors_0.48.1    
#> [7] BiocGenerics_0.56.0  generics_0.1.4       BiocStyle_2.38.0    
#> 
#> loaded via a namespace (and not attached):
#>  [1] sass_0.4.10             futile.options_1.0.1    stringi_1.8.7          
#>  [4] digest_0.6.39           magrittr_2.0.5          RColorBrewer_1.1-3     
#>  [7] evaluate_1.0.5          bookdown_0.46           fastmap_1.2.0          
#> [10] jsonlite_2.0.0          backports_1.5.1         formatR_1.14           
#> [13] promises_1.5.0          BiocManager_1.30.27     httr_1.4.8             
#> [16] scales_1.4.0            randomcoloR_1.1.0.1     textshaping_1.0.5      
#> [19] jquerylib_0.1.4         cli_3.6.6               rlang_1.2.0            
#> [22] futile.logger_1.4.9     cachem_1.1.0            yaml_2.3.12            
#> [25] otel_0.2.0              Rtsne_0.17              tools_4.5.2            
#> [28] checkmate_2.3.4         colorspace_2.1-2        httpuv_1.6.17          
#> [31] GenomeInfoDbData_1.2.15 lambda.r_1.2.4          curl_7.1.0             
#> [34] R6_2.6.1                mime_0.13               lifecycle_1.0.5        
#> [37] stringr_1.6.0           fs_2.1.0                V8_8.2.0               
#> [40] htmlwidgets_1.6.4       cluster_2.1.8.2         ragg_1.5.2             
#> [43] desc_1.4.3              pkgdown_2.2.0           bslib_0.10.0           
#> [46] later_1.4.8             glue_1.8.1              Rcpp_1.1.1-1.1         
#> [49] systemfonts_1.3.2       xfun_0.57               knitr_1.51             
#> [52] farver_2.1.2            xtable_1.8-8            htmltools_0.5.9        
#> [55] rmarkdown_2.31          compiler_4.5.2
```
