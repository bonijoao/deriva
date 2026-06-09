#' @importFrom generics augment
#' @export
generics::augment

#' Annotated observations from a fitted drift detector
#'
#' With `new_data = NULL`, returns the accumulated history (baseline +
#' advanced batches) annotated with `.warning`, `.drift` and `.phase`.
#' With `new_data`, returns a READ-ONLY preview: the batch annotated from
#' the current state, WITHOUT persisting it — use [advance()] to persist.
#'
#' @param x A `drift_detector_fit`.
#' @param new_data Optional data frame with a new batch to preview.
#' @param ... Not used.
#' @return A tibble.
#' @export
#' @examples
#' base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
#' f0 <- fit(drift_detector("ddm"), base, signal = error)
#' augment(f0)
augment.drift_detector_fit <- function(x, new_data = NULL, ...) {
  if (is.null(new_data)) {
    return(x$history)
  }
  sig <- validate_signal(new_data, x$signal_col, x$spec)
  m <- drift_method(x$spec$method)
  out <- run_engine(m, x$state, sig)
  annotate(new_data, out$signals)
}
