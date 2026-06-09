# Pulls and validates the signal column for a spec (design section 11).
# NA policy for error-based methods: abort with a clear message.
validate_signal <- function(data, col, spec, call = rlang::caller_env()) {
  if (!col %in% names(data)) {
    cli::cli_abort("Column {.val {col}} not found in the data.", call = call)
  }
  x <- data[[col]]
  if (anyNA(x)) {
    cli::cli_abort(
      c("Column {.val {col}} contains NA values.",
        "i" = "Remove or impute missing values before drift detection."),
      call = call
    )
  }
  m <- drift_method(spec$method)
  if (m$signal_type == "error") {
    if (!(is.numeric(x) || is.logical(x)) || !all(x %in% c(0, 1))) {
      cli::cli_abort(
        c("Method {.val {spec$method}} expects an error signal with values 0/1.",
          "x" = "Column {.val {col}} has other values.",
          "i" = "Use {.fn add_prediction_error} to build the signal from predictions."),
        call = call
      )
    }
  }
  as.numeric(x)
}

annotate <- function(data, signals, phase = NULL) {
  out <- tibble::as_tibble(data)
  out$.warning <- signals$.warning
  out$.drift <- signals$.drift
  if (!is.null(phase)) out$.phase <- phase
  out
}
