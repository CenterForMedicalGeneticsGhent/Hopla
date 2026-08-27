hopla_log_rank <- c(
  error = 1L,
  warn = 2L,
  info = 3L,
  debug = 4L
)

.hopla_log_state <- new.env(parent = emptyenv())
.hopla_log_state$level <- "info"

hopla_normalize_log_level <- function(level) {
  stopifnot(is.character(level), length(level) == 1L, nzchar(level))
  normalized <- tolower(level)
  if (identical(normalized, "warning")) {
    normalized <- "warn"
  }
  if (identical(normalized, "quiet")) {
    normalized <- "error"
  }
  if (!normalized %in% names(hopla_log_rank)) {
    stop(
      "log level must be error, warn, info, or debug; got: ",
      level,
      call. = FALSE
    )
  }
  normalized
}

#' Get or set the Hopla log level
#'
#' Levels are `error`, `warn`, `info`, and `debug`. `warning` is accepted as
#' an alias of `warn`, and `quiet` as an alias of `error`.
#'
#' @param level Optional level name. When omitted, the current level is
#'   returned.
#' @return The active log level, invisibly when `level` is set.
#' @export
hopla_log_level <- function(level = NULL) {
  if (is.null(level)) {
    return(.hopla_log_state$level)
  }
  .hopla_log_state$level <- hopla_normalize_log_level(level)
  invisible(.hopla_log_state$level)
}

hopla_log <- function(level, ..., sep = "") {
  level <- hopla_normalize_log_level(level)
  if (hopla_log_rank[[level]] > hopla_log_rank[[.hopla_log_state$level]]) {
    return(invisible(NULL))
  }
  dest <- if (level %in% c("error", "warn")) stderr() else stdout()
  cat(
    format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    " ",
    toupper(level),
    " ",
    ...,
    "\n",
    file = dest,
    sep = sep
  )
  invisible(NULL)
}

hopla_fail <- function(..., status = 1L) {
  hopla_log("error", ...)
  quit(status = status)
}

hopla_with_debug_warnings <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      hopla_log("debug", conditionMessage(w))
      tryInvokeRestart("muffleWarning")
    }
  )
}

hopla_init_log_level <- function(level = NULL) {
  if (is.null(level) || !nzchar(level)) {
    level <- Sys.getenv("HOPLA_LOG_LEVEL", "info")
  }
  hopla_log_level(level)
}
