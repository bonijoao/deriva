#' @importFrom generics fit
#' @export
generics::fit

new_drift_detector_fit <- function(spec, state, signal_col, history, counts,
                                   drifts, rng = NULL) {
  structure(
    list(spec = spec, state = state, signal_col = signal_col, history = history,
         counts = counts, drifts = drifts, rng = rng),
    class = "drift_detector_fit"
  )
}

empty_tallies <- function() {
  list(
    counts = list(n_obs = 0L, n_baseline = 0L, n_warning = 0L),
    drifts = tibble::tibble(index = integer(), phase = character())
  )
}

# Totals live outside `history` so they stay exact when it is truncated.
update_tallies <- function(counts, drifts, signals, phase) {
  n <- nrow(signals)
  hit <- which(!is.na(signals$.drift) & signals$.drift)
  list(
    counts = list(
      n_obs = counts$n_obs + n,
      n_baseline = counts$n_baseline + if (phase == "baseline") n else 0L,
      n_warning = counts$n_warning + sum(signals$.warning, na.rm = TRUE)
    ),
    drifts = vctrs::vec_rbind(
      drifts,
      tibble::tibble(index = counts$n_obs + hit, phase = rep(phase, length(hit)))
    )
  )
}

trim_history <- function(history, keep) {
  n <- nrow(history)
  if (n <= keep) return(history)
  vctrs::vec_slice(history, seq.int(n - keep + 1, length.out = keep))
}

check_fit_version <- function(object, call = rlang::caller_env()) {
  if (is.null(object$counts)) {
    cli::cli_abort(
      c("This fitted detector was created by deriva 0.1.0 and lacks running totals.",
        "i" = "Refit it with {.fn fit}."),
      call = call
    )
  }
  invisible(object)
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
  if (is.null(object$keep)) {
    cli::cli_abort(
      c("This detector specification was created by deriva 0.1.0 and lacks {.arg keep}.",
        "i" = "Recreate it with {.fn drift_detector}.")
    )
  }
  check_reserved_columns(data, c(".warning", ".drift", ".phase"))
  col <- rlang::as_name(rlang::ensym(signal))
  x <- validate_signal(data, col, object)
  m <- drift_method(object$method)
  out <- run_engine_rng(m, m$init(object$params), x, seed_to_rng(object$seed))
  empty <- empty_tallies()
  tallies <- update_tallies(empty$counts, empty$drifts, out$signals, "baseline")
  new_drift_detector_fit(
    spec = object,
    state = out$state,
    signal_col = col,
    history = trim_history(annotate(data, out$signals, phase = "baseline"), object$keep),
    counts = tallies$counts,
    drifts = tallies$drifts,
    rng = out$rng
  )
}

#' @export
print.drift_detector_fit <- function(x, ...) {
  check_fit_version(x)
  cat("Fitted Drift Detector (", x$spec$method, ")\n", sep = "")
  cat("  observations: ", x$counts$n_obs,
      " (", x$counts$n_baseline, " baseline)\n", sep = "")
  cat("  warnings: ", x$counts$n_warning,
      " | drifts: ", nrow(x$drifts), "\n", sep = "")
  if (nrow(x$history) < x$counts$n_obs) {
    cat("  history: last ", nrow(x$history), " rows kept\n", sep = "")
  }
  invisible(x)
}
