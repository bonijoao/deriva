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
  if (m$signal_type == "distribution") {
    if (!is.numeric(x)) {
      cli::cli_abort(
        c("Method {.val {spec$method}} expects a numeric signal.",
          "x" = "Column {.val {col}} is {.cls {class(x)}}."),
        call = call
      )
    }
  }
  as.numeric(x)
}

check_reserved_columns <- function(data, reserved, call = rlang::caller_env()) {
  clash <- intersect(names(data), reserved)
  if (length(clash) == 0) return(invisible(data))
  cli::cli_abort(
    c("The data already has {cli::qty(length(clash))}column{?s} {.val {clash}}, which deriva would overwrite.",
      "i" = "Rename or drop {cli::qty(length(clash))}{?it/them} first."),
    class = "deriva_error_reserved_column", call = call
  )
}

check_batch_columns <- function(history, new_data, call = rlang::caller_env()) {
  expected <- setdiff(names(history), c(".warning", ".drift", ".phase"))
  missing <- setdiff(expected, names(new_data))
  extra <- setdiff(names(new_data), expected)
  if (length(missing) + length(extra) == 0) return(invisible(new_data))
  cli::cli_abort(
    c("{.arg new_data} must have the same columns as the data given to {.fn fit}.",
      if (length(missing) > 0) c("x" = "Missing: {.val {missing}}."),
      if (length(extra) > 0) c("x" = "Unexpected: {.val {extra}}.")),
    class = "deriva_error_batch_columns", call = call
  )
}

annotate <- function(data, signals, phase = NULL) {
  out <- tibble::as_tibble(data)
  out$.warning <- signals$.warning
  out$.drift <- signals$.drift
  if (!is.null(phase)) out$.phase <- phase
  out
}
