#' Run a Hopla analysis
#'
#' Runs the analysis engine in a clean R process after validating the supplied
#' YAML or JSON settings file.
#'
#' @param settings Path to a `.yaml`, `.yml`, or `.json` settings file.
#' @param engine Optional path to the Hopla engine. Intended for development and
#'   testing; installed packages locate it automatically.
#' @return The engine process exit status, invisibly.
#' @export
hopla_run <- function(settings, engine = NULL) {
  stopifnot(is.character(settings), length(settings) == 1L)

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
    c(shQuote(normalizePath(engine)), shQuote(settings))
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

  first[, input.order := .I]
  flows <- merge(
    first[, .(
      chr, pos, input.order,
      flowA.1 = flowA.hexcol, flowB.1 = flowB.hexcol
    )],
    second[, .(
      chr, pos,
      flowA.2 = flowA.hexcol, flowB.2 = flowB.hexcol
    )],
    by = c("chr", "pos"),
    sort = FALSE
  )
  data.table::setorder(flows, input.order)
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
    `1 vs 1` = concordance(flows$flowA.1, flows$flowA.2),
    `1 vs 2` = concordance(flows$flowA.1, flows$flowB.2),
    `2 vs 1` = concordance(flows$flowB.1, flows$flowA.2),
    `2 vs 2` = concordance(flows$flowB.1, flows$flowB.2)
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

  second.rows <- second[first, on = .(chr, pos), which = TRUE]
  matched <- !is.na(second.rows)
  first <- first[matched]
  second <- second[second.rows[matched]]
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
