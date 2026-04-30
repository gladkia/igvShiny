# get_tracks_dir Get the directory where tracks are stored. The directory can be defined with environmental variable. If not defined the default is a directory called "tracks" in the temp directory. We need a local directory to write files - for instance, a vcf file representing a genomic region of interest. We then tell shiny about that directory, so that shiny's built-in http server can serve up files we write there, ultimately consumed by igv.js

get_tracks_dir Get the directory where tracks are stored. The directory
can be defined with environmental variable. If not defined the default
is a directory called "tracks" in the temp directory. We need a local
directory to write files - for instance, a vcf file representing a
genomic region of interest. We then tell shiny about that directory, so
that shiny's built-in http server can serve up files we write there,
ultimately consumed by igv.js

## Usage

``` r
get_tracks_dir(env_var = "TRACKS_DIR")
```

## Arguments

- env_var:

  The name of the environmental variable to use.

## Value

string with the path to the tracks directory.

## Examples

``` r
gtd <- get_tracks_dir(env_var = "TRACKS_DIR")
```
