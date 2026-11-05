# Package index

## igvShiny

- [`.packJunctionAttributes()`](https://gladkia.github.io/igvShiny/reference/dot-packJunctionAttributes.md)
  : Pack junction attributes into a bed name column
- [`.sanitizeAndMergeOptions()`](https://gladkia.github.io/igvShiny/reference/dot-sanitizeAndMergeOptions.md)
  : Sanitize and merge track configuration options
- [`.sanitizeTrack()`](https://gladkia.github.io/igvShiny/reference/dot-sanitizeTrack.md)
  : Sanitize one startup track specification
- [`.sanitizeTracks()`](https://gladkia.github.io/igvShiny/reference/dot-sanitizeTracks.md)
  : Sanitize a list of startup track specifications
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
- [`loadBamTrackFromLocalFile()`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromLocalFile.md)
  : Load a BAM Track from a Local File via HTTP Range Requests
- [`loadBamTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromURL.md)
  : load a bam track which, with index, is served up by http
- [`loadBedGraphTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadBedGraphTrackFromURL.md)
  : load a bedgraph track from a URL
- [`loadBedTrack()`](https://gladkia.github.io/igvShiny/reference/loadBedTrack.md)
  : load a bed track provided as a data.frame
- [`loadCramTrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadCramTrackFromLocalData.md)
  [`loadCramTrackFromLocalFile()`](https://gladkia.github.io/igvShiny/reference/loadCramTrackFromLocalData.md)
  : load a cram file sitting on the same machine as the shiny app
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
- [`loadSpliceJunctionTrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadSpliceJunctionTrackFromLocalData.md)
  : load a splice junction track from a data.frame
- [`loadSpliceJunctionTrackFromURL()`](https://gladkia.github.io/igvShiny/reference/loadSpliceJunctionTrackFromURL.md)
  : load a splice junction track served up by http
- [`loadTrack()`](https://gladkia.github.io/igvShiny/reference/loadTrack.md)
  : Display a track object in an igvShiny widget
- [`loadVcfTrack()`](https://gladkia.github.io/igvShiny/reference/loadVcfTrack.md)
  : load a VCF (variant) track provided as a Bioconductor
  VariantAnnotation object

## Track classes

- [`BedpeInteractionsTrack()`](https://gladkia.github.io/igvShiny/reference/BedpeInteractionsTrack-class.md)
  : BedpeInteractionsTrack: paired-end interactions from a bedpe
  data.frame
- [`GFF3Track()`](https://gladkia.github.io/igvShiny/reference/GFF3Track-class.md)
  : GFF3Track: gene models from a GFF3 data.frame or url
- [`GenomicAlignmentTrack()`](https://gladkia.github.io/igvShiny/reference/GenomicAlignmentTrack-class.md)
  [`RemoteAlignmentTrack()`](https://gladkia.github.io/igvShiny/reference/GenomicAlignmentTrack-class.md)
  [`CramTrack()`](https://gladkia.github.io/igvShiny/reference/GenomicAlignmentTrack-class.md)
  : Alignment tracks: in-memory reads, a bam url or a cram url
- [`QuantitativeTrack()`](https://gladkia.github.io/igvShiny/reference/QuantitativeTrack-class.md)
  [`DataFrameQuantitativeTrack()`](https://gladkia.github.io/igvShiny/reference/QuantitativeTrack-class.md)
  [`GRangesQuantitativeTrack()`](https://gladkia.github.io/igvShiny/reference/QuantitativeTrack-class.md)
  [`UCSCBedGraphQuantitativeTrack()`](https://gladkia.github.io/igvShiny/reference/QuantitativeTrack-class.md)
  : Quantitative tracks: scored intervals from a data.frame, GRanges or
  UCSCData
- [`Track()`](https://gladkia.github.io/igvShiny/reference/Track-class.md)
  : Track: the base class of igvShiny's S4 tracks
- [`VariantTrack()`](https://gladkia.github.io/igvShiny/reference/VariantTrack-class.md)
  : VariantTrack: variants from a VariantAnnotation VCF object
- [`DataFrameAnnotationTrack()`](https://gladkia.github.io/igvShiny/reference/igvAnnotationTrack-class.md)
  [`GRangesAnnotationTrack()`](https://gladkia.github.io/igvShiny/reference/igvAnnotationTrack-class.md)
  [`UCSCBedAnnotationTrack()`](https://gladkia.github.io/igvShiny/reference/igvAnnotationTrack-class.md)
  : Annotation tracks: bed-like features from a data.frame, GRanges or
  UCSCData
- [`igvAnnotationTrack()`](https://gladkia.github.io/igvShiny/reference/igvAnnotationTrack.md)
  : Build an annotation track from whatever annotation object is at hand
- [`show(`*`<Track>`*`)`](https://gladkia.github.io/igvShiny/reference/show-Track.md)
  : Print a summary of a track object
- [`trackInfo()`](https://gladkia.github.io/igvShiny/reference/trackInfo.md)
  [`trackSize()`](https://gladkia.github.io/igvShiny/reference/trackInfo.md)
  : Basic facts about a track

## GWASTrack class

- [`GWASTrack()`](https://gladkia.github.io/igvShiny/reference/GWASTrack-class.md)
  : Constructor for GWASTrack
- [`display(`*`<GWASTrack>`*`)`](https://gladkia.github.io/igvShiny/reference/display.md)
  : display the already constructed and configured track
- [`.sanitizeChromosomeColorMap()`](https://gladkia.github.io/igvShiny/reference/dot-sanitizeChromosomeColorMap.md)
  : Check a chromosome color map before it reaches igv.js
- [`getUrl(`*`<GWASTrack>`*`)`](https://gladkia.github.io/igvShiny/reference/getUrl.md)
  : the url of the gwas table
- [`show(`*`<GWASTrack>`*`)`](https://gladkia.github.io/igvShiny/reference/show.md)
  : Display a short summary of a GWASTrack object

## Utils

- [`checkReferenceCompatibility()`](https://gladkia.github.io/igvShiny/reference/checkReferenceCompatibility.md)
  : Check reference compatibility between track data and genome
  specification
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
- [`serveLocalFile()`](https://gladkia.github.io/igvShiny/reference/serveLocalFile.md)
  : Serve a local file via HTTP Range Requests from the Shiny session
