# M1: Shared S4 Track Engine

Move the S4 `Track` hierarchy from igvR into igvShiny and split every igvShiny
track loader into a pure **payload builder** and a thin **sender**.

## Stages

- [x] 1. Inventory + pattern: this file, `^dev$` in `.Rbuildignore`,
      builder/sender split of the BED and bedGraph loaders, tests
- [x] 2. Builder/sender split for all remaining loaders in `R/igvShiny.R`
      (VCF, seg, GWAS, BAM/CRAM, URL loaders, GFF3, splice junctions), tests
- [x] 3. Port `Track`, `QuantitativeTrack`, `igvAnnotationTrack` (needed as the
      parent, see below), `GRangesAnnotationTrack`, `DataFrameAnnotationTrack`,
      `UCSCBedAnnotationTrack`, `GRangesQuantitativeTrack`,
      `DataFrameQuantitativeTrack`, `UCSCBedGraphQuantitativeTrack` into
      `R/tracks.R` (Collate before `igvShiny.R`); a builder method per class;
      exported `loadTrack(session, id, track)` generic + methods; tests
- [x] 4. `GenomicAlignmentTrack`, `VariantTrack`, `BedpeInteractionsTrack`,
      `GFF3Track`, `CramTrack`, `RemoteAlignmentTrack`, `igvAnnotationTrack`;
      reconcile with igvShiny's `GWASTrack`; tests; roxygen pass; NEWS.md and
      DESCRIPTION Version/Date

## The builder/sender pattern (stage 1 reference)

```
.<kind>TrackPayload(trackName, <data>, [path], <display args>, trackConfig)
  -> list(config = <message body, no elementID>, files = <paths written>)
```

- **Builder** (`.bedTrackPayload`, `.bedGraphTrackPayload`,
  `.bedGraphUrlTrackPayload`): dot-prefixed, internal, checkmate asserts at the
  top, no `session`, no `state`, no `sendCustomMessage`. It validates and
  reshapes the input, writes any file to the `path` it is *given*, merges
  `trackConfig` with `.sanitizeAndMergeOptions()` (defaults win, user keys are
  only added), and returns `config` + `files`. `color = "random"` is resolved
  in the builder so `loadTrack()` behaves like the old loaders.
- **Sender** (the exported loader, signature unchanged): logging,
  `removeTracksByName()`, `state$userAddedTracks`, column normalisation
  (`.normalizeBedColumns()` / `.normalizeBedGraphColumns()`) so that
  `.validateTrackReference()` sees the same table as before, then
  `path = .trackFile(session, ext)`, the builder, and
  `session$sendCustomMessage(<handler>, c(list(elementID = id), payload$config))`.
  The message is byte-for-byte the one the loader sent before (same keys,
  same order); `test-trackPayloads.R` pins that for the bedGraph senders.
- **What `config` is**: for now it is the body the existing handler in
  `inst/htmlwidgets/igvShiny.js` reads (e.g. `bedFilepath`, `trackHeight`),
  not a finished igv.js track config — the JS handler still adds `format`,
  `type`, `order`, ... and runs `mergeExtraParameters()`. Turning builders into
  real igv.js configs needs a JS change and is out of M1 scope; see questions.
- Builders are tested directly in `tests/testthat/test-trackPayloads.R`,
  without a session. Sender behaviour stays covered by `test-loadTracks.R`.

## Inventory of igvR S4 classes (igvR `R/*Track.R`)

All classes inherit the `Track` slots: `trackType`, `sourceType`,
`fileFormat`, `trackName`, `onScreenOrder`, `color`, `height`,
`autoTrackHeight`, `minTrackHeight`, `maxTrackHeight`, `visibilityWindow`.
igvR generics: `trackInfo(obj)`, `trackSize(obj)`. igvR `Track()` resolves
`color = "random"` with `RColorBrewer::brewer.pal()`; igvShiny should use its
own `randomColors` instead (no new dependency).

