flow_fixture <- function(path, reverse = FALSE) {
  value <- data.frame(
    chr = c("chr1", "chr2"),
    pos = 1:2,
    flowA.hexcol = c("red", "blue"),
    flowB.hexcol = c("green", "yellow")
  )
  if (reverse) value <- value[2:1, ]
  data.table::fwrite(value, path, sep = "\t")
}

hopla_cli_path <- function() {
  candidates <- c(
    file.path(getwd(), "exec", "hopla"),
    file.path(getwd(), "..", "..", "exec", "hopla"),
    file.path(getwd(), "..", "exec", "hopla")
  )
  for (candidate in candidates) {
    normalized <- normalizePath(candidate, mustWork = FALSE)
    if (file.exists(normalized)) {
      return(normalized)
    }
  }
  installed <- system.file("exec", "hopla", package = "hopla")
  if (nzchar(installed)) {
    return(installed)
  }
  stop("Could not locate hopla CLI.", call. = FALSE)
}

engine_path <- function() {
  candidates <- c(
    file.path(getwd(), "exec", "hopla-run.R"),
    file.path(getwd(), "..", "..", "exec", "hopla-run.R"),
    file.path(getwd(), "..", "exec", "hopla-run.R")
  )
  for (candidate in candidates) {
    normalized <- normalizePath(candidate, mustWork = FALSE)
    if (file.exists(normalized)) {
      return(normalized)
    }
  }
  installed <- system.file("exec", "hopla-run.R", package = "hopla")
  if (nzchar(installed)) {
    return(installed)
  }
  stop("Could not locate hopla engine.", call. = FALSE)
}

is_function_assignment <- function(expression) {
  is.call(expression) &&
    as.character(expression[[1]]) %in% c("<-", "=") &&
    is.call(expression[[3]]) &&
    identical(as.character(expression[[3]][[1]]), "function")
}

engine_functions <- function() {
  env <- new.env(parent = asNamespace("plotly"))
  for (expression in parse(engine_path())) {
    if (is_function_assignment(expression)) {
      eval(expression, env)
    }
  }
  env
}

schema_path <- function() {
  candidates <- c(
    file.path(getwd(), "inst", "schema", "hopla.schema.json"),
    file.path(getwd(), "..", "..", "inst", "schema", "hopla.schema.json")
  )
  for (candidate in candidates) {
    normalized <- normalizePath(candidate, mustWork = FALSE)
    if (file.exists(normalized)) {
      return(normalized)
    }
  }
  installed <- system.file("schema", "hopla.schema.json", package = "hopla")
  if (nzchar(installed)) {
    return(installed)
  }
  stop("Could not locate hopla schema.", call. = FALSE)
}

hopla_cli <- function(...) {
  hopla_path <- hopla_cli_path()
  command <- paste(
    shQuote(file.path(R.home("bin"), "Rscript")),
    shQuote(hopla_path),
    paste(vapply(list(...), shQuote, character(1)), collapse = " ")
  )
  system(command, intern = TRUE)
}

hopla_cli_status <- function(...) {
  hopla_path <- hopla_cli_path()
  args <- vapply(list(...), shQuote, character(1))
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(hopla_path, args),
    stdout = FALSE,
    stderr = FALSE
  )
  if (is.null(status)) NA_integer_ else as.integer(status)
}

test_that("concordance aligns shared markers", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second, reverse = TRUE)

  expect_equal(unname(hopla_concordance(first, second)), c(100, 0, 0, 100))
})

test_that("transform writes matching strand comparisons", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  output <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second, reverse = TRUE)

  expect_identical(hopla_transform(first, second, 1, output), output)
  transformed <- data.table::fread(output)
  expect_true(all(transformed$flowA.hexcol))
  expect_true(all(transformed$flowB.hexcol))
})

test_that("cli help and version exit successfully", {
  expect_equal(hopla_cli_status("-h"), 0L)
  expect_equal(hopla_cli_status("-hV"), 0L)
  expect_equal(hopla_cli_status("-V"), 0L)
  expect_match(hopla_cli("-V")[1], "^v2\\.0\\.0$")
})

