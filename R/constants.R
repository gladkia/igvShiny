CAS_GENOMES <-
  c("hg38", "hg19", "mm10", "tair10", "custom", "dm6", "sacCer3")

BASIC_GENOMES <-
  c("hg38",
    "hg19",
    "mm10",
    "tair10",
    "rhos",
    "custom",
    "dm6",
    "sacCer3")

randomColors <- randomcoloR::distinctColorPalette(24)

state <- new.env(parent = emptyenv())
state[["userAddedTracks"]] <- list()
