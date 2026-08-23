# Make a file on disk reachable by igv.js

Files igv.js reads by url have to sit in the directory shiny serves as
"tracks". Alignment files run to gigabytes, so the file is linked rather
than copied where the filesystem allows it (windows, and any mount
refusing links, falls back to a copy). The name is randomized: two
loaders may be handed same-named files from different directories.

## Usage

``` r
.stageTrackFile(session, path, ext)
```

## Arguments

- session:

  a shiny session object; the staged file is removed when that session
  ends

- path:

  character string, an existing file

- ext:

  character string, the extension of the served file

## Value

string with the path to the file, relative to the shiny app
