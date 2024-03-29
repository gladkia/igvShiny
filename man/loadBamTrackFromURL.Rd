% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/igvShiny.R
\name{loadBamTrackFromURL}
\alias{loadBamTrackFromURL}
\title{load a bam track which, with index, is served up by http}
\usage{
loadBamTrackFromURL(
  session,
  id,
  trackName,
  bamURL,
  indexURL,
  deleteTracksOfSameName = TRUE,
  displayMode = "EXPANDED",
  showAllBases = FALSE
)
}
\arguments{
\item{session}{an environment or list, provided and managed by shiny}

\item{id}{character string, the html element id of this widget instance}

\item{trackName}{character string}

\item{bamURL}{character string http url for the bam file, 
typically very large}

\item{indexURL}{character string http url for the bam file index, 
typically small}

\item{deleteTracksOfSameName}{logical, default TRUE}

\item{displayMode}{character string, possible values are "EXPANDED"(default),
"SQUISHED" or "COLLAPSED"}

\item{showAllBases}{logical, show all bases in the alignment, default FALSE}
}
\value{
nothing
}
\description{
load a remote bam track
}
\examples{
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}

}
\keyword{track_loaders}
