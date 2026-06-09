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
#' @return A tibble with one row per detected drift: `index` (position in
#'   the history) and `phase`.
#' @export
tidy.drift_detector_fit <- function(x, ...) {
  h <- x$history
  idx <- which(!is.na(h$.drift) & h$.drift)
  tibble::tibble(index = idx, phase = h$.phase[idx])
}

#' One-row summary of a fitted detector
#'
#' @param x A `drift_detector_fit`.
#' @param ... Not used.
#' @return A 1-row tibble: `method`, `n_obs`, `n_warning`, `n_drift`,
#'   `first_drift` (NA if no drift detected).
#' @export
glance.drift_detector_fit <- function(x, ...) {
  h <- x$history
  drifts <- which(!is.na(h$.drift) & h$.drift)
  tibble::tibble(
    method = x$spec$method,
    n_obs = nrow(h),
    n_warning = sum(h$.warning, na.rm = TRUE),
    n_drift = length(drifts),
    first_drift = if (length(drifts) > 0) drifts[[1]] else NA_integer_
  )
}