| igvR class | parent | own slots | igvShiny loader / builder | Bioc/CRAN needs | igvShiny equivalent today |
|---|---|---|---|---|---|
| `Track` | — | (base slots above) | — (virtual-ish base) | methods | none |
| `igvAnnotationTrack` | Track | classTypeOfSuppliedObject, displayMode, expandedRowHeight, squishedRowHeight, nameField, maxRows, searchable | `.bedTrackPayload` | — | none |
| `DataFrameAnnotationTrack` | igvAnnotationTrack | coreObject = data.frame | `loadBedTrack` → `.bedTrackPayload` | — | none |
| `GRangesAnnotationTrack` | igvAnnotationTrack | coreObject = GRanges | `loadBedTrack` (GRanges → data.frame) → `.bedTrackPayload` | GenomicRanges (Depends) | none |
| `UCSCBedAnnotationTrack` | igvAnnotationTrack | coreObject = UCSCData | `loadBedTrack` → `.bedTrackPayload` | rtracklayer (Suggests) | none |
| `QuantitativeTrack` | Track | autoscale, min, max | `.bedGraphTrackPayload` (file) / `.bedGraphUrlTrackPayload` (url: wig, bigWig, bedGraph) | — | none |
| `DataFrameQuantitativeTrack` | QuantitativeTrack | coreObject = data.frame | `loadBedGraphTrack` → `.bedGraphTrackPayload` | — | none |
| `GRangesQuantitativeTrack` | QuantitativeTrack | coreObject = GRanges | `loadBedGraphTrack` → `.bedGraphTrackPayload` | GenomicRanges | none |
| `UCSCBedGraphQuantitativeTrack` | QuantitativeTrack | coreObject = UCSCData | `loadBedGraphTrack` → `.bedGraphTrackPayload` | rtracklayer (Suggests) | none |
| `GWASTrack` | QuantitativeTrack | coreObject = data.frame, chrom.col, pos.col, pval.col, colorTable | `loadGwasTrack` | — | **yes**: igvShiny `GWASTrack` (standalone class, *no* Track parent; slots trackName, data.mode, url, chrom.col, pos.col, pval.col, chromosomeColorMap, trackHeight, autoscale, minY, maxY; `display()` + `getUrl()` generics) |
| `GWASUrlTrack` | QuantitativeTrack | coreObject = character (url), chrom.col, pos.col, pval.col, colorTable | `loadGwasTrack` (url mode) | — | covered by igvShiny `GWASTrack` (data.mode = "url"). Not in the stage list |
| `GenomicAlignmentTrack` | Track | alignment = GAlignments | `loadBamTrackFromLocalData` | GenomicAlignments, Rsamtools, rtracklayer (Suggests) | none |
| `RemoteAlignmentTrack` | Track | bamUrl, bamIndex | `loadBamTrackFromURL` | — | none |
| `CramTrack` | Track | cramUrl, indexUrl | `loadCramTrackFromURL` | — | none |
| `VariantTrack` | Track | displayMode, vcf.obj = `VCF.or.NULL` (class union), vcf.url = list(data, index), anchorColor, homvarColor, hetvarColor, homrefColor | `loadVcfTrack` (VCF object); URL form has no igvShiny loader yet | VariantAnnotation (Suggests) | none |
| `BedpeInteractionsTrack` | DataFrameAnnotationTrack | (none) | **no igvShiny loader** (igv.js `interact` type, bedpe format) — needs a new builder + JS handler or generic handler | — | none |
| `GFF3Track` | igvAnnotationTrack | tbl = data.frame, url, indexURL, colorByAttribute, colorTable | `loadGFF3TrackFromURL` / `loadGFF3TrackFromLocalData` | — | none |

### Porting hazards found while inventorying

