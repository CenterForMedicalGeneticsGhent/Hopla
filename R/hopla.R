require_existing_run_paths <- function(vcf_file, out_dir) {
  if (!file.exists(vcf_file) || dir.exists(vcf_file)) {
    stop("VCF file does not exist: ", vcf_file, call. = FALSE)
  }
  if (!dir.exists(out_dir)) {
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  }
  invisible(TRUE)
}

#' Run a Hopla analysis
#'
#' Runs the analysis engine in a clean R process after validating the supplied
#' YAML or JSON settings file.
#'
#' @param settings Path to a `.yaml`, `.yml`, or `.json` settings file.
#' @param vcf_file Path to a (multisample) `vcf.gz` file. Must exist.
#' @param out_dir Output directory. Defaults to the current working directory
#'   and must already exist.
#' @param engine Optional path to the Hopla engine. Intended for development and
#'   testing; installed packages locate it automatically.
#' @return The engine process exit status, invisibly.
#' @export
hopla_run <- function(settings, vcf_file, out_dir = getwd(), engine = NULL) {
  stopifnot(
    is.character(settings), length(settings) == 1L,
    is.character(vcf_file), length(vcf_file) == 1L,
    is.character(out_dir), length(out_dir) == 1L
  )
  require_existing_run_paths(vcf_file, out_dir)

  if (is.null(engine)) {
    engine <- system.file("exec", "hopla-run.R", package = "hopla")
    if (!nzchar(engine)) {
      candidate <- file.path("exec", "hopla-run.R")
      if (file.exists(candidate)) engine <- candidate
    }
  }
  if (!length(engine) || !file.exists(engine)) {
    stop("Could not locate the Hopla analysis engine.", call. = FALSE)
  }

  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      shQuote(normalizePath(engine)),
      shQuote(normalizePath(settings, mustWork = FALSE)),
      shQuote(normalizePath(vcf_file)),
      shQuote(normalizePath(out_dir))
    )
  )
  invisible(status)
}

#' Compare haplotype flow tables
#'
#' @param flow1,flow2 Paths to Hopla flow tables.
#' @param relative Compare each flow relative to its first retained marker.
#' @return A named numeric vector containing four concordance percentages.
#' @export
hopla_concordance <- function(flow1, flow2, relative = FALSE) {
  stopifnot(
    is.character(flow1), length(flow1) == 1L,
    is.character(flow2), length(flow2) == 1L,
    is.logical(relative), length(relative) == 1L
  )

  first <- data.table::fread(flow1)
  second <- data.table::fread(flow2)
  required <- c("chr", "pos", "flowA.hexcol", "flowB.hexcol")
  if (!all(required %in% names(first)) || !all(required %in% names(second))) {
    stop("Flow tables must contain chr, pos, flowA.hexcol, and flowB.hexcol.", call. = FALSE)
  }

  first[, input_order := .I]
  flows <- merge(
    first[, .(
      chr, pos, input_order,
      flow_a_1 = flowA.hexcol, flow_b_1 = flowB.hexcol
    )],
    second[, .(
      chr, pos,
      flow_a_2 = flowA.hexcol, flow_b_2 = flowB.hexcol
    )],
    by = c("chr", "pos"),
    sort = FALSE
  )
  data.table::setorder(flows, input_order)
  if (!nrow(flows)) stop("Flow tables have no shared markers.", call. = FALSE)

  concordance <- function(x, y) {
    keep <- x != "X" & y != "X"
    x <- x[keep]
    y <- y[keep]
    if (!length(x)) return(NA_real_)
    if (relative) {
      x <- x == x[1]
      y <- y == y[1]
    }
    round(mean(x == y) * 100, 2)
  }

  c(
    `1 vs 1` = concordance(flows$flow_a_1, flows$flow_a_2),
    `1 vs 2` = concordance(flows$flow_a_1, flows$flow_b_2),
    `2 vs 1` = concordance(flows$flow_b_1, flows$flow_a_2),
    `2 vs 2` = concordance(flows$flow_b_1, flows$flow_b_2)
  )
}

