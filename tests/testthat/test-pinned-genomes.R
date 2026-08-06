test_that("the human stock genomes keep their assets off hgdownload", {
  # Requesting hg19 or hg38 by bare id hands igv.js the genomes3.json entry,
  # where sequence, cytobands and the RefSeq annotation all sit on
  # hgdownload.soe.ucsc.edu: a host that throttles to tens of seconds per range
  # request, serving an unindexed whole-genome annotation on top of it. That is
  # a browser which looks hung on startup, so igvShiny.js pins its own
  # reference for the two of them. A revert to the bare id is silent - it costs
  # startup time, never correctness - so assert the pin here.
  binding <- system.file("htmlwidgets", "igvShiny.js", package = "igvShiny")
  expect_true(file.exists(binding))
  js <- paste(readLines(binding, warn = FALSE), collapse = "\n")

  pinned <- sub(".*function pinnedReference\\(", "", js)
  pinned <- sub("\\n\\}.*", "", pinned)

  expect_match(pinned, "hg19:", fixed = TRUE)
  expect_match(pinned, "hg38:", fixed = TRUE)
  expect_false(grepl("hgdownload.soe.ucsc.edu", pinned, fixed = TRUE))

  # the annotation has to be the tabix-indexed build: the plain one is
  # whole-genome, and igv.js reads all of it before drawing the first gene
  expect_equal(lengths(regmatches(pinned, gregexpr("indexURL", pinned)))[1], 1L)
  expect_match(pinned, "indexed: true", fixed = TRUE)

  # twoBitURL has to be spelled out for both, and this is the assertion that
  # earns its keep: igv.js merges the registry entry by id, so a reference
  # naming only a fasta keeps the registry's twoBitURL and the sequence comes
  # from UCSC after all. getSequence() then never resolves and every alignment
  # track spins forever, while the gene track still draws - so the symptom
  # points nowhere near the cause
  twoBit <- regmatches(pinned, gregexpr("twoBitURL: \"[^\"]+\"", pinned))[[1]]
  expect_length(twoBit, 2L)
  expect_true(all(grepl("https://igv.org/genomes/data/", twoBit, fixed = TRUE)))
})
