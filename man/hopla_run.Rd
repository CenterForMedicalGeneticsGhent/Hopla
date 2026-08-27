\name{hopla_run}
\alias{hopla_run}
\title{Run a Hopla Analysis}
\usage{
hopla_run(settings, engine = NULL)
}
\arguments{
  \item{settings}{Path to a YAML or JSON settings file.}
  \item{engine}{Optional analysis-engine path for development and testing.}
}
\value{The engine process exit status, invisibly.}
\description{
Runs the Hopla analysis engine in a clean R process. The engine validates the
settings file against the installed JSON Schema before loading analysis data.
}
