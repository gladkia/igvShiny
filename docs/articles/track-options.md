# Track options reference

``` r

library(igvShiny)
futile.logger::flog.threshold(futile.logger::WARN)
```

## What this vignette is

Every track type `igvShiny` can load, and the options each one accepts.
If you are looking for how to get a browser onto the page in the first
place, start with the *Getting started with igvShiny* vignette instead.

The options are igv.js options: `igvShiny` passes them through rather
than reinventing them, and the names below are the ones the bundled
igv.js (currently 3.8.4) actually reads.

## How an option reaches the browser

Every loader takes a `trackConfig` argument: a named list merged into
the track configuration sent to igv.js.

The examples here run against a stand-in `session` that prints the
message instead of sending it to a browser, so you can see what igv.js
is handed — including the defaults the loader fills in:

``` r

tbl <- data.frame(
    chrom = "chr1",
    start = 7432000,
    end = 7436000
    )

loadBedTrack(
    session,
    id = "igv",
    trackName = "my regions",
    tbl = tbl,
    trackConfig = list(displayMode = "EXPANDED", maxRows = 20)
    )
#> removeTracksByName
#>   trackNames: my regions
#>   elementID: igv
#> loadBedTrackFromFile
#>   elementID: igv
#>   trackName: my regions
#>   bedFilepath: tracks/file1afecf89fe7.bed
#>   color: 
#>   trackHeight: 50
#>   displayMode: EXPANDED
#>   maxRows: 20
```

The frequently used options are also plain arguments on the loaders that
need them — `color`, `trackHeight`, `displayMode` and so on. Both routes
end up in the same place, so use whichever reads better. Giving the same
option twice is not an error: the explicit argument wins, and you are
told so.

Keys are checked against an allowlist before they are sent, and a key
that is not on it is dropped. Startup tracks go through the same check,
and
[`igvShiny()`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)
builds outside a Shiny session, so the behaviour is visible here:

``` r

genomeOptions <- parseAndValidateGenomeSpec(
    genomeName = "hg38",
    initialLocus = "NDUFS2"
    )

widget <- igvShiny(
    genomeOptions,
    tracks = list(
        list(
            name = "genes",
            type = "annotation",
            url = "https://example.org/genes.bed",
            onClick = "alert('hi')"
            )
        )
    )
#> Warning in FUN(X[[i]], ...): Ignoring invalid or unsupported track options in
#> 'tracks': onClick

names(widget$x$tracks[[1]])
#> [1] "name" "type" "url"
```

That is the mechanism, not a nuisance: a track configuration is a
JavaScript object built from user input, and only names known to be data
options are let through. The consequence to remember is that a typo does
not reach igv.js and does not raise an error — it produces a warning and
a track drawn with defaults.

## Loaders

