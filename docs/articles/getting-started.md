# Getting started with igvShiny

## Who this is for

You have a Shiny app and some genomic data — intervals, alignments,
variants, association statistics — and you want to look at it in a
genome browser without leaving R. This vignette takes you from
installation to a working app with a track loaded from your own
`data.frame`.

It assumes you have written a Shiny app before. It does not assume you
know [igv.js](https://github.com/igvteam/igv.js), the JavaScript browser
`igvShiny` wraps.

For the complete API — every track type and the options each one accepts
— see the *Track options reference* vignette. For a live app you can
click through before installing anything, see the [demo on Posit Connect
Cloud](https://gladkia-igvshiny-demo.share.connect.posit.cloud).

## Install

`if`` ``(``!`[`requireNamespace`](https://rdrr.io/r/base/ns-load.html)`(``"BiocManager"``, quietly ``=`` ``TRUE``)``)`` `` `[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"BiocManager"``)`` `` ``BiocManager``::`[`install`](https://bioconductor.github.io/BiocManager/reference/install.html)`(``"igvShiny"``)`

[`library`](https://rdrr.io/r/base/library.html)`(`[`igvShiny`](https://github.com/gladkia/igvShiny)`)`

## The three moving parts

An `igvShiny` browser is an htmlwidget, so it follows the usual Shiny
pattern of an output function in the UI and a render function on the
server. What is specific to this package is the third part: the browser
has to be told which genome to display *before* it is created.

| Part | Function | Where |
|----|----|----|
| Genome specification | [`parseAndValidateGenomeSpec()`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md) | top of the app |
| Placeholder in the layout | [`igvShinyOutput()`](https://gladkia.github.io/igvShiny/reference/igvShinyOutput.md) | UI |
| The widget itself | [`renderIgvShiny()`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md) + [`igvShiny()`](https://gladkia.github.io/igvShiny/reference/igvShiny.md) | server |

[`parseAndValidateGenomeSpec()`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)
returns a validated list. Building it separately means a bad genome name
fails immediately, with a readable message, rather than producing an
empty browser in the page:

`genomeOptions`` ``<-`` `[`parseAndValidateGenomeSpec`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)`(`` `` genomeName ``=`` ``"hg38"``,`` `` initialLocus ``=`` ``"NDUFS2"`` `` ``)`` `[`str`](https://rdrr.io/r/utils/str.html)`(``genomeOptions``)`` ``#> List of 8`` ``#> $ stockGenome : logi TRUE`` ``#> $ dataMode : logi NA`` ``#> $ validated : logi TRUE`` ``#> $ genomeName : chr "hg38"`` ``#> $ initialLocus: chr "NDUFS2"`` ``#> $ fasta : logi NA`` ``#> $ fastaIndex : logi NA`` ``#> $ annotation : logi NA`

`initialLocus` accepts a gene symbol, a `chrom:start-end` string, or
`"all"` for the whole-genome view.

## A complete app

Everything above assembled — this is the smallest useful `igvShiny` app:

[`library`](https://rdrr.io/r/base/library.html)`(`[`shiny`](https://shiny.posit.co/)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`igvShiny`](https://github.com/gladkia/igvShiny)`)`` `` ``genomeOptions`` ``<-`` `[`parseAndValidateGenomeSpec`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)`(`` `` genomeName ``=`` ``"hg38"``,`` `` initialLocus ``=`` ``"NDUFS2"`` `` ``)`` `` ``ui`` ``<-`` `[`fluidPage`](https://rdrr.io/pkg/shiny/man/fluidPage.html)`(`` `` `[`titlePanel`](https://rdrr.io/pkg/shiny/man/titlePanel.html)`(``"igvShiny"``)``,`` `` `[`igvShinyOutput`](https://gladkia.github.io/igvShiny/reference/igvShinyOutput.md)`(``"igv"``)`` `` ``)`` `` ``server`` ``<-`` ``function``(``input``, ``output``, ``session``)`` ``{`` `` ``output``$``igv`` ``<-`` `[`renderIgvShiny`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md)`(``{`` `` `[`igvShiny`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)`(``genomeOptions``)`` `` ``}``)`` `` ``}`` `` `[`shinyApp`](https://rdrr.io/pkg/shiny/man/shinyApp.html)`(``ui``, ``server``)`

Two notes on sizing.
[`igvShinyOutput()`](https://gladkia.github.io/igvShiny/reference/igvShinyOutput.md)
takes `height` as an explicit pixel measure (`"800px"`); percentages do
not work, because the browser needs a concrete height to lay its panels
out. And the widget only draws once its container is visible, so if you
put it behind a
[`tabsetPanel()`](https://rdrr.io/pkg/shiny/man/tabsetPanel.html) tab,
expect it to appear when that tab is first opened.

## Loading a track from your own data

Tracks are added by sending a message to a browser that already exists,
so the loaders are called from the server, take `session` and the widget
`id`, and are usually wired to an event:

`tbl`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` chrom ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"chr1"``, ``"chr1"``, ``"chr1"``)``,`` `` start ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``7432000``, ``7437000``, ``7443000``)``,`` `` end ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``7436000``, ``7442000``, ``7447000``)``,`` `` value ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.2``, ``0.9``, ``0.4``)``,`` `` stringsAsFactors ``=`` ``FALSE`` `` ``)`` `` ``server`` ``<-`` ``function``(``input``, ``output``, ``session``)`` ``{`` `` ``output``$``igv`` ``<-`` `[`renderIgvShiny`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md)`(``{`` `` `[`igvShiny`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)`(``genomeOptions``)`` `` ``}``)`` `` `` `[`observeEvent`](https://rdrr.io/pkg/shiny/man/observeEvent.html)`(``input``$``addTrack``, ``{`` `` `[`loadBedTrack`](https://gladkia.github.io/igvShiny/reference/loadBedTrack.md)`(`` `` ``session``,`` `` id ``=`` ``"igv"``,`` `` trackName ``=`` ``"my regions"``,`` `` tbl ``=`` ``tbl``,`` `` color ``=`` ``"darkblue"`` `` ``)`` `` ``}``)`` `` ``}`

[`loadBedTrack()`](https://gladkia.github.io/igvShiny/reference/loadBedTrack.md)
needs `chrom`, `start` and `end` columns; anything else is ignored. The
other loaders follow the same shape —
[`loadBedGraphTrack()`](https://gladkia.github.io/igvShiny/reference/loadGenomeAnnotationTrack.md),
[`loadSegTrack()`](https://gladkia.github.io/igvShiny/reference/loadSEGTrack.md),
[`loadVcfTrack()`](https://gladkia.github.io/igvShiny/reference/loadVcfTrack.md),
[`loadGwasTrack()`](https://gladkia.github.io/igvShiny/reference/loadGwasTrack.md),
[`loadBamTrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromLocalData.md),
[`loadSpliceJunctionTrackFromLocalData()`](https://gladkia.github.io/igvShiny/reference/loadSpliceJunctionTrackFromLocalData.md)
— and each has a `*FromURL()` counterpart for data that already lives on
a web server:

`gff3`` ``<-`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(`` `` ``"https://s3.amazonaws.com/igv.org.genomes/hg38/"``,`` `` ``"Homo_sapiens.GRCh38.94.chr.gff3.gz"`` `` ``)`` `` `[`loadGFF3TrackFromURL`](https://gladkia.github.io/igvShiny/reference/loadGFF3TrackFromURL.md)`(`` `` ``session``,`` `` id ``=`` ``"igv"``,`` `` trackName ``=`` ``"genes"``,`` `` gff3URL ``=`` ``gff3``,`` `` indexURL ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``gff3``, ``".tbi"``)``,`` `` color ``=`` ``"darkgreen"``,`` `` trackHeight ``=`` ``100`` `` ``)`

The `From URL` variants ask the *user’s browser* to fetch the file, not
R. A URL that works in
[`download.file()`](https://rdrr.io/r/utils/download.file.html) can
still fail here if the server does not send permissive CORS headers.

Tracks the user added during a session can be cleared with
`removeUserAddedTracks(session, id = "igv")`, or individually by name
with
[`removeTracksByName()`](https://gladkia.github.io/igvShiny/reference/removeTracksByName.md).

### Loading tracks at startup

Tracks that should always be present do not need an event. Pass them to
[`igvShiny()`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)
through `tracks`, as a list of igv.js track configurations:

`output``$``igv`` ``<-`` `[`renderIgvShiny`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md)`(``{`` `` `[`igvShiny`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)`(`` `` ``genomeOptions``,`` `` tracks ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` name ``=`` ``"genes"``,`` `` type ``=`` ``"annotation"``,`` `` format ``=`` ``"gff3"``,`` `` url ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(`` `` ``"https://s3.amazonaws.com/igv.org.genomes/hg38/"``,`` `` ``"Homo_sapiens.GRCh38.94.chr.gff3.gz"`` `` ``)``,`` `` indexed ``=`` ``FALSE`` `` ``)`` `` ``)`` `` ``)`` `` ``}``)`

Keys that igv.js does not recognise are dropped with a warning rather
than passed through, so a typo produces a message instead of a silently
empty track.

### Drawing two tracks in one panel

A `merged` track holds other tracks instead of a url of its own, and
draws them on top of each other in a single panel. Splice junction arcs
over the coverage they were spliced out of — the view sashimi plots are
wanted for — is the case it is worth knowing:

`sample`` ``<-`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(`` `` ``"https://raw.githubusercontent.com/igvteam/igv-data/main/data/test/"``,`` `` ``"splice_junctions/splice_junction_track_test_cases_sampleA."``,`` `` ``"chr15-92835700-93031800"`` `` ``)`` `` ``output``$``igv`` ``<-`` `[`renderIgvShiny`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md)`(``{`` `` `[`igvShiny`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)`(`` `` ``genomeOptions``,`` `` tracks ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` name ``=`` ``"sampleA"``,`` `` type ``=`` ``"merged"``,`` `` height ``=`` ``180``,`` `` tracks ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` type ``=`` ``"wig"``,`` `` format ``=`` ``"bigwig"``,`` `` url ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``sample``, ``".bigWig"``)``,`` `` color ``=`` ``"rgb(190,190,190)"`` `` ``)``,`` `` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` type ``=`` ``"junction"``,`` `` format ``=`` ``"bed"``,`` `` url ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``sample``, ``".SJ.out.bed.gz"``)``,`` `` indexURL ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``sample``, ``".SJ.out.bed.gz.tbi"``)``,`` `` colorBy ``=`` ``"motif"`` `` ``)`` `` ``)`` `` ``)`` `` ``)`` `` ``)`` `` ``}``)`

Member tracks go through the same option allowlist as any other track. A
member left with no usable url is dropped on its own, with a warning;
the merged track itself is dropped only once no member survives, rather
than sent on empty, as igv.js throws while building the browser if it is
handed one.

## Moving around, and knowing where you are

To drive the browser from R, use
[`showGenomicRegion()`](https://gladkia.github.io/igvShiny/reference/showGenomicRegion.md):

[`observeEvent`](https://rdrr.io/pkg/shiny/man/observeEvent.html)`(``input``$``goto``, ``{`` `` `[`showGenomicRegion`](https://gladkia.github.io/igvShiny/reference/showGenomicRegion.md)`(`` `` ``session``,`` `` id ``=`` ``"igv"``,`` `` region ``=`` ``"chr5:88,700,000-88,800,000"`` `` ``)`` `` ``}``)`

Reading the position back is asynchronous, which is the one part of the
API that surprises people.
[`getGenomicRegion()`](https://gladkia.github.io/igvShiny/reference/showGenomicRegion.md)
does not return the region; it asks the browser for it, and the answer
arrives later as a Shiny input named `currentGenomicRegion.<id>`:

[`observeEvent`](https://rdrr.io/pkg/shiny/man/observeEvent.html)`(``input``$``whereAmI``, ``{`` `` `[`getGenomicRegion`](https://gladkia.github.io/igvShiny/reference/showGenomicRegion.md)`(``session``, id ``=`` ``"igv"``)`` `` ``}``)`` `` `[`observeEvent`](https://rdrr.io/pkg/shiny/man/observeEvent.html)`(``input``[[``"currentGenomicRegion.igv"``]``]``, ``{`` `` `[`message`](https://rdrr.io/r/base/message.html)`(``"now showing: "``, ``input``[[``"currentGenomicRegion.igv"``]``]``)`` `` ``}``)`

The same input fires whenever the user pans or zooms, so an observer on
it is enough if you only want to follow the view rather than poll it.

Two other inputs are available: `igvReady`, which fires once the browser
has finished initialising — the right place to load tracks automatically
— and `trackClick`, which carries the feature the user clicked on.

## Inside a Shiny module

`igvShiny` works in modules with no extra arguments: the widget reads
the namespace from the session it is created in. The one thing to
remember is that the loaders address the browser by its *HTML element*
id, not by the input name — so they need the namespaced id, `ns("igv")`,
and not `"igv"`:

`igvModuleUI`` ``<-`` ``function``(``id``)`` ``{`` `` ``ns`` ``<-`` `[`NS`](https://rdrr.io/pkg/shiny/man/NS.html)`(``id``)`` `` `[`tagList`](https://rstudio.github.io/htmltools/reference/tagList.html)`(`` `` `[`actionButton`](https://rdrr.io/pkg/shiny/man/actionButton.html)`(``ns``(``"addTrack"``)``, ``"Add track"``)``,`` `` `[`igvShinyOutput`](https://gladkia.github.io/igvShiny/reference/igvShinyOutput.md)`(``ns``(``"igv"``)``)`` `` ``)`` `` ``}`` `` ``igvModuleServer`` ``<-`` ``function``(``id``, ``genomeOptions``, ``tbl``)`` ``{`` `` `[`moduleServer`](https://rdrr.io/pkg/shiny/man/moduleServer.html)`(``id``, ``function``(``input``, ``output``, ``session``)`` ``{`` `` ``ns`` ``<-`` ``session``$``ns`` `` `` ``output``$``igv`` ``<-`` `[`renderIgvShiny`](https://gladkia.github.io/igvShiny/reference/renderIgvShiny.md)`(``{`` `` `[`igvShiny`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)`(``genomeOptions``)`` `` ``}``)`` `` `` `[`observeEvent`](https://rdrr.io/pkg/shiny/man/observeEvent.html)`(``input``$``addTrack``, ``{`` `` `[`loadBedTrack`](https://gladkia.github.io/igvShiny/reference/loadBedTrack.md)`(`` `` ``session``,`` `` id ``=`` ``ns``(``"igv"``)``,`` `` trackName ``=`` ``"regions"``,`` `` tbl ``=`` ``tbl`` `` ``)`` `` ``}``)`` `` `` ``# the region input keeps its unnamespaced name inside the module`` `` `[`observeEvent`](https://rdrr.io/pkg/shiny/man/observeEvent.html)`(``input``[[``"currentGenomicRegion.igv"``]``]``, ``{`` `` `[`message`](https://rdrr.io/r/base/message.html)`(``"now showing: "``, ``input``[[``"currentGenomicRegion.igv"``]``]``)`` `` ``}``)`` `` ``}``)`` `` ``}`

That observer follows the user panning and zooming. Asking for the
region explicitly with
[`getGenomicRegion()`](https://gladkia.github.io/igvShiny/reference/showGenomicRegion.md)
is currently unreliable inside a module unless the module id happens to
be `"igv"` — see [issue
\#134](https://github.com/gladkia/igvShiny/issues/134).

A runnable version is in `inst/demos/modules.R`.

## Stock genomes

Any genome igv.js knows can be requested by name —
[`get_css_genomes()`](https://gladkia.github.io/igvShiny/reference/get_css_genomes.md)
lists them, reading the same registry the bundled igv.js does
([genomes3.json](https://igv.org/genomes/genomes3.json)).

Naming a stock genome means R fetches no sequence data: it reads the
registry only to validate the name, and the user’s browser streams the
sequence from wherever the registry entry points. Since igv.js 3.x that
is a `.2bit` file, preferred over the entry’s FASTA when both are
listed, and for the genomes igvShiny offers those `.2bit` files are
hosted by UCSC (`hgdownload.soe.ucsc.edu`). A UCSC outage therefore
leaves a stock genome blank, with 403s or timeouts in the JavaScript
console — the package itself is fine, and custom genomes (below) are
unaffected because they carry their own URLs.

## Custom genomes

For a genome outside the registry, supply the sequence yourself: a FASTA
file, its index, and optionally an annotation, either as local paths
(`dataMode = "localFiles"`) or URLs (`dataMode = "http"`). The package
ships a small example genome:

`data_directory`` ``<-`` `[`system.file`](https://rdrr.io/r/base/system.file.html)`(``package ``=`` ``"igvShiny"``, ``"extdata"``)`` `` ``customOptions`` ``<-`` `[`parseAndValidateGenomeSpec`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)`(`` `` genomeName ``=`` ``"ribosomal RNA gene"``,`` `` initialLocus ``=`` ``"U13369.1:7,276-8,225"``,`` `` stockGenome ``=`` ``FALSE``,`` `` dataMode ``=`` ``"localFiles"``,`` `` fasta ``=`` `[`file.path`](https://rdrr.io/r/base/file.path.html)`(``data_directory``, ``"ribosomal-RNA-gene.fasta"``)``,`` `` fastaIndex ``=`` `[`file.path`](https://rdrr.io/r/base/file.path.html)`(``data_directory``, ``"ribosomal-RNA-gene.fasta.fai"``)``,`` `` genomeAnnotation ``=`` `[`file.path`](https://rdrr.io/r/base/file.path.html)`(``data_directory``, ``"ribosomal-RNA-gene.gff3"``)`` `` ``)`` ``customOptions``[`[`c`](https://rdrr.io/r/base/c.html)`(``"genomeName"``, ``"dataMode"``, ``"stockGenome"``)``]`` ``#> $genomeName`` ``#> [1] "ribosomal RNA gene"`` ``#> `` ``#> $dataMode`` ``#> [1] "localFiles"`` ``#> `` ``#> $stockGenome`` ``#> [1] FALSE`

The result goes to
[`igvShiny()`](https://gladkia.github.io/igvShiny/reference/igvShiny.md)
exactly like a stock genome specification.

The same genome served over HTTP instead, which is what you want once
the app runs somewhere other than your laptop. `dataMode = "http"` makes
[`parseAndValidateGenomeSpec()`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)
send a `HEAD` request to every URL, so this chunk is shown rather than
run — building the vignette stays offline:

`base_url`` ``<-`` ``"https://gladki.pl/igvr/testFiles"`` `` ``remoteOptions`` ``<-`` `[`parseAndValidateGenomeSpec`](https://gladkia.github.io/igvShiny/reference/parseAndValidateGenomeSpec.md)`(`` `` genomeName ``=`` ``"ribosomal RNA gene"``,`` `` initialLocus ``=`` ``"U13369.1:7,276-8,225"``,`` `` stockGenome ``=`` ``FALSE``,`` `` dataMode ``=`` ``"http"``,`` `` fasta ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``base_url``, ``"/ribosomal-RNA-gene.fasta"``)``,`` `` fastaIndex ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``base_url``, ``"/ribosomal-RNA-gene.fasta.fai"``)``,`` `` genomeAnnotation ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``base_url``, ``"/ribosomal-RNA-gene.gff3"``)`` `` ``)`` ``remoteOptions``[`[`c`](https://rdrr.io/r/base/c.html)`(``"genomeName"``, ``"dataMode"``, ``"stockGenome"``)``]`

`inst/demos/genomes.R` shows both variants side by side, picked with
radio buttons.

## When something does not show up

**The browser is blank.** Almost always the genome, not the track. Check
the JavaScript console: a 404 on the FASTA or its index leaves an empty
browser. Some upstream genome URLs have broken in the past without any
change on our side.

**A track loads but is empty.** Chromosome naming. If your data says `1`
and the genome says `chr1`, igv.js finds nothing and reports nothing.
Compare one interval against the locus shown in the search box.

**Nothing at all happens after a loader call.** The loaders are one-way
messages to the browser: no error comes back to R when they fail. Call
the loader with `quiet = FALSE` to log what was sent, and read the
JavaScript console for what happened to it.

**Local data files 404.** Tracks built from R data are written to a
temporary directory that Shiny serves. If you have set `TRACKS_DIR`,
make sure the process can write there;
[`get_tracks_dir()`](https://gladkia.github.io/igvShiny/reference/get_tracks_dir.md)
reports the directory in use.

## Where to go next

- The *Track options reference* vignette — every track type and its
  options
- `inst/demos/` — one runnable app per feature, each under sixty lines
- `inst/showcase/igvShinyDemo.R` — most of the API in a single app, and
  what the public Posit Connect demo serves
- [igv.js documentation](https://github.com/igvteam/igv.js/wiki) — the
  underlying browser, useful when you need a track option this package
  passes through but does not document itself

## Session Info

[`sessionInfo`](https://rdrr.io/r/utils/sessionInfo.html)`(``)`` ``#> R version 4.6.1 (2026-06-24)`` ``#> Platform: x86_64-pc-linux-gnu`` ``#> Running under: Ubuntu 24.04.4 LTS`` ``#> `` ``#> Matrix products: default`` ``#> BLAS: /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 `` ``#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so; LAPACK version 3.12.0`` ``#> `` ``#> locale:`` ``#> [1] LC_CTYPE=en_US.UTF-8 LC_NUMERIC=C `` ``#> [3] LC_TIME=en_US.UTF-8 LC_COLLATE=en_US.UTF-8 `` ``#> [5] LC_MONETARY=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8 `` ``#> [7] LC_PAPER=en_US.UTF-8 LC_NAME=C `` ``#> [9] LC_ADDRESS=C LC_TELEPHONE=C `` ``#> [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C `` ``#> `` ``#> time zone: UTC`` ``#> tzcode source: system (glibc)`` ``#> `` ``#> attached base packages:`` ``#> [1] stats4 stats graphics grDevices utils datasets methods `` ``#> [8] base `` ``#> `` ``#> other attached packages:`` ``#> [1] igvShiny_1.9.43 shiny_1.14.0 GenomicRanges_1.65.1`` ``#> [4] Seqinfo_1.3.0 IRanges_2.47.2 S4Vectors_0.51.7 `` ``#> [7] BiocGenerics_0.59.12 generics_0.1.4 BiocStyle_2.41.0 `` ``#> `` ``#> loaded via a namespace (and not attached):`` ``#> [1] sass_0.4.10 futile.options_1.0.1 stringi_1.8.9 `` ``#> [4] digest_0.6.39 magrittr_2.0.5 RColorBrewer_1.1-3 `` ``#> [7] evaluate_1.0.5 bookdown_0.47 fastmap_1.2.0 `` ``#> [10] jsonlite_2.0.0 backports_1.5.1 formatR_1.14 `` ``#> [13] promises_1.5.0 BiocManager_1.30.27 httr_1.4.8 `` ``#> [16] scales_1.4.0 randomcoloR_1.1.0.1 textshaping_1.0.5 `` ``#> [19] jquerylib_0.1.4 cli_3.6.6 rlang_1.3.0 `` ``#> [22] futile.logger_1.4.9 cachem_1.1.0 yaml_2.3.12 `` ``#> [25] otel_0.2.0 Rtsne_0.17 tools_4.6.1 `` ``#> [28] checkmate_2.3.4 colorspace_2.1-3 httpuv_1.6.17 `` ``#> [31] GenomeInfoDbData_1.2.15 lambda.r_1.2.4 curl_7.1.0 `` ``#> [34] R6_2.6.1 mime_0.13 lifecycle_1.0.5 `` ``#> [37] stringr_1.6.0 fs_2.1.0 V8_8.2.0 `` ``#> [40] htmlwidgets_1.6.4 cluster_2.1.8.3 ragg_1.5.2 `` ``#> [43] desc_1.4.3 pkgdown_2.2.1 bslib_0.12.0 `` ``#> [46] later_1.4.8 glue_1.8.1 Rcpp_1.1.2 `` ``#> [49] systemfonts_1.3.2 xfun_0.60 knitr_1.51 `` ``#> [52] farver_2.1.2 xtable_1.8-8 htmltools_0.5.9 `` ``#> [55] rmarkdown_2.31 compiler_4.6.1`
