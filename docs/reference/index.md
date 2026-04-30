# Package index

## igvShiny

- [`.sanitizeAndMergeOptions()`](https://gladkia.github.io/igvShiny/reference/dot-sanitizeAndMergeOptions.md)
  : Sanitize and merge track configuration options
- [`igvShiny()`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)
  : Create an igvShiny instance
- [`igvShinyOutput()`](https://gladkia.github.io/igvShiny/reference/igvShinyOutput.md)
  : create the UI for the widget
- [`parseAndValidateGenomeSpec()`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)
  : parseAndValidateGenomeSpec
- [`removeTracksByName()`](https://gladkia.github.io/igvShiny/reference/removeTracksByName.md)
  : remove tracks from the browser
- [`removeUserAddedTracks()`](https://gladkia.github.io/igvShiny/reference/removeUserAddedTracks.md)
  : remove only those tracks explicitly added by your app
- [`renderIgvShiny()`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md)
  : draw the igv genome browser element
- [`showGenomicRegion()`](https://gladkia.github.io/igvShiny/reference/showGenomicRegion.md)
  [`getGenomicRegion()`](https://gladkia.github.io/igvShiny/reference/showGenomicRegion.md)
  : focus igv on a region

## Track loaders

- [`loadBamTrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromLocalData.md)
  : load GenomicAlignments data as an igv.js alignment track
- [`loadBamTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromURL.md)
  : load a bam track which, with index, is served up by http
- [`loadBedGraphTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadBedGraphTrackFromURL.md)
  : load a bedgraph track from a URL
- [`loadBedTrack()`](https://gladkia.github.io/igvShiny/reference/loadBedTrack.md)
  : load a bed track provided as a data.frame
- [`loadCramTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadCramTrackFromURL.md)
  : load a cram track which, with index, is served up by http
- [`loadGFF3TrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadGFF3TrackFromLocalData.md)
  : load a GFF3 track defined by local data
- [`loadGFF3TrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadGFF3TrackFromURL.md)
  : load a GFF3 track which, with index, is served up by http
- [`loadBedGraphTrack()`](https://gladkia.github.io/igvShiny/reference/loadGenomeAnnotationTrack.md)
  : load a scored genome annotation track provided as a data.frame
- [`loadGwasTrack()`](https://gladkia.github.io/igvShiny/reference/loadGwasTrack.md)
  : load a GWAS (genome-wide association study) track provided as a
  data.frame
- [`loadSegTrack()`](https://gladkia.github.io/igvShiny/reference/loadSEGTrack.md)
  : load a seg track provided as a data.frame
- [`loadVcfTrack()`](https://gladkia.github.io/igvShiny/reference/loadVcfTrack.md)
  : load a VCF (variant) track provided as a Bioconductor
  VariantAnnotation object

## GWASTrack class

- [`GWASTrack()`](https://gladkia.github.io/igvShiny/reference/GWASTrack-class.md)
  : Constructor for GWASTrack
- [`display(`*`<GWASTrack>`*`)`](https://gladkia.github.io/igvShiny/reference/display.md)
  : display the already constructed and configured track
- [`getUrl(`*`<GWASTrack>`*`)`](https://gladkia.github.io/igvShiny/reference/getUrl.md)
  : the url of the gwas table

## Utils

- [`get_basic_genomes()`](https://gladkia.github.io/igvShiny/reference/get_basic_genomes.md)
  : get_basic_genomes
- [`get_cas_genomes()`](https://gladkia.github.io/igvShiny/reference/get_cas_genomes.md)
  : get_cas_genomes
- [`get_css_genomes()`](https://gladkia.github.io/igvShiny/reference/get_css_genomes.md)
  : get_css_genomes
- [`get_tracks_dir()`](https://gladkia.github.io/igvShiny/reference/get_tracks_dir.md)
  : get_tracks_dir Get the directory where tracks are stored. The
  directory can be defined with environmental variable. If not defined
  the default is a directory called "tracks" in the temp directory. We
  need a local directory to write files - for instance, a vcf file
  representing a genomic region of interest. We then tell shiny about
  that directory, so that shiny's built-in http server can serve up
  files we write there, ultimately consumed by igv.js
