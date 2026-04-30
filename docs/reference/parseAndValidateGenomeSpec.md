# parseAndValidateGenomeSpec

a helper function for internal use by the igvShiny constructor, but
possible also of use to those building an igvShiny app, to test their
genome specification for validity

## Usage

``` r
parseAndValidateGenomeSpec(
  genomeName,
  initialLocus = "all",
  stockGenome = TRUE,
  dataMode = NA,
  fasta = NA,
  fastaIndex = NA,
  genomeAnnotation = NA
)
```

## Arguments

- genomeName:

  character usually one short code of a supported ("stock") genome
  (e.g., "hg38") or for a user-supplied custom genome, the name you wish
  to use

- initialLocus:

  character default "all", otherwise "chrN:start-end" or a recognized
  gene symbol

- stockGenome:

  logical default TRUE

- dataMode:

  character either "stock", "localFile" or "http"

- fasta:

  character when supplying a custom (non-stock) genome, either a file
  path or a URL

- fastaIndex:

  character when supplying a custom (non-stock) genome, either a file
  path or a URL, essential for all but the very small custom genomes.

- genomeAnnotation:

  character when supplying a custom (non-stock) genome, a file path or
  URL pointing to a genome annotation file in a gff3 format

## Value

an options list directly usable by igvApp.js, and thus igv.js

## See also

\[get_css_genomes()\] for stock genomes we support.

## Examples

``` r
genomeSpec <-
  parseAndValidateGenomeSpec("hg38", "APOE")  # the simplest case
base.url <-
  "https://gladki.pl/igvr/testFiles/sarsGenome"
fasta.file <-
  sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.dna.toplevel.fa")
fastaIndex.file <-
  sprintf("%s/%s",
          base.url,
          "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai")
annotation.file <-
  sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.101.gff3")
custom.genome.title <- "SARS-CoV-2"
genomeOptions <-
  parseAndValidateGenomeSpec(
    genomeName = custom.genome.title,
    initialLocus = "all",
    stockGenome = FALSE,
    dataMode = "http",
    fasta = fasta.file,
    fastaIndex = fastaIndex.file,
    genomeAnnotation = annotation.file
  )
```