#' Transform a haplotype flow table relative to another
#'
#' @param flow1,flow2 Paths to Hopla flow tables.
#' @param mode Either `1` for matching strands or `2` for crossed strands.
#' @param output Optional output path. Defaults to `<flow1>-relative.txt`.
#' @return The output path, invisibly.
#' @export
hopla_transform <- function(flow1, flow2, mode, output = NULL) {
  stopifnot(
    is.character(flow1), length(flow1) == 1L,
    is.character(flow2), length(flow2) == 1L
  )
  mode <- as.integer(mode)
  if (is.na(mode) || !(mode %in% c(1L, 2L))) {
    stop("mode must be 1 (matching) or 2 (crossed).", call. = FALSE)
  }

  first <- data.table::fread(flow1)
  second <- data.table::fread(flow2)
  required <- c("chr", "pos", "flowA.hexcol", "flowB.hexcol")
  if (!all(required %in% names(first)) || !all(required %in% names(second))) {
    stop("Flow tables must contain chr, pos, flowA.hexcol, and flowB.hexcol.", call. = FALSE)
  }

  second_rows <- second[first, on = .(chr, pos), which = TRUE]
  matched <- !is.na(second_rows)
  first <- first[matched]
  second <- second[second_rows[matched]]
  if (!nrow(first)) stop("Flow tables have no shared markers.", call. = FALSE)

  if (mode == 1L) {
    first[, flowA.hexcol := flowA.hexcol == second$flowA.hexcol]
    first[, flowB.hexcol := flowB.hexcol == second$flowB.hexcol]
  } else {
    first[, flowA.hexcol := flowA.hexcol == second$flowB.hexcol]
    first[, flowB.hexcol := flowB.hexcol == second$flowA.hexcol]
  }

  if (is.null(output)) {
    output <- paste0(tools::file_path_sans_ext(flow1), "-relative.txt")
  }
  data.table::fwrite(first, output, quote = FALSE, sep = "\t")
  invisible(output)
}

hopla_schema_file <- function() {
  installed <- system.file("schema", "hopla.schema.json", package = "hopla")
  if (nzchar(installed) && file.exists(installed)) {
    return(normalizePath(installed))
  }

  candidates <- c(
    file.path("inst", "schema", "hopla.schema.json"),
    file.path("..", "inst", "schema", "hopla.schema.json"),
    file.path("..", "..", "inst", "schema", "hopla.schema.json")
  )
  for (candidate in candidates) {
    if (file.exists(candidate)) {
      return(normalizePath(candidate))
    }
  }
  stop("Could not locate hopla.schema.json.", call. = FALSE)
}

legacy_key_to_schema <- function(key) {
  tolower(gsub(".", "_", key, fixed = TRUE))
}

parse_legacy_settings_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  raw <- list()
  at_info <- FALSE

  for (line in lines) {
    if (!at_info) {
      line <- gsub("'", "", gsub("\"", "", line), fixed = TRUE)
    } else {
      line <- gsub("\t", "    ", line, fixed = TRUE)
    }

    trimmed <- trimws(line)
    if (identical(trimmed, "end.info")) {
      if (!at_info) {
        stop("Legacy settings file has end.info without start.info.", call. = FALSE)
      }
      at_info <- FALSE
      next
    }
    if (at_info) {
      raw$info <- c(raw$info, line)
      next
    }
    if (identical(trimmed, "start.info")) {
      at_info <- TRUE
      next
    }
    if (!nzchar(trimmed) || startsWith(trimmed, "#")) {
      next
    }

    line <- trimws(strsplit(trimmed, "#", fixed = TRUE)[[1]][1])
    if (!grepl("=", line, fixed = TRUE)) {
      stop("Legacy settings line is not key=value: ", line, call. = FALSE)
    }
    if (endsWith(line, "=")) {
      next
    }

    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    key <- trimws(parts[[1]])
    value <- trimws(paste(parts[-1], collapse = "="))
    raw[[legacy_key_to_schema(key)]] <- value
  }

  if (at_info) {
    stop("Legacy settings file is missing end.info.", call. = FALSE)
  }
  raw
}

split_legacy_tokens <- function(value) {
  trimws(strsplit(value, ",", fixed = TRUE)[[1]])
}

is_legacy_null_token <- function(token) {
  !nzchar(token) || identical(token, "NA")
}

