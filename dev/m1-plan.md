# M1: Shared S4 Track Engine

Move the S4 `Track` hierarchy from igvR into igvShiny and split every igvShiny
track loader into a pure **payload builder** and a thin **sender**.

## Stages

- [x] 1. Inventory + pattern: this file, `^dev$` in `.Rbuildignore`,
      builder/sender split of the BED and bedGraph loaders, tests
- [ ] 2. Builder/sender split for all remaining loaders in `R/igvShiny.R`
      (VCF, seg, GWAS, BAM/CRAM, URL loaders, GFF3, splice junctions), tests
- [ ] 3. Port `Track`, `QuantitativeTrack`, `igvAnnotationTrack` (needed as the
      parent, see below), `GRangesAnnotationTrack`, `DataFrameAnnotationTrack`,
      `UCSCBedAnnotationTrack`, `GRangesQuantitativeTrack`,
      `DataFrameQuantitativeTrack`, `UCSCBedGraphQuantitativeTrack` into
      `R/tracks.R` (Collate before `igvShiny.R`); a builder method per class;
      exported `loadTrack(session, id, track)` generic + methods; tests
- [ ] 4. `GenomicAlignmentTrack`, `VariantTrack`, `BedpeInteractionsTrack`,
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

**For stage 3 (from the stage 1 gate review):** `displayMode` passed through
`trackConfig` to `loadBedTrack` is merged in R but ignored in the browser:
`igvShiny.js` hard-codes `displayMode: "EXPANDED"` in the
`loadBedTrackFromFile` handler, and `mergeExtraParameters()` skips keys the
handler already set. `igvAnnotationTrack@displayMode` will hit this; it needs a
JS-side fix or a decision before the annotation `loadTrack()` methods land.

**Open questions for the human:**
1. Should builders eventually return a genuine igv.js track config (with
   `type`, `format`, `url`, ...) so one generic JS handler can serve
   `loadTrack()`? That moves logic out of `igvShiny.js` and is a bigger
   change than M1 allows; for now `config` = the existing handler payload.
2. Builders are internal (`@keywords internal`, not exported). Export them
   later for igvR to reuse, or have igvR call `loadTrack()` only?
3. `GWASTrack` reconciliation (see hazards) — confirm the "keep igvShiny's
   class, add a `loadTrack` method" default before stage 4.
