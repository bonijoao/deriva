#' Advance a fitted drift detector over a new batch
#'
#' Feeds a new batch of observations (any size, including 1 — stream mode)
#' to the detector and returns a NEW fitted object with the engine state
#' advanced and the annotated batch appended to the history. The original
#' object is not modified. This is the only way to persist state; see
#' [augment()] for a read-only preview.
#'
#' Why not `update()`: in the tidymodels ecosystem `update()` on a spec
#' means "change hyperparameters", so deriva defines its own verb.
#'
#' @param object A `drift_detector_fit`.
#' @param ... Passed to methods.
#' @return A new `drift_detector_fit`.
#' @export
advance <- function(object, ...) {
  UseMethod("advance")
}

#' @param new_data A data frame with the new batch, in temporal order,
#'   containing the same signal column used in [fit()].
#' @rdname advance
#' @export
#' @examples
#' base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
#' f0 <- fit(drift_detector("ddm"), base, signal = error)
#' f1 <- advance(f0, sim_drift_stream(n_pre = 0, n_post = 50, seed = 2))
advance.drift_detector_fit <- function(object, new_data, ...) {
  x <- validate_signal(new_data, object$signal_col, object$spec)
  m <- drift_method(object$spec$method)
  out <- run_engine(m, object$state, x)
  batch <- annotate(new_data, out$signals, phase = "stream")
  new_drift_detector_fit(
    spec = object$spec,
    state = out$state,
    signal_col = object$signal_col,
    history = vctrs::vec_rbind(object$history, batch)
  )
}
