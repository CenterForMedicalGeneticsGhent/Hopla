#!/usr/bin/env Rscript

files <- c(
  list.files("R", pattern = "[.]R$", full.names = TRUE),
  list.files("tests", pattern = "[.]R$", full.names = TRUE, recursive = TRUE),
  "exec/hopla",
  "exec/hopla-run.R"
)

lints <- lapply(files, lintr::lint)
lint_count <- sum(lengths(lints))

if (lint_count > 0L) {
  for (file_lints in lints) print(file_lints)
  quit(status = 1L)
}

cat("No lints found.\n")
