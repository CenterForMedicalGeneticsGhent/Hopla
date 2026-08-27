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

engine_local_functions <- function() {
  pattern <- "^[[:space:]]*([A-Za-z._][A-Za-z0-9._]*)[[:space:]]*(<-|=)[[:space:]]*function.*$"
  lines <- readLines(engine_path())
  unique(sub(pattern, "\\1", lines[grepl(pattern, lines)]))
}

call_parts <- function(expression) {
  parts <- as.list(expression)
  # Empty arguments such as `x[i, ]` cannot be evaluated, so probe safely.
  is_call_part <- function(part) tryCatch(is.call(part), error = function(error) FALSE)
  parts[vapply(parts, is_call_part, logical(1))]
}

engine_calls <- function() {
  calls <- list()
  walk <- function(expression) {
    calls[[length(calls) + 1L]] <<- expression
    for (part in call_parts(expression)) walk(part)
  }
  for (expression in parse(engine_path())) {
    if (is.call(expression)) walk(expression)
  }
  calls
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
  expect_false("cytoband_file" %in% names(schema$properties))
  expect_false(any(grepl("\\.", unlist(schema$required))))
})

legacy_fixture <- function(path, extra = character()) {
  writeLines(c(
    "vcf.file=/data/family.vcf.gz",
    "out.dir=/tmp",
    "cytoband.file=/ref/cytoband.hg38.txt",
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
  expect_null(converted$cytoband_file)
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
  expect_false(any(grepl("vcf_file|out_dir|cytoband_file", readLines(output))))
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

test_that("cli run takes the cytoband table as a path", {
  settings <- tempfile(fileext = ".yaml")
  writeLines("sample_ids: [child]", settings)
  vcf <- tempfile(fileext = ".vcf.gz")
  file.create(vcf)
  missing_cytoband <- file.path(tempdir(), "no-such-cytoband.txt")

  expect_equal(hopla_cli_status("run", "-c"), 2L)
  expect_equal(hopla_cli_status("run", "-c", missing_cytoband, settings, vcf), 1L)
  expect_error(
    hopla_run(settings, vcf, tempdir(), cytoband_file = missing_cytoband),
    "Cytoband file does not exist"
  )
})

test_that("cytoband_file is rejected as a settings property", {
  settings <- tempfile(fileext = ".yaml")
  writeLines(c("sample_ids: [child]", "cytoband_file: /ref/cytoband.hg38.txt"), settings)
  vcf <- tempfile(fileext = ".vcf.gz")
  file.create(vcf)

  # schema violations are usage errors, like any other unknown property
  expect_equal(hopla_cli_status("run", settings, vcf), 2L)
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

test_that("type.convert coercion warnings are logged at debug", {
  skip_if_not_installed("data.table")
  previous <- hopla_log_level()
  on.exit(hopla_log_level(previous), add = TRUE)

  coerce <- function() {
    hopla:::hopla_with_debug_warnings(
      data.table::tstrsplit(
        c("1,2", ".", NA, "3,4"),
        ",",
        fixed = TRUE,
        type.convert = as.numeric,
        keep = 1:2
      )
    )
  }

  hopla_log_level("info")
  expect_warning(invisible(coerce()), NA)
  expect_identical(capture.output(invisible(coerce())), character())

  hopla_log_level("debug")
  logged <- capture.output(invisible(coerce()))
  expect_match(paste(logged, collapse = "\n"), "NAs introduced by coercion")
})

test_that("variant depth histograms contain bins instead of raw depths", {
  skip_if_not_installed("plotly")
  engine <- engine_functions()
  engine$args <- list(
    samples_no_u = "sample",
    samples_out = "Sample",
    sample_ids = "sample"
  )
  engine$colors <- "#1f78b4"
  depths <- rep(seq_len(1000), 100)

  figures <- engine$get_var_depth_hist(list(sample = data.frame(DP = depths)))
  built <- plotly::plotly_build(figures$sample)
  trace <- built$x$data[[1]]

  expect_identical(trace$type, "bar")
  expect_lte(length(trace$x), 100L)
  expect_equal(sum(trace$y), length(depths))
})

test_that("variant depth histograms share one scale across panels", {
  skip_if_not_installed("plotly")
  engine <- engine_functions()
  engine$args <- list(
    samples_no_u = c("a", "b"),
    samples_out = c("A", "B"),
    sample_ids = c("a", "b")
  )
  engine$colors <- "#1f78b4"

  # very different depth distributions must still land on one common axis
  figures <- engine$get_var_depth_hist(list(
    a = data.frame(DP = rep(c(10, 20, 30), 200)),
    b = data.frame(DP = rep(c(300, 400), 5))
  ))
  built <- lapply(figures, plotly::plotly_build)

  expect_equal(
    unlist(built$a$x$layout$xaxis$range),
    unlist(built$b$x$layout$xaxis$range)
  )
  expect_equal(
    unlist(built$a$x$layout$yaxis$range),
    unlist(built$b$x$layout$yaxis$range)
  )
  expect_equal(built$a$x$data[[1]]$x, built$b$x$data[[1]]$x)
})

test_that("htmlwidget JSON is compressed and round-trips", {
  engine <- engine_functions()
  payload <- paste0('{"value":"', strrep("compressible-data-", 1000), '"}')
  html <- paste0(
    "<html><head></head><body>",
    '<script type="application/json" data-for="htmlwidget-test">',
    payload,
    "</script></body></html>"
  )

  compressed <- engine$compress_widget_data(html)
  tag <- regmatches(
    compressed,
    regexpr(
      '<script type="application/gzip\\+json"[^>]*>[^<]+</script>',
      compressed,
      perl = TRUE
    )
  )
  encoded <- sub("^.*>", "", sub("</script>$", "", tag))
  restored <- rawToChar(memDecompress(
    base64enc::base64decode(encoded),
    type = "gzip"
  ))

  expect_identical(restored, payload)
  expect_false(grepl(payload, compressed, fixed = TRUE))
  expect_match(compressed, 'DecompressionStream\\("deflate"\\)')
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

test_that("axes without tick labels do not set a title standoff", {
  # Plotly derives the standoff from the tick-label depth, so a standoff on an
  # axis with hidden tick labels drops every title at the top of the figure.
  offenders <- character()
  for (expression in engine_calls()) {
    head <- expression[[1]]
    if (!is.name(head) || !identical(as.character(head), "list")) next
    supplied <- as.list(expression)[-1]
    names(supplied) <- names(expression)[-1]
    hides_ticks <- identical(supplied[["showticklabels"]], quote(F)) ||
      identical(supplied[["showticklabels"]], FALSE)
    if (!hides_ticks) next
    title <- supplied[["title"]]
    if (is.call(title) && "standoff" %in% names(title)) {
      offenders <- c(offenders, deparse(title, width.cutoff = 500L)[1])
    }
  }

  expect_identical(offenders, character())
})

test_that("report text and plots share one sans-serif font stack", {
  source_lines <- readLines(engine_path())
  definition <- grep("^report_font <- ", source_lines, value = TRUE)

  expect_length(definition, 1L)
  expect_match(definition, "sans-serif")
  # page text, plotly grids, and plotly tables must all pick up the stack
  expect_true(any(grepl("body{font-family:", source_lines, fixed = TRUE)))
  expect_true(any(grepl("layout$font$family <- report_font", source_lines, fixed = TRUE)))
  expect_true(any(grepl("font = list(family = report_font)", source_lines, fixed = TRUE)))
})

test_that("engine passes valid named arguments to package functions", {
  packages <- c(
    "plotly", "data.table", "GenomicRanges", "DNAcopy", "vcfR", "htmltools",
    "kinship2", "scales", "RColorBrewer", "jsonlite", "yaml", "jsonvalidate",
    "base64enc", "tools", "base", "stats", "utils", "graphics", "grDevices"
  )
  for (package in packages) skip_if_not_installed(package)

  locals <- engine_local_functions()
  resolve <- function(name) {
    for (package in packages) {
      if (name %in% getNamespaceExports(package)) {
        return(get(name, envir = asNamespace(package)))
      }
    }
    NULL
  }

  invalid <- character()
  for (expression in engine_calls()) {
    head <- expression[[1]]
    if (!is.name(head)) next
    name <- as.character(head)
    if (name %in% locals) next
    candidate <- resolve(name)
    if (is.null(candidate) || !is.function(candidate)) next
    formal_names <- names(formals(candidate))
    if (!length(formal_names) || "..." %in% formal_names) next
    supplied <- names(expression)
    supplied <- supplied[!is.na(supplied) & nzchar(supplied)]
    unmatched <- supplied[!vapply(
      supplied,
      function(argument) any(startsWith(formal_names, argument)),
      logical(1)
    )]
    if (length(unmatched)) {
      invalid <- c(invalid, paste0(name, "(", unmatched, " = )"))
    }
  }

  expect_identical(unique(invalid), character())
})

test_that("engine reads DNAcopy segment output under its real column names", {
  skip_if_not_installed("DNAcopy")
  set.seed(42)
  copy_number <- DNAcopy::CNA(
    rnorm(200),
    rep("chr1", 200),
    seq_len(200) * 100L,
    data.type = "logratio",
    sampleid = "X"
  )
  capture.output(segmented <- DNAcopy::segment(copy_number, verbose = 0))

  expect_true(
    all(c("chrom", "loc.start", "loc.end", "seg.mean") %in% names(segmented$output))
  )

  source_lines <- readLines(engine_path())
  expect_true(any(grepl("dat_seg\\$loc\\.start", source_lines)))
  expect_false(any(grepl("dat_seg\\$(loc_start|loc_end|seg_mean)", source_lines)))
})

test_that("cli rejects unknown log levels", {
  expect_equal(hopla_cli_status("-L"), 2L)
  expect_equal(hopla_cli_status("-L", "nope"), 2L)
  expect_equal(hopla_cli_status("-L", "debug", "-h"), 0L)
})
