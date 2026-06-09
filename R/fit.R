#' @importFrom generics fit
#' @export
generics::fit

new_drift_detector_fit <- function(spec, state, signal_col, history) {
  structure(
    list(spec = spec, state = state, signal_col = signal_col, history = history),
    class = "drift_detector_fit"
  )
}

#' Fit a drift detector on a baseline period
#'
#' Runs the detector over the baseline data — the period where the monitored
#' model is considered stable — so it learns the reference ("normal") level.
#' The returned object is immutable: feed new batches with [advance()].
#'
#' @param object A [drift_detector()] specification.
#' @param data A data frame with the baseline period, in temporal order.
#' @param signal Unquoted name of the signal column (0/1 errors for
#'   error-based methods such as `"ddm"`).
#' @param ... Not used.
#'
#' @return A `drift_detector_fit` object.
#' @export
#' @examples
#' base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
#' fit(drift_detector("ddm"), base, signal = error)
fit.drift_detector <- function(object, data, signal, ...) {
  col <- rlang::as_name(rlang::ensym(signal))
  x <- validate_signal(data, col, object)
  m <- drift_method(object$method)
  out <- run_engine(m, m$init(object$params), x)
  new_drift_detector_fit(
    spec = object,
    state = out$state,
    signal_col = col,
    history = annotate(data, out$signals, phase = "baseline")
  )
}

#' @export
print.drift_detector_fit <- function(x, ...) {
  h <- x$history
  cat("Fitted Drift Detector (", x$spec$method, ")\n", sep = "")
  cat("  observations: ", nrow(h),
      " (", sum(h$.phase == "baseline"), " baseline)\n", sep = "")
  cat("  warnings: ", sum(h$.warning, na.rm = TRUE),
      " | drifts: ", sum(h$.drift, na.rm = TRUE), "\n", sep = "")
  invisible(x)
}
