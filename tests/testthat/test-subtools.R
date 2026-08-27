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
  expect_true(all(c("vcf_file", "sample_ids") %in% schema$required))
  expect_false(any(grepl("\\.", unlist(schema$required))))
})

legacy_fixture <- function(path, extra = character()) {
  writeLines(c(
    "vcf.file=/data/family.vcf.gz",
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

  expect_identical(converted$vcf_file, "/data/family.vcf.gz")
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
  writeLines(c("vcf.file=/data/family.vcf.gz", "sample.ids=child", "unknown.arg=1"), unknown)
  writeLines("vcf.file=/data/family.vcf.gz", missing)

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
  expect_match(paste(readLines(output), collapse = "\n"), "vcf_file:")
})
