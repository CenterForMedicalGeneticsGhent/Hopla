\name{hopla_subtools}
\alias{hopla_concordance}
\alias{hopla_transform}
\title{Work with Hopla Haplotype Flow Tables}
\usage{
hopla_concordance(flow1, flow2, relative = FALSE)

hopla_transform(flow1, flow2, mode, output = NULL)
}
\arguments{
  \item{flow1, flow2}{Paths to Hopla flow tables.}
  \item{relative}{Whether to compare each flow relative to its first marker.}
  \item{mode}{Either 1 for matching strands or 2 for crossed strands.}
  \item{output}{Optional transformed-table output path.}
}
\value{
\code{hopla_concordance()} returns four named percentages.
\code{hopla_transform()} returns the output path invisibly.
}
\description{
Aligns flow tables by chromosome and position, then calculates strand
concordance or writes logical strand comparisons.
}
