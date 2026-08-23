# Name a file in the served tracks directory, and have it removed with the session that asked for it

Loaders write a file per track load and nothing ever removes it. In an
interactive session that is harmless - the default directory sits under
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) and goes with the
process - but a deployed app keeps one R process across many user
sessions, and `TRACKS_DIR` may point outside
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) altogether, where
nothing removes the files at all. Alignment loads make it concrete: a
bam export or a cram copy is gigabytes.

The paths handed out to one session are collected in that session's
`userData`, and the first call registers a single
`session$onSessionEnded()` hook to unlink the set. Assignment goes
through a local binding to the `userData` environment on purpose:
`session$userData$x <- value` would call the assignment method of a
module's session proxy, which refuses to be written to.

## Usage

``` r
.trackFile(session, ext)
```

## Arguments

- session:

  a shiny session object

- ext:

  character string, the extension of the served file

## Value

string with the path to the file
