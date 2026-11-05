# VariantTrack: variants from a VariantAnnotation VCF object

A `VariantTrack` holds a `VCF` object (needs the suggested package
VariantAnnotation), written to a vcf file at display time, or the urls
of a served vcf and its index. Display it with
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md),
which sends color (from `anchorColor`), the three genotype colors,
displayMode, trackHeight (as height) and visibilityWindow to igv.js. Url
tracks have no igvShiny browser handler yet, so `loadTrack` refuses
them.

## Usage

``` r
VariantTrack(
  trackName,
  vcf,
  trackHeight = 50,
  anchorColor = "pink",
  homvarColor = "rgb(17,248,254)",
  hetvarColor = "rgb(34,12,253)",
  homrefColor = "rgb(200,200,200)",
  displayMode = "EXPANDED",
  visibilityWindow = 1e+05
)
```

## Arguments

- trackName:

  A character string, used as track label by igv

- vcf:

  a `VCF` object, or a list with the urls `data` and `index`

- trackHeight:

  track height in pixels

- anchorColor:

  CSS color of the variant row

- homvarColor:

  CSS color of homozygous variant genotypes

- hetvarColor:

  CSS color of heterozygous variant genotypes

- homrefColor:

  CSS color of homozygous reference genotypes

- displayMode:

  "COLLAPSED", "SQUISHED" or "EXPANDED"

- visibilityWindow:

  Maximum window size in base pairs for which variants are displayed

## Value

An object of class VariantTrack

## Slots

- `displayMode`:

  character, "COLLAPSED", "SQUISHED" or "EXPANDED"

- `vcf.obj`:

  a `VCF` object, or NULL for a url track

- `vcf.url`:

  list with the urls `data` and `index`, or empty

- `anchorColor`:

  character, the variant color

- `homvarColor`:

  character, homozygous variant genotype color

- `hetvarColor`:

  character, heterozygous variant genotype color

- `homrefColor`:

  character, homozygous reference genotype color

## Examples

``` r
if (requireNamespace("VariantAnnotation", quietly = TRUE)) {
  f <- system.file(package = "igvShiny", "extdata",
                   "chr19-cebpaRegion.vcf.gz")
  vcf <- VariantAnnotation::readVcf(f, "hg38")
  track <- VariantTrack("cebpa variants", vcf)
  trackSize(track)
}
#> [1] 162
```