test_that("cli rejects unknown options with usage status", {
  expect_equal(hopla_cli_status(), 2L)
  expect_equal(hopla_cli_status("-v"), 2L)
  expect_equal(hopla_cli_status("-x"), 2L)
  expect_equal(hopla_cli_status("--"), 2L)
  expect_equal(hopla_cli_status("concordance", "-x", "a.txt", "b.txt"), 2L)
})

test_that("cli concordance supports -r before operands", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second)

  output <- hopla_cli("concordance", "-r", first, second)
  expect_length(output, 4)
})

test_that("cli rejects options after operands", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second)

  expect_equal(hopla_cli_status("concordance", first, second, "-r"), 2L)
})

test_that("cli supports -- to terminate option parsing", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second)

  expect_equal(hopla_cli_status("concordance", "--", first, second), 0L)
})

test_that("cli transform requires mode operand", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second)

  expect_equal(hopla_cli_status("transform", first, second), 2L)
})

test_that("settings schema uses snake_case keys", {
  schema <- jsonlite::fromJSON(schema_path(), simplifyVector = FALSE)
  expect_true("sample_ids" %in% schema$required)
  expect_false("vcf_file" %in% names(schema$properties))
  expect_false("out_dir" %in% names(schema$properties))
  expect_false(any(grepl("\\.", unlist(schema$required))))
})

legacy_fixture <- function(path, extra = character()) {
  writeLines(c(
    "vcf.file=/data/family.vcf.gz",
    "out.dir=/tmp",
    "sample.ids=child,dad,mom",
    "father.ids=dad,NA,NA",
    "mother.ids=mom,NA,NA",
    "genders=F,M,F",
    "run.merlin=T",
    "af.hard.limit=.25",
    "min.seg.var.X=15",
    "X.cutoff=1.5",
    "limit.pm.to.P=F",
    "keep.hetero.ids=",
    "start.info",
    "Disease: example",
    "end.info",
    extra
  ), path)
}

test_that("legacy settings convert to validated snake_case yaml", {
  legacy <- tempfile(fileext = ".txt")
  output <- tempfile(fileext = ".yaml")
  legacy_fixture(legacy)

  expect_identical(hopla_convert_settings(legacy, output, schema_path()), output)
  converted <- yaml::read_yaml(output)

  expect_null(converted$vcf_file)
  expect_null(converted$out_dir)
  expect_identical(converted$sample_ids, c("child", "dad", "mom"))
  expect_identical(converted$father_ids, list("dad", NULL, NULL))
  expect_identical(converted$genders, c("F", "M", "F"))
  expect_true(converted$run_merlin)
  expect_equal(converted$af_hard_limit, 0.25)
  expect_equal(converted$min_seg_var_x, 15)
  expect_equal(converted$x_cutoff, 1.5)
  expect_false(converted$limit_pm_to_p)
  expect_null(converted$keep_hetero_ids)
  expect_identical(converted$info, "Disease: example")
})

test_that("legacy conversion rejects unknown keys and missing required fields", {
  unknown <- tempfile(fileext = ".txt")
  missing <- tempfile(fileext = ".txt")
  writeLines(c("sample.ids=child", "unknown.arg=1"), unknown)
  writeLines("run.merlin=T", missing)

  expect_error(hopla_convert_settings(unknown, tempfile(fileext = ".yaml"), schema_path()), "Unknown")
  expect_error(hopla_convert_settings(missing, tempfile(fileext = ".yaml"), schema_path()), "validation")
})

test_that("cli convert writes yaml and reports usage errors", {
  legacy <- tempfile(fileext = ".txt")
  output <- tempfile(fileext = ".yaml")
  legacy_fixture(legacy)

  expect_equal(hopla_cli_status("convert"), 2L)
  expect_equal(hopla_cli_status("convert", legacy, output), 0L)
  expect_true(file.exists(output))
  expect_match(paste(readLines(output), collapse = "\n"), "sample_ids:")
  expect_false(any(grepl("vcf_file|out_dir", readLines(output))))
})