- **Slots typed with classes from Suggests packages** (`GAlignments`,
  `UCSCData`, `VCF` via `setClassUnion("VCF.or.NULL", ...)`) cannot be
  declared in igvShiny: the class must exist when the namespace is built, and
  those packages are not installed in every CI job. Proposed: declare the slot
  as `"ANY"` and enforce the class in a `validity` function / constructor that
  calls `requireNamespace()`. This keeps all three packages in Suggests.
- **Name clash `GWASTrack`**: igvShiny already exports `GWASTrack` with a
  different slot set and no `Track` parent. Porting igvR's would break
  igvShiny users. Stage 4 decides; the default proposal is to keep igvShiny's
  class as is and add a `loadTrack()` method for it that calls `display()`'s
  builder, rather than re-parenting it.
- igvShiny already has an S4 generic `display(obj, session, id, ...)` for
  `GWASTrack`. `loadTrack(session, id, track)` is the M1 name (different
  argument order); `display()` must stay.
- igvR constructors use `stopifnot`, `ncol`, `1:8` and RColorBrewer; the ports
  need checkmate asserts, `NCOL`, `seq_len` and `randomColors` to pass
  gDRstyle lint.

## Notes for next stage

**Stage 1 (done):** wrote this plan; added `^dev$` to `.Rbuildignore`; split
`loadBedTrack`, `loadBedGraphTrack` and `loadBedGraphTrackFromURL` into
`.bedTrackPayload`, `.bedGraphTrackPayload`, `.bedGraphUrlTrackPayload` plus
two shared helpers `.normalizeBedColumns` / `.normalizeBedGraphColumns`
(`R/igvShiny.R`). New tests: `tests/testthat/test-trackPayloads.R`. Exported
signatures and wire messages are unchanged; no new igv.js option keys, no
DESCRIPTION/NEWS changes.

Behavioural nuances (intentional, small):
- `.trackFile()` is now called before the bed type checks, so a rejected bed
  table registers a never-created path for cleanup (harmless `unlink`).
- Builders assert `trackName`, `color` (and `url`/`path`) are single strings
  and `tbl` is a `data.frame` with >= 3 (bed) / >= 4 (bedGraph) columns. A
  non-data.frame table (e.g. S4 `DataFrame`) now fails with a checkmate error
  instead of later; it did not produce a working track before either.
- `elementID` passed in `trackConfig` is still dropped, now as "invalid"
  rather than "conflicting" (the builder does not know the element id).

Skipped / left for stage 2: every other loader. `loadBedGraphTrackFromURL`
still calls `message()` (untouched pre-existing line).

**Open questions for the human:**
1. Should builders eventually return a genuine igv.js track config (with
   `type`, `format`, `url`, ...) so one generic JS handler can serve
   `loadTrack()`? That moves logic out of `igvShiny.js` and is a bigger
   change than M1 allows; for now `config` = the existing handler payload.
2. Builders are internal (`@keywords internal`, not exported). Export them
   later for igvR to reuse, or have igvR call `loadTrack()` only?
3. `GWASTrack` reconciliation (see hazards) — confirm the "keep igvShiny's
   class, add a `loadTrack` method" default before stage 4.

**Stage 2 (done):** split every remaining loader in `R/igvShiny.R` into a
builder + sender, same pattern as stage 1. New internal builders:

| exported loader(s) | builder | writes |
|---|---|---|
| `loadSegTrack` | `.segTrackPayload` | — (inline JSON) |
| `loadVcfTrack` | `.vcfTrackPayload` | `path` (VariantAnnotation, guarded) |
| `loadGwasTrack` | `.gwasTrackPayload` | `path` |
| `loadBamTrackFromURL`, `loadBamTrackFromLocalFile` | `.bamUrlTrackPayload` | — |
| `loadBamTrackFromLocalData` | `.bamLocalDataTrackPayload` | `path` + `path.bai` (rtracklayer/Rsamtools, guarded) |
| `loadCramTrackFromURL`, `loadCramTrackFromLocalData` (= `...LocalFile`) | `.cramUrlTrackPayload` | — |
| `loadGFF3TrackFromURL` | `.gff3UrlTrackPayload` | — |
| `loadGFF3TrackFromLocalData` | `.gff3TrackPayload` | `path` |
| `loadSpliceJunctionTrackFromURL` | `.spliceJunctionUrlTrackPayload` | — |
| `loadSpliceJunctionTrackFromLocalData` | `.spliceJunctionTrackPayload` (calls the url builder) | `path` |

