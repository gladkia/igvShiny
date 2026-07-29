# igvShiny — public demo on Posit Connect Cloud.
#
# This used to be a hand-maintained copy of inst/demos/igvShinyDemo.R with a
# bslib skin. The two drifted every time a loader was added, so the copy is
# gone: the deploy now runs the package's own flagship demo, which carries the
# skin. Whatever the live demo shows is exactly what a user gets from
# runApp(system.file("demos", "igvShinyDemo.R", package = "igvShiny")).
#
# The demo file is inside the installed package, so manifest.json's pinned
# igvShiny commit decides which version of the app is served - see README.md.
# The flagship deliberately avoids the *FromLocalData loaders, which is what
# keeps Rsamtools / GenomicAlignments out of this deploy.

library(igvShiny)

# an igvShiny old enough to predate the demo returns "" here, and
# shinyAppFile("") greys the page out with nothing to explain it - the failure
# mode README.md warns about. Name the installed version instead.
app.file <- system.file("demos", "igvShinyDemo.R", package = "igvShiny")
if (!nzchar(app.file))
  stop(sprintf("igvShiny %s ships no demos/igvShinyDemo.R - bump the pinned SHA in manifest.json",
               utils::packageVersion("igvShiny")))

shiny::shinyAppFile(app.file)
