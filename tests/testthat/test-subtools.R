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
  installed <- system.file("exec", "hopla", package = "hopla")
  if (nzchar(installed)) {
    return(installed)
  }
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
  stop("Could not locate hopla CLI.", call. = FALSE)
}

schema_path <- function() {
  installed <- system.file("schema", "hopla.schema.json", package = "hopla")
  if (nzchar(installed)) {
    return(installed)
  }
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
