#' Simulate a binary error stream with a known drift point
#'
#' Generates a stream of 0/1 classifier errors whose error rate jumps from
#' `p_pre` to `p_post` after `n_pre` observations. Useful for testing and
#' validating drift detectors against a known ground truth.
#'
#' @param n_pre,n_post Number of observations before / after the drift point.
#' @param p_pre,p_post Error probability before / after the drift point.
#' @param seed Optional integer; if supplied, `set.seed()` is called for
#'   reproducibility.
#'
#' @return A tibble with columns `t` (index), `error` (0/1) and
#'   `drift_true` (logical ground truth: `TRUE` after the drift point).
#' @export
#' @examples
#' sim_drift_stream(n_pre = 100, n_post = 100, seed = 42)
sim_drift_stream <- function(n_pre = 500, n_post = 500,
                             p_pre = 0.05, p_post = 0.30, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  tibble::tibble(
    t = seq_len(n_pre + n_post),
    error = c(stats::rbinom(n_pre, 1, p_pre), stats::rbinom(n_post, 1, p_post)),
    drift_true = c(rep(FALSE, n_pre), rep(TRUE, n_post))
  )
}
