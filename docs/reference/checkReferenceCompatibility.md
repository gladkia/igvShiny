# Check reference compatibility between track data and genome specification

Compares contig naming conventions (e.g. UCSC `chr1` vs Ensembl `1`),
contig lengths (e.g. hg19 vs hg38), and coordinate boundaries between a
track (BAM, CRAM, VCF, BED, or Bioconductor object) and the active
reference genome.

## Usage

``` r
checkReferenceCompatibility(
  target,
  genomeName = NULL,
  genomeSpec = NULL,
  session = NULL,
  id = NULL
)
```

## Arguments

- target:

  A file path (.bam, .cram, .vcf, .vcf.gz, .bed) or data object
  (data.frame, GenomicAlignments, VCF, GRanges)

- genomeName:

  Character string, e.g. "hg38", "hg19", "mm10"

- genomeSpec:

  Named list of genome options, as produced by
  [`parseAndValidateGenomeSpec`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)

- session:

  Optional Shiny session object

- id:

  Optional widget element ID

## Value

A list with:

- `checked`: logical indicating whether both inputs could be inspected

- `compatible`: logical indicating if no critical mismatches were found,
  or `NA` when the inputs could not be checked

- `mismatches`: character vector of descriptive warning messages

- `details`: list of specific detected anomalies (naming, length,
  out-of-bounds)

- `targetAssembly`: detected assembly of track, if recognized

- `referenceAssembly`: reference genome name

## Examples

``` r
bamFile <- system.file(package = "igvShiny", "extdata", "tumor.bam")
# tumor.bam is GRCh38: compatible with hg38, incompatible with hg19
res1 <- checkReferenceCompatibility(bamFile, genomeName = "hg38")
res1$compatible  # TRUE
#> [1] TRUE

res2 <- checkReferenceCompatibility(bamFile, genomeName = "hg19")
res2$compatible  # FALSE
#> [1] FALSE
```
