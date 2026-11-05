# What loadTrack checks against the reference genome

What `.validateTrackReference` gets for a track: the feature table for
the data.frame families, the Bioconductor object for alignment and
variant tracks, and NULL (nothing checked, as with the url loaders) for
tracks that only point at urls.

## Usage

``` r
.trackReferenceData(track)
```

## Arguments

- track:

  an object of a Track subclass

## Value

a data.frame, a GAlignments or VCF object, or NULL
