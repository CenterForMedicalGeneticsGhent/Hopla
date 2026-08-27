\name{hopla_run}
\alias{hopla_run}
\title{Run a Hopla Analysis}
\usage{
hopla_run(settings, vcf_file, out_dir = getwd(), engine = NULL)
}
\arguments{
  \item{settings}{Path to a YAML or JSON settings file.}
  \item{vcf_file}{Path to a (multisample) \code{vcf.gz} file. Must exist.}
  \item{out_dir}{Output directory. Defaults to the current working directory
    and must already exist.}
  \item{engine}{Optional analysis-engine path for development and testing.}
}
\value{The engine process exit status, invisibly.}
\description{
Runs the Hopla analysis engine in a clean R process. The engine validates the
settings file against the installed JSON Schema before loading analysis data.
The VCF path and output directory are supplied here, not in the settings file.
}
