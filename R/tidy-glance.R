#' @importFrom generics tidy
#' @export
generics::tidy

#' @importFrom generics glance
#' @export
generics::glance

#' Drift points of a fitted detector
#'
#' @param x A `drift_detector_fit`.
#' @param ... Not used.
#' @return A tibble with one row per detected drift: `index` (position since
#'   the start of the baseline, exact even when the history is truncated by
#'   `keep`) and `phase`.
#' @export
tidy.drift_detector_fit <- function(x, ...) {
  check_fit_version(x)
  x$drifts
}

#' One-row summary of a fitted detector
#'
#' @param x A `drift_detector_fit`.
#' @param ... Not used.
#' @return A 1-row tibble: `method`, `n_obs`, `n_warning`, `n_drift`,
#'   `first_drift` (NA if no drift detected).
#' @export
glance.drift_detector_fit <- function(x, ...) {
  check_fit_version(x)
  d <- x$drifts
  tibble::tibble(
    method = x$spec$method,
    n_obs = x$counts$n_obs,
    n_warning = x$counts$n_warning,
    n_drift = nrow(d),
    first_drift = if (nrow(d) > 0) d$index[[1]] else NA_integer_
  )
}
