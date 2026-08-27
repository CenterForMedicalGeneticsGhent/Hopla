\name{hopla_convert_settings}
\alias{hopla_convert_settings}
\title{Convert Legacy Hopla Settings to YAML}
\usage{
hopla_convert_settings(legacy, output = NULL, schema = NULL)
}
\arguments{
  \item{legacy}{Path to a legacy \code{key=value} settings file.}
  \item{output}{Optional YAML output path. Defaults to the input path with a
    \code{.yaml} extension.}
  \item{schema}{Optional path to \code{hopla.schema.json}. Located
    automatically when omitted.}
}
\value{The output path, invisibly.}
\description{
Reads the historical settings format, maps dotted keys to snake_case schema
properties, omits unset values, coerces types, and writes YAML after JSON
Schema validation. \code{NA} tokens in parent and gender lists become YAML
\code{null}.
}
