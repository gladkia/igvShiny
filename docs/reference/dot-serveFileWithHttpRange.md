# Internal HTTP Range request handler for local files

Internal HTTP Range request handler for local files

## Usage

``` r
.serveFileWithHttpRange(filePath, req)
```

## Arguments

- filePath:

  character, normalized path to existing local file

- req:

  environment, Rook request environment supplied by Shiny

## Value

An `httpResponse` object (status 206 for Range requests, 200 otherwise)
