% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/igvShiny.R
\name{igvShinyOutput}
\alias{igvShinyOutput}
\title{create the UI for the widget}
\usage{
igvShinyOutput(outputId, width = "100\%", height = NULL)
}
\arguments{
\item{outputId}{a character string, specifies the html element id}

\item{width}{a character string, standard css notations, 
either e.g., "1000px" or "95\%", "100\%" by default}

\item{height}{a character string, needs to be an explicit pixel measure, 
e.g., "800px", "400px" by default}
}
\value{
the created widget's html
}
\description{
This function is called in the ui function of your shiny app
}
\examples{
io <- igvShinyOutput("igvOut")

}
\keyword{igvShiny}
