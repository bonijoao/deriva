#' Detect drift in a signal column (one-shot shortcut)
#'
#' Layer-3 convenience: runs a detector over an existing signal column and
#' returns the data annotated with `.warning` / `.drift`. For an explicit
#' baseline and persistent state, use the full object path:
#' [drift_detector()] + [fit()] + [advance()].
#'
#' For `"ddm"`, the warm-up is governed by `min_instances`: the first
#' `min_instances - 1` observations get `NA` flags.
#'
#' @param data A data frame in temporal order.
#' @param .col Unquoted name of the signal column.
#' @param method Name of a registered method (default `"ddm"`).
#' @param ... Hyperparameters forwarded to [drift_detector()].
#'
#' @return `data` as a tibble with `.warning` and `.drift` columns added.
#' @export
#' @examples
#' s <- sim_drift_stream(seed = 42)
#' detect_drift(s, .col = error, method = "ddm")
detect_drift <- function(data, .col, method = "ddm", ...) {
  spec <- drift_detector(method, ...)
  col <- rlang::as_name(rlang::ensym(.col))
  x <- validate_signal(data, col, spec)
  m <- drift_method(method)
  out <- run_engine(m, m$init(spec$params), x)
  annotate(data, out$signals)
}
