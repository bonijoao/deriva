#' Build a drift signal from model predictions
#'
#' Bridge from tidymodels: takes the output of `augment()` on a fitted
#' workflow/model and adds a `.error` column — the signal drift detectors
#' consume. Classification (factor/character truth): 0/1 mismatch against
#' `estimate` (default column `.pred_class`). Regression (numeric truth):
#' absolute error against `estimate` (default column `.pred`).
#'
#' @param data A data frame with truth and prediction columns.
#' @param truth Unquoted name of the true outcome column.
#' @param estimate Unquoted name of the prediction column. Defaults to
#'   `.pred_class` (classification) or `.pred` (regression), following
#'   tidymodels conventions.
#' @param ... Not used.
#'
#' @return `data` as a tibble with a `.error` column added.
#' @export
#' @examples
#' d <- tibble::tibble(truth = c(1, 2, 3), .pred = c(1, 1, 5))
#' add_prediction_error(d, truth = truth)
add_prediction_error <- function(data, truth, estimate = NULL, ...) {
  truth_col <- rlang::as_name(rlang::ensym(truth))
  if (!truth_col %in% names(data)) {
    cli::cli_abort("Column {.val {truth_col}} not found in the data.")
  }
  t_vals <- data[[truth_col]]
  is_class <- is.factor(t_vals) || is.character(t_vals)

  est_quo <- rlang::enquo(estimate)
  est_col <- if (rlang::quo_is_null(est_quo)) {
    if (is_class) ".pred_class" else ".pred"
  } else {
    rlang::as_name(est_quo)
  }
  if (!est_col %in% names(data)) {
    cli::cli_abort(
      c("Column {.val {est_col}} not found in the data.",
        "i" = "Pass {.arg estimate} explicitly if your prediction column has another name.")
    )
  }
  e_vals <- data[[est_col]]

  out <- tibble::as_tibble(data)
  out$.error <- if (is_class) {
    as.integer(as.character(t_vals) != as.character(e_vals))
  } else {
    abs(t_vals - e_vals)
  }
  out
}