Plus helper `.normalizeJunctionColumns` (the old inline checks, so the sender
still rejects a bad table before it sends `removeTracksByName`). The local
file loaders keep `serveLocalFile()` in the sender and pass the served urls to
the url builder, so "local file" and "url" share one builder per format.
Optional keys (`height`, and `showAllBases` for the local-file bam loader,
which never sent it) are left out of `config` when `NULL`, so every wire
message keeps its keys and key order; `test-trackPayloads.R` checks builder
vs. sender output for every stage 2 loader. No new igv.js option keys, no
DESCRIPTION/NEWS changes, nothing moved to Imports.

Behavioural nuances (intentional, small):
- New checkmate asserts in builders: `trackName` and urls/paths are single
  strings; seg/gwas/gff3 tables must be `data.frame`s (a matrix was accepted
  before and written by `write.table`); `vcfData` must be a `VCF`;
  `showAllBases` a flag; `trackHeight` a number >= 1 or NULL (all bam/cram
  loaders already asserted that). The GFF3 builders keep the loaders' lack of
  defaults for `colorTable`, `colorByAttribute`, `displayMode`,
  `visibilityWindow`.
- `loadSpliceJunctionTrackFromURL`'s "indexURL must be a single character
  string" `warning()` moved into the builder unchanged (still a base
  `warning()`, tests expect it); it still fires before `removeTracksByName`.
- As in stage 1, an `elementID` in `trackConfig` is dropped as "invalid"
  rather than "conflicting".

Skipped / left for later:
- `display()` for igvShiny's `GWASTrack` (`R/GWASTrack.R`) still builds its
  `loadGwasTrackFlexibleSource` message inline — it is not a loader in
  `R/igvShiny.R`; stage 4 should extract `.gwasTrackObjectPayload` when it
  reconciles `GWASTrack`.
- `loadBamTrackFromLocalData` still serves its exported bam from the static
  `tracks/` path, not `serveLocalFile()`; changing that changes the wire
  message (`bamDataFilepath`) and the JS handler, so it is out of scope.
- `loadBedGraphTrackFromURL`'s pre-existing `message()` call is untouched.

**Open questions for the human (stage 2):**
4. `.bamLocalDataTrackPayload` writes a large file to the static `tracks/`
   dir. Should it switch to `serveLocalFile()` (repo rule for range-read
   files)? That needs the `loadBamTrackFromLocalData` JS handler to accept a
   served url.
5. OK to keep the data.frame/VCF asserts in builders, or should builders be
   as permissive as the old loaders (matrix input for gwas/gff3/seg)?


**Stage 3 (done):** new `R/tracks.R` (Collate: after `rangeServer.R`, before
`igvShiny.R`) with the classes `Track`, `igvAnnotationTrack` (class only),
`DataFrameAnnotationTrack`, `GRangesAnnotationTrack`,
`UCSCBedAnnotationTrack`, `QuantitativeTrack`, `DataFrameQuantitativeTrack`,
`GRangesQuantitativeTrack`, `UCSCBedGraphQuantitativeTrack`, their
constructors, the igvR generics `trackInfo()` / `trackSize()`, and the
exported S4 generic `loadTrack(session, id, track, ...)`. Tests:
`tests/testthat/test-tracks.R`. The class docs carry the new keyword
`track_classes`, indexed by a new "Track classes" section in `_pkgdown.yml`
(pkgdown fails on exported topics missing from the index). No DESCRIPTION
Imports change, no new igv.js
option keys, no JS change.