| Function | Data comes from | igv.js track |
|----|----|----|
| [`loadBedTrack()`](https://gladkia.github.io/igvShiny/reference/loadBedTrack.md) | `data.frame` | annotation |
| [`loadBedGraphTrack()`](https://gladkia.github.io/igvShiny/reference/loadGenomeAnnotationTrack.md) | `data.frame` | wig |
| [`loadBedGraphTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadBedGraphTrackFromURL.md) | URL | wig |
| [`loadSegTrack()`](https://gladkia.github.io/igvShiny/reference/loadSEGTrack.md) | `data.frame` | seg |
| [`loadGwasTrack()`](https://gladkia.github.io/igvShiny/reference/loadGwasTrack.md) | `data.frame` | gwas |
| [`loadVcfTrack()`](https://gladkia.github.io/igvShiny/reference/loadVcfTrack.md) | `VCF` object | variant |
| [`loadGFF3TrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadGFF3TrackFromLocalData.md) | `data.frame` | annotation |
| [`loadGFF3TrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadGFF3TrackFromURL.md) | URL | annotation |
| [`loadBamTrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromLocalData.md) | `GAlignments` | alignment |
| [`loadBamTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromURL.md) | URL | alignment |
| [`loadCramTrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadCramTrackFromLocalData.md) | file on disk | alignment |
| [`loadCramTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadCramTrackFromURL.md) | URL | alignment |
| [`loadSpliceJunctionTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadSpliceJunctionTrackFromURL.md) | URL | junction |

The `FromURL` variants ask the *user’s browser* to fetch the file. A URL
that works in
[`download.file()`](https://rdrr.io/r/utils/download.file.html) can
still fail here if the server sends no permissive CORS header — see the
troubleshooting section of the getting started vignette.

## Options every track accepts

| Option | Type | What it does |
|----|----|----|
| `name` | character | track label in the left panel |
| `url` | character | where the data is |
| `indexURL` | character | index for a bgzipped or binary file |
| `indexed` | logical | set `FALSE` to read an unindexed file whole |
| `format` | character | `"bed"`, `"gff3"`, `"bigwig"`, `"vcf"`, … |
| `type` | character | igv.js track class; usually implied by the loader |
| `order` | numeric | position among the other tracks |
| `height` | numeric | track height in pixels |
| `minHeight`, `maxHeight` | numeric | bounds when the track resizes itself |
| `autoHeight` | logical | grow to fit the features in view |
| `visibilityWindow` | numeric | above this span in bp, draw nothing |
| `removable` | logical | whether the user may close the track |
| `color` | character | any CSS colour |
| `altColor` | character | second colour, per track type |
| `displayMode` | character | `"COLLAPSED"`, `"EXPANDED"`, `"SQUISHED"` |
| `roi` | list | regions of interest drawn over this track |
| `oauthToken`, `headers` | character, list | sent with the data request |

`trackHeight` on the loaders and `height` in `trackConfig` are the same
thing.

## Numeric tracks: bedGraph, wig, bigWig

| Option              | Type      | What it does                                |
|---------------------|-----------|---------------------------------------------|
| `autoscale`         | logical   | rescale to the data in view                 |
| `autoscaleGroup`    | character | scale several tracks together, as one group |
| `min`, `max`        | numeric   | fixed data range when not autoscaling       |
| `logScale`          | logical   | log the y axis                              |
| `graphType`         | character | `"bar"` or `"points"`                       |
| `flipAxis`          | logical   | draw the y axis upside down                 |
| `color`, `altColor` | character | values above and below the baseline         |

``` r

coverage <- data.frame(
    chrom = "chr1",
    start = c(7432000, 7437000),
    end = c(7436000, 7442000),
    value = c(0.2, 0.9)
    )

loadBedGraphTrack(
    session, id = "igv", trackName = "coverage", tbl = coverage,
    autoscale = TRUE,
    trackConfig = list(
        graphType = "points",
        autoscaleGroup = "sampleA",
        logScale = FALSE
        )
    )
#> removeTracksByName
#>   trackNames: coverage
#>   elementID: igv
#> Warning in .sanitizeAndMergeOptions(base.msg.to.igv, trackConfig):
#> User-provided trackConfig options conflict with function arguments and will be
#> ignored: autoscaleGroup
#> loadBedGraphTrack
#>   elementID: igv
#>   trackName: coverage
#>   tbl: [{"chr":"chr1","start":7432000,"end":7436000,"value":0.2},{"chr":"chr1","start":7437000,"end":7442000,"value":0.9}]
#>   color: gray
#>   trackHeight: 30
#>   autoscale: TRUE
#>   min: NA
#>   max: NA
#>   autoscaleGroup: -1
#>   graphType: points
#>   logScale: FALSE
```

Two tracks sharing an `autoscaleGroup` are drawn on one scale, which is
what makes their heights comparable by eye.

## Annotation tracks: bed, gff3

| Option          | Type      | What it does                              |
|-----------------|-----------|-------------------------------------------|
| `colorBy`       | character | feature attribute to take the colour from |
| `colorTable`    | list      | attribute value to colour                 |
| `featureHeight` | numeric   | height of one feature row                 |
| `maxRows`       | numeric   | rows drawn before the rest are hidden     |
| `searchable`    | logical   | let the locus box find features by name   |
| `queryable`     | logical   | whether the track answers region queries  |

On
[`loadGFF3TrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadGFF3TrackFromURL.md)
and
[`loadGFF3TrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadGFF3TrackFromLocalData.md)
the argument is called `colorByAttribute`, and it becomes igv.js
`colorBy`. Pass it as the loader argument rather than in `trackConfig`,
together with `colorTable`:

``` r

gff3.url <- paste0(
    "https://s3.amazonaws.com/igv.org.genomes/hg38/",
    "Homo_sapiens.GRCh38.94.chr.gff3.gz"
    )

loadGFF3TrackFromURL(
    session, id = "igv", trackName = "genes",
    gff3URL = gff3.url, indexURL = paste0(gff3.url, ".tbi"),
    colorByAttribute = "biotype",
    displayMode = "EXPANDED",
    visibilityWindow = 1000000,
    colorTable = list(
        protein_coding = "darkgreen",
        processed_transcript = "blue",
        default = "black"
        )
    )
#> removeTracksByName
#>   trackNames: genes
#>   elementID: igv
#> loadGFF3TrackFromURL
#>   elementID: igv
#>   trackName: genes
#>   dataURL: https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz
#>   indexURL: https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz.tbi
#>   color: gray
#>   colorTable: darkgreen,blue,black
#>   colorByAttribute: biotype
#>   displayMode: EXPANDED
#>   trackHeight: 50
#>   visibilityWindow: 1e+06
```

A `default` entry in `colorTable` catches the values you did not list.

## Alignment tracks: bam, cram

| Option | Type | What it does |
|----|----|----|
| `showAllBases` | logical | draw every base, not just mismatches |
| `viewAsPairs` | logical | join mates on one row |
| `colorBy` | character | `"strand"`, `"firstOfPairStrand"`, `"tag"`, … |
| `colorTable` | list | value to colour, for `colorBy = "tag"` |
| `sort` | list | how reads are sorted when the track loads |
| `samplingWindowSize` | numeric | window the downsampler works over |
| `samplingDepth` | numeric | reads kept per window |

`sort` takes the same object the igv.js right-click menu builds, so
sorting by a tag at load time is:

``` r

bam.url <- "https://1000genomes.s3.amazonaws.com/phase3/NA12878.bam"

loadBamTrackFromURL(
    session, id = "igv", trackName = "reads",
    bamURL = bam.url, indexURL = paste0(bam.url, ".bai"),
    trackConfig = list(
        sort = list(
            option = "TAG", tag = "HP",
            chr = "chr8", position = 128750000
            )
        )
    )
#> removeTracksByName
#>   trackNames: reads
#>   elementID: igv
#> loadBamTrackFromURL
#>   elementID: igv
#>   trackName: reads
#>   bam: https://1000genomes.s3.amazonaws.com/phase3/NA12878.bam
#>   index: https://1000genomes.s3.amazonaws.com/phase3/NA12878.bam.bai
#>   displayMode: EXPANDED
#>   showAllBases: FALSE
#>   sort: TAG,HP,chr8,128750000
```

Alignment tracks are the memory-hungry ones. `visibilityWindow` matters
here more than anywhere else: without it a user who zooms out asks the
browser for every read on the chromosome.

## Variant tracks: vcf

| Option        | Type      | What it does                      |
|---------------|-----------|-----------------------------------|
| `colorBy`     | character | variant attribute to colour by    |
| `colorTable`  | list      | attribute value to colour         |
| `maxRows`     | numeric   | genotype rows drawn               |
| `sort`        | list      | initial sort of the genotype rows |
| `displayMode` | character | `"COLLAPSED"` hides the genotypes |

## GWAS tracks

| Option       | Type      | What it does                                    |
|--------------|-----------|-------------------------------------------------|
| `trait`      | character | column holding the trait name                   |
| `columns`    | list      | **1-based** column positions in the source file |
| `min`, `max` | numeric   | y range, in -log10(p)                           |
| `autoscale`  | logical   | rescale to the data in view                     |
| `colorTable` | list      | chromosome to colour                            |

`columns` is worth its own note. The GWAS parser reads it 1-based, and
without it the parser guesses the layout from header names it recognises
— any other spelling draws an empty track rather than an error:

``` r

gwas <- data.frame(
    CHR = "chr1",
    BP = c(1000, 2000),
    SNP = c("rs1", "rs2"),
    P = c(1e-8, 1e-5)
    )

loadGwasTrack(
    session, id = "igv", trackName = "gwas", tbl.gwas = gwas,
    trackConfig = list(
        columns = list(chromosome = 12, position = 13, value = 28)
        )
    )
#> removeTracksByName
#>   trackNames: gwas
#>   elementID: igv
#> loadGwasTrack
#>   elementID: igv
#>   trackName: gwas
#>   gwasDataFilepath: tracks/file1afe110f608.gwas
#>   color: red
#>   trackHeight: 200
#>   autoscale: FALSE
#>   min: 0
#>   max: 35
#>   columns: 12,13,28
```

The `GWASTrack` class is the other way into the same track type, for
data that already lives at a URL; see
[`?GWASTrack`](https://gladkia.github.io/igvShiny/reference/GWASTrack-class.md).

## Splice junction tracks

Junction options divide into filters, which decide whether an arc is
drawn at all, and appearance.

Filters:

| Option | Type | What it does |
|----|----|----|
| `minUniquelyMappedReads` | numeric | drop junctions below this count |
| `minTotalReads` | numeric | unique plus multi-mapped |
| `maxFractionMultiMappedReads` | numeric | drop mostly multi-mapped junctions |
| `minSplicedAlignmentOverhang` | numeric | shortest anchor accepted |
| `minJunctionEndsVisible` | numeric | 0, 1 or 2 ends in view |
| `minSamplesWithThisJunction` | numeric | across samples |
| `maxSamplesWithThisJunction` | numeric | across samples |
| `minPercentSamplesWithThisJunction` | numeric | as a percentage |
| `maxPercentSamplesWithThisJunction` | numeric | as a percentage |
| `hideAnnotatedJunctions` | logical | draw novel junctions only |
| `hideUnannotatedJunctions` | logical | draw annotated junctions only |
| `hideMotifs` | character | motifs to leave out, e.g. `c("GT/AG")` |
| `hideStrand` | character | `"+"` or `"-"` |

Appearance:

| Option                     | Type      | What it does                         |
|----------------------------|-----------|--------------------------------------|
| `thicknessBasedOn`         | character | what sets the arc thickness          |
| `bounceHeightBasedOn`      | character | what sets how high the arc rises     |
| `colorBy`                  | character | what sets the arc colour             |
| `colorByNumReadsThreshold` | numeric   | split point for read-count colouring |
| `labelWith`                | character | what the arc label shows             |
| `labelWithInParen`         | character | a second value, in parentheses       |

The three `...BasedOn` and `colorBy` options take a fixed vocabulary:

- `thicknessBasedOn`: `"numUniqueReads"`, `"numReads"`,
  `"isAnnotatedJunction"`
- `bounceHeightBasedOn`: `"random"`, `"distance"`, `"thickness"`
- `colorBy`: `"numUniqueReads"`, `"numReads"`, `"isAnnotatedJunction"`,
  `"strand"`, `"motif"`

``` r

junctions.url <- paste0(
    "https://raw.githubusercontent.com/igvteam/igv-data/main/data/test/",
    "splice_junctions/sampleA.SJ.out.bed.gz"
    )

loadSpliceJunctionTrackFromURL(
    session, id = "igv", trackName = "sampleA junctions",
    url = junctions.url, indexURL = paste0(junctions.url, ".tbi"),
    trackHeight = 150,
    trackConfig = list(
        colorBy = "motif",
        labelWith = "uniquelyMapped",
        minUniquelyMappedReads = 5,
        hideAnnotatedJunctions = FALSE
        )
    )
#> removeTracksByName
#>   trackNames: sampleA junctions
#>   elementID: igv
#> loadSpliceJunctionTrackFromURL
#>   elementID: igv
#>   trackName: sampleA junctions
#>   url: https://raw.githubusercontent.com/igvteam/igv-data/main/data/test/splice_junctions/sampleA.SJ.out.bed.gz
#>   indexURL: https://raw.githubusercontent.com/igvteam/igv-data/main/data/test/splice_junctions/sampleA.SJ.out.bed.gz.tbi
#>   trackHeight: 150
#>   displayMode: COLLAPSED
#>   colorBy: motif
#>   labelWith: uniquelyMapped
#>   minUniquelyMappedReads: 5
#>   hideAnnotatedJunctions: FALSE
```

The filter names come from the igv.js source rather than from the
`spliceJunctionTrack.html` example page that ships with it: that example
sets `labelUniqueReadCount` and four siblings, and no such option exists
in the library any more.

## Options on startup tracks

Tracks passed to
[`igvShiny()`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)
through `tracks` are checked against the same allowlist, so everything
above applies to them too. What they additionally need is a `url`, since
there is no loader argument to carry the data: an entry without a usable
one is dropped with a warning.

``` r

gff3.url <- paste0(
    "https://s3.amazonaws.com/igv.org.genomes/hg38/",
    "Homo_sapiens.GRCh38.94.chr.gff3.gz"
    )

startupTrack <- list(
    name = "genes",
    type = "annotation",
    format = "gff3",
    url = gff3.url,
    indexed = FALSE,
    displayMode = "EXPANDED"
    )

widget <- igvShiny(genomeOptions, tracks = list(startupTrack))
str(widget$x$tracks[[1]])
#> List of 6
#>  $ name       : chr "genes"
#>  $ type       : chr "annotation"
#>  $ format     : chr "gff3"
#>  $ url        : chr "https://s3.amazonaws.com/igv.org.genomes/hg38/Homo_sapiens.GRCh38.94.chr.gff3.gz"
#>  $ indexed    : logi FALSE
#>  $ displayMode: chr "EXPANDED"
```

In an app that goes inside
[`renderIgvShiny()`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md):

``` r

output$igv <- renderIgvShiny({
    igvShiny(genomeOptions, tracks = list(startupTrack))
    })
```

## When an option seems to do nothing

**Check for the warning first.** A dropped key says so on the R console.
If there is no warning, the option reached igv.js and the problem is
elsewhere.

**An option igv.js does not know is ignored in silence** once past the
allowlist. igv.js reads the keys it recognises and never complains about
the rest, so a correct-looking option from IGV desktop, or from an older
igv.js, produces a track drawn with defaults and no message anywhere.

**Some options apply to one track type only.** `autoscale` on an
annotation track, `colorBy = "motif"` on anything that is not a junction
track: both are accepted, and both do nothing.

When you need an option this vignette does not list, the [igv.js
wiki](https://github.com/igvteam/igv.js/wiki) documents the underlying
browser. If it is genuinely missing from the allowlist rather than
misspelled, that is worth [an
issue](https://github.com/gladkia/igvShiny/issues) — the list covers the
options that are useful from R, and it grows.

## Session Info

``` r

sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
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
#> [1] igvShiny_1.9.42      shiny_1.14.0         GenomicRanges_1.65.1
#> [4] Seqinfo_1.3.0        IRanges_2.47.2       S4Vectors_0.51.6    
#> [7] BiocGenerics_0.59.12 generics_0.1.4       BiocStyle_2.41.0    
#> 
#> loaded via a namespace (and not attached):
#>  [1] sass_0.4.10             futile.options_1.0.1    stringi_1.8.9          
#>  [4] digest_0.6.39           magrittr_2.0.5          RColorBrewer_1.1-3     
#>  [7] evaluate_1.0.5          bookdown_0.47           fastmap_1.2.0          
#> [10] jsonlite_2.0.0          backports_1.5.1         formatR_1.14           
#> [13] promises_1.5.0          BiocManager_1.30.27     httr_1.4.8             
#> [16] scales_1.4.0            randomcoloR_1.1.0.1     textshaping_1.0.5      
#> [19] jquerylib_0.1.4         cli_3.6.6               rlang_1.3.0            
#> [22] futile.logger_1.4.9     cachem_1.1.0            yaml_2.3.12            
#> [25] otel_0.2.0              Rtsne_0.17              tools_4.6.1            
#> [28] checkmate_2.3.4         colorspace_2.1-3        httpuv_1.6.17          
#> [31] GenomeInfoDbData_1.2.15 lambda.r_1.2.4          curl_7.1.0             
#> [34] R6_2.6.1                mime_0.13               lifecycle_1.0.5        
#> [37] stringr_1.6.0           fs_2.1.0                V8_8.2.0               
#> [40] htmlwidgets_1.6.4       cluster_2.1.8.3         ragg_1.5.2             
#> [43] desc_1.4.3              pkgdown_2.2.1           bslib_0.12.0           
#> [46] later_1.4.8             glue_1.8.1              Rcpp_1.1.2             
#> [49] systemfonts_1.3.2       xfun_0.60               knitr_1.51             
#> [52] farver_2.1.2            xtable_1.8-8            htmltools_0.5.9        
#> [55] rmarkdown_2.31          compiler_4.6.1
```