test_that("cli run requires settings and vcf and checks path existence", {
  settings <- tempfile(fileext = ".yaml")
  writeLines("sample_ids: [child]", settings)
  missing_vcf <- file.path(tempdir(), "no-such-family.vcf.gz")
  missing_dir <- file.path(tempdir(), "no-such-hopla-out")

  expect_equal(hopla_cli_status("run"), 2L)
  expect_equal(hopla_cli_status("run", settings), 2L)
  expect_equal(hopla_cli_status("run", settings, missing_vcf), 1L)
  expect_equal(hopla_cli_status("run", "-o", missing_dir, settings, tempfile()), 1L)
})

test_that("log level filters stdout records", {
  previous <- hopla_log_level()
  on.exit(hopla_log_level(previous), add = TRUE)

  hopla_log_level("warn")
  expect_identical(capture.output(hopla:::hopla_log("info", "skip-me")), character())
  hopla_log_level("info")
  logged <- capture.output(hopla:::hopla_log("info", "keep-me"))
  expect_match(logged, "INFO keep-me")
})

test_that("mark_region draws region and flank traces", {
  skip_if_not_installed("plotly")
  engine <- engine_functions()
  engine$args <- list(regions_flanking_size = 50, dot_factor = 2)
  engine$colors <- rep("#1f78b4", 12)
  engine$letters <- c("A", "B")

  marked <- engine$mark_region(
    plotly::plot_ly(),
    c(chr1 = 0),
    c(0, 1),
    "chr1:100-200",
    c(chr1 = 1000)
  )
  without_flanks <- engine$mark_region(
    plotly::plot_ly(),
    c(chr1 = 0),
    c(0, 1),
    "chr1:100-200",
    c(chr1 = 1000),
    plot_flanks = FALSE
  )

  expect_s3_class(marked, "plotly")
  expect_equal(
    length(marked$x$attrs) - length(without_flanks$x$attrs),
    2L
  )
})

test_that("engine helpers do not shadow attached package exports", {
  packages <- c(
    "base", "plotly", "data.table", "GenomicRanges", "DNAcopy", "vcfR",
    "htmltools", "kinship2", "scales", "RColorBrewer"
  )
  for (package in packages) skip_if_not_installed(package)

  defined <- ls(engine_functions())
  exported <- unlist(lapply(packages, getNamespaceExports), use.names = FALSE)

  expect_identical(intersect(defined, exported), character())
})

rscript <- function() file.path(R.home("bin"), "Rscript")

hopla_namespace_available <- function() {
  output <- suppressWarnings(system2(
    rscript(),
    c("-e", shQuote("cat(requireNamespace('hopla', quietly = TRUE))")),
    stdout = TRUE,
    stderr = FALSE
  ))
  any(grepl("TRUE", output, fixed = TRUE))
}

test_that("scripts run from an installed layout without the source R directory", {
  skip_if_not(hopla_namespace_available(), "hopla is not installed")

  exec_dir <- file.path(tempfile("hopla-installed"), "exec")
  dir.create(exec_dir, recursive = TRUE)
  file.copy(hopla_cli_path(), file.path(exec_dir, "hopla"))
  file.copy(engine_path(), file.path(exec_dir, "hopla-run.R"))

  engine_status <- system2(
    rscript(),
    c(shQuote(file.path(exec_dir, "hopla-run.R")), "-h"),
    stdout = FALSE,
    stderr = FALSE
  )
  cli_status <- system2(
    rscript(),
    c(shQuote(file.path(exec_dir, "hopla")), "-V"),
    stdout = FALSE,
    stderr = FALSE
  )

  expect_equal(as.integer(engine_status), 0L)
  expect_equal(as.integer(cli_status), 0L)
})

test_that("cli rejects unknown log levels", {
  expect_equal(hopla_cli_status("-L"), 2L)
  expect_equal(hopla_cli_status("-L", "nope"), 2L)
  expect_equal(hopla_cli_status("-L", "debug", "-h"), 0L)
})