How it is wired:
- Internal generics `.trackTable(track)` (coreObject -> the data.frame the
  builders take; GRanges/UCSCData go through `.granges2bedTable` /
  `.granges2bedGraphTable`, 1-based starts -> 0-based) and
  `.trackPayload(track, path = NULL, trackConfig = list())` (the builder:
  `igvAnnotationTrack` -> `.bedTrackPayload`, `QuantitativeTrack` ->
  `.bedGraphTrackPayload`; `Track` -> error).
- `loadTrack` methods for `igvAnnotationTrack` (handler
  `loadBedTrackFromFile`, file from `.trackFile(session, ".bed")`) and
  `QuantitativeTrack` (`loadBedGraphTrack`, inline), both through the
  internal sender `.sendTrack()`; method args `deleteTracksOfSameName`,
  `trackConfig`, `validateReference` as on the old loaders. Tests check that
  `loadTrack()` puts the same message on the wire as `loadBedTrack()` /
  `loadBedGraphTrack()` with equivalent arguments.
- Slots sent to the browser are the ones igvR sent: annotation -> color,
  height, `displayMode`; quantitative -> color, height, autoscale, min, max.
  The other slots (row heights, maxRows, searchable, visibilityWindow,
  auto/min/maxTrackHeight) are stored but not sent, as in igvR. Slot values
  win over `trackConfig`, which only adds keys (same rule as the loaders).

Deviations from igvR (intentional):
- `stopifnot`/`ncol`/RColorBrewer replaced by checkmate, `NCOL`,
  `randomColors`; `Track()` now `match.arg()`s trackType/sourceType/
  fileFormat (igvR stored the whole choice vector when an argument was
  omitted) and gives defaults to the numeric slots; the bed9 strand check
  logs via `flog.warn` instead of `warning()`.
- UCSCData slots are typed `GRanges` (its parent) plus a validity check, so
  rtracklayer stays in Suggests; the UCSC constructors `requireNamespace()`.
- `UCSCBedGraphQuantitativeTrack` honours `trackHeight` (igvR hard-coded 50).
- `trackSize()` is one method on `Track` (rows/length of `coreObject`, `NA`
  without one); igvR's `QuantitativeTrack` method referenced a non-existent
  `vcf.obj` slot.
- GRanges annotation tracks are written by hand as 6-column bed (name/score
  from mcols or `.`/0, strand `*` -> `.`) instead of `rtracklayer::export`.
- Annotation tables are sorted by start only (the existing `.bedTrackPayload`
  behaviour); igvR sorted by chrom, then start.

Skipped / left for stage 4:
- `igvAnnotationTrack()` constructor (igvR's ignores its `annotation`
  argument and builds a track with no data); only the class is ported.
- A bare `QuantitativeTrack` (and `Track`) has no data, so `loadTrack()`
  errors on it ("no feature table" / "no method").

**Open questions for the human (stage 3):**
6. `displayMode` is sent, but the `loadBedTrackFromFile` JS handler sets
   `displayMode: "EXPANDED"` in its config and `mergeExtraParameters()` skips
   keys already in the config, so the slot (and a user
   `trackConfig$displayMode` on `loadBedTrack`) has no effect in the browser
   today. Fix in JS (let message keys override handler defaults for an
   allowlisted set)? Out of M1 scope as written; not changed.
   After the gate review, the roxygen of the track classes says so: the slots
   that are stored but not sent are documented as such.
7. igvR exports the same class and constructor names. Once igvShiny is
   released with them, should igvR import them from igvShiny (and drop its
   own copies) to avoid masking when both are attached?
8. Should `loadTrack()` also return the payload (invisibly) for debugging?
   It returns `NULL` now, like the other loaders.