coerce_legacy_value <- function(key, value, spec) {
  types <- spec$type
  if (is.null(types)) {
    types <- character()
  }

  if ("array" %in% types) {
    tokens <- split_legacy_tokens(value)
    item_types <- spec$items$type
    item_enum <- spec$items$enum
    allows_null <- FALSE
    if (!is.null(item_types) && "null" %in% unlist(item_types, use.names = FALSE)) {
      allows_null <- TRUE
    }
    if (!is.null(item_enum) && any(vapply(item_enum, is.null, logical(1)))) {
      allows_null <- TRUE
    }

    return(lapply(tokens, function(token) {
      if (is_legacy_null_token(token)) {
        if (!allows_null) {
          stop("NA is not allowed in ", key, ".", call. = FALSE)
        }
        return(NULL)
      }
      token
    }))
  }

  if ("boolean" %in% types) {
    parsed <- as.logical(value)
    if (length(parsed) != 1L || is.na(parsed)) {
      stop("Could not parse boolean setting ", key, ": ", value, call. = FALSE)
    }
    return(parsed)
  }

  if ("number" %in% types) {
    parsed <- suppressWarnings(as.numeric(value))
    if (length(parsed) != 1L || is.na(parsed)) {
      stop("Could not parse numeric setting ", key, ": ", value, call. = FALSE)
    }
    return(parsed)
  }

  value
}

validate_settings_object <- function(settings, schema_file) {
  json <- jsonlite::toJSON(settings, auto_unbox = TRUE, null = "null", na = "null")
  valid <- jsonvalidate::json_validate(json, schema_file, verbose = TRUE)
  if (!isTRUE(valid)) {
    errors <- attr(valid, "errors")
    detail <- paste(utils::capture.output(print(errors)), collapse = "\n")
    stop("Converted settings failed schema validation:\n", detail, call. = FALSE)
  }
  invisible(TRUE)
}

yaml_handlers <- function() {
  list(
    logical = function(x) {
      structure(if (isTRUE(x)) "true" else "false", class = "verbatim")
    },
    `NULL` = function(x) {
      structure("null", class = "verbatim")
    }
  )
}

#' Convert a legacy Hopla settings file to validated YAML
#'
#' Reads the historical `key=value` settings format, maps dotted keys to the
#' current snake_case schema, omits unset values, and writes YAML after JSON
#' Schema validation.
#'
#' @param legacy Path to a legacy settings file.
#' @param output Optional YAML output path. Defaults to the input path with a
#'   `.yaml` extension.
#' @param schema Optional path to `hopla.schema.json`. Located automatically
#'   when omitted.
#' @return The output path, invisibly.
#' @export
hopla_convert_settings <- function(legacy, output = NULL, schema = NULL) {
  stopifnot(is.character(legacy), length(legacy) == 1L)
  if (!file.exists(legacy)) {
    stop("Legacy settings file does not exist: ", legacy, call. = FALSE)
  }
  if (is.null(schema)) {
    schema <- hopla_schema_file()
  }
  if (!file.exists(schema)) {
    stop("Settings schema does not exist: ", schema, call. = FALSE)
  }
  if (is.null(output)) {
    output <- paste0(tools::file_path_sans_ext(legacy), ".yaml")
  }
  stopifnot(is.character(output), length(output) == 1L)

  schema_doc <- jsonlite::fromJSON(schema, simplifyVector = FALSE)
  properties <- schema_doc$properties
  raw <- parse_legacy_settings_file(legacy)
  cli_only <- intersect(names(raw), c("vcf_file", "out_dir"))
  if (length(cli_only)) {
    message(
      "Note: ", paste(cli_only, collapse = ", "),
      " belong on the CLI and were omitted from the YAML."
    )
    raw[cli_only] <- NULL
  }

  unknown <- setdiff(names(raw), names(properties))
  if (length(unknown)) {
    stop("Unknown legacy setting(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  }

  settings <- list()
  for (key in names(raw)) {
    if (identical(key, "info")) {
      settings$info <- as.list(raw$info)
      next
    }
    settings[[key]] <- coerce_legacy_value(key, raw[[key]], properties[[key]])
  }

  validate_settings_object(settings, schema)

  ordered <- list()
  for (key in names(properties)) {
    if (key %in% names(settings)) {
      ordered[[key]] <- settings[[key]]
    }
  }

  text <- yaml::as.yaml(
    ordered,
    indent = 2,
    indent.mapping.sequence = TRUE,
    handlers = yaml_handlers()
  )
  writeLines(text, output, sep = "")
  invisible(output)
}
