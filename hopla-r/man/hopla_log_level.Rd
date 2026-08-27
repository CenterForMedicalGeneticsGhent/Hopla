\name{hopla_log_level}
\alias{hopla_log_level}
\title{Get or Set the Hopla Log Level}
\usage{
hopla_log_level(level = NULL)
}
\arguments{
  \item{level}{Optional level name: \code{error}, \code{warn}, \code{info}, or
    \code{debug}. \code{warning} aliases \code{warn}; \code{quiet} aliases
    \code{error}.}
}
\value{The active log level. When \code{level} is set, it is returned invisibly.}
\description{
Controls which log records are emitted. Error and warning records go to
standard error; information and debug records go to standard output. Each
record is prefixed with a timestamp and the level name.
}
