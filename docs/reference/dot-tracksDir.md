# Get the tracks directory and make sure shiny serves that very directory

The "tracks" resource path is registered once, when the package is
loaded. The default directory lives under
[`tempdir()`](https://rdrr.io/r/base/tempfile.html), which is not
guaranteed to stay put for the life of the process: when it moves, files
are written to the new directory while shiny still serves the old one,
and igv.js gets a 404 for a file that exists on disk. Re-registering the
path before each write keeps the served directory and the written
directory the same.

## Usage

``` r
.tracksDir()
```

## Value

string with the path to the tracks directory.