**Stage 4 (done):** ported `GenomicAlignmentTrack`, `RemoteAlignmentTrack`,
`CramTrack`, `VariantTrack`, `GFF3Track`, `BedpeInteractionsTrack` and an
`igvAnnotationTrack()` constructor into `R/tracks.R`, each with a
`.trackPayload` method that reuses the stage 2 builder of its loader
(`.bamLocalDataTrackPayload`, `.bamUrlTrackPayload`, `.cramUrlTrackPayload`,
`.vcfTrackPayload`, `.gff3TrackPayload` / `.gff3UrlTrackPayload`) and a
`loadTrack()` method. Tests: `tests/testthat/test-tracks-alignment-variant.R`.
Each one checks that `loadTrack()` sends the same message as the matching
loader given equivalent arguments. NEWS 1.9.52, DESCRIPTION Version and Date
bumped. Imports are unchanged.

What changed besides the class port:
- `.sendTrack()` validates against `.trackReferenceData(track)`, a new
  internal generic. It returns the feature table by default, the
  GAlignments/VCF object for alignment and variant tracks, both bedpe anchors
  for bedpe, and NULL for url tracks, which skips the check as the url
  loaders do. After the builder runs, it also registers extra written files
  (the bam `.bai`) for session cleanup.
- `Track()` accepts igvR's trackType values `genomicAlignment`,
  `remoteAlignment` and `pairedEndAnnotation`, and the file formats `cram` and
  `bedpe`.
- Slots typed with Suggests classes (`alignment`, `vcf.obj`) are `"ANY"`, with
  a validity check, as stage 3 proposed.
- New `homvarColor`, `hetvarColor` and `homrefColor` in
  `.validIgvTrackOptions`. Each identifier appears in the igv-3.8.4 bundle as
  a VariantTrack config default.
- **bedpe:** new builder `.bedpeTrackPayload` (R/igvShiny.R) and a new JS
  handler `loadBedpeTrackFromFile` (igv.js type `interact`, format `bedpe`).
  This is the only JS change in M1. It has a node harness scenario
  (`bedpe-handler`, which runs only when requested) but was never checked in
  a real browser. There is no exported data.frame loader for it.

**GWASTrack decision:** igvShiny's `GWASTrack` stays as it is: no `Track`
parent, same slots, `display()` and `getUrl()` unchanged. Its message
building moved into the builder `.gwasTrackObjectPayload(obj)` in
`R/GWASTrack.R`, and the wire message is unchanged. `loadTrack(session, id,
<GWASTrack>)` is a method that calls `display()`. igvR's `GWASTrack` and
`GWASUrlTrack` are not ported; their name clashes with igvShiny's class.

Deviations from igvR:
- igvR's `VariantTrack` never stored `anchorColor`; it is stored now.
- igvR's `GFF3Track` errored on a `colorTable` without a "default" entry; that
  is fixed.
- `GFF3Track` now has defaults (EXPANDED, 50, 1e5).
- `RemoteAlignmentTrack` defaults `bamIndex` to `<bamUrl>.bai`; igvR's NULL
  default could not fill its character slot.
- Colors are sent as given; igvR converted them to hex with `col2rgb`.

Skipped / open questions for the human (stage 4):
9. A url `VariantTrack` (`vcf = list(data, index)`) is constructed, but
   `loadTrack()` refuses it. The `loadVcfTrack` JS handler prepends the app
   url, so a remote vcf needs a new handler. Add one?
10. The `loadVcfTrack` handler hard-codes `displayMode`, `height` and
    `visibilityWindow`, so those VariantTrack slots are not sent; only the
    colors reach igv.js. This is the same problem as question 6.
11. Keep the bedpe JS handler, which is unverified in a real browser? Also add
    an exported `loadBedpeTrack()` data.frame loader?
12. `GenomicAlignmentTrack` serves its bam from the static `tracks/` path,
    like `loadBamTrackFromLocalData` (see question 4).
13. The `GWASTrack()` constructor still writes with
    `tempfile(tmpdir = .tracksDir())`, because it has no session. Move the
    write into `display()`/`loadTrack()` via `.trackFile()`?
