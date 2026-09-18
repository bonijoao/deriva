#' Specify a drift detector
#'
#' Creates an inert detector specification (analogous to a parsnip model
#' spec). Nothing is computed until [fit()] is called on a baseline period.
#'
#' @param method Name of a registered detection method, e.g. `"ddm"`.
#' @param ... Method hyperparameters overriding the defaults (e.g.
#'   `min_instances = 50` for `"ddm"`). Unknown parameters and values
#'   outside a parameter's valid range error.
#'
#' @return A `drift_detector` specification object.
#' @export
#' @examples
#' drift_detector("ddm", min_instances = 50)
drift_detector <- function(method = "ddm", ...) {
  if (!(is.character(method) && length(method) == 1 && !is.na(method))) {
    cli::cli_abort(
      c("{.arg method} must be a single string naming a registered method.",
        "i" = "Hyperparameters go in {.arg ...}, e.g. {.code drift_detector(\"ddm\", min_instances = 50)}.")
    )
  }
  m <- drift_method(method)
  user <- rlang::list2(...)
  unknown <- setdiff(names(user), names(m$params))
  if (length(unknown) > 0) {
    cli::cli_abort(
      c("Unknown {cli::qty(length(unknown))}parameter{?s} {.arg {unknown}} for method {.val {method}}.",
        "i" = "Valid parameters: {.arg {names(m$params)}}.")
    )
  }
  params <- m$params
  # `[<-` with list() keeps a NULL value so the checker can reject it
  for (nm in names(user)) params[nm] <- list(user[[nm]])
  validate_params(m, params)
  structure(
    list(method = method, params = params),
    class = "drift_detector"
  )
}

#' @export
print.drift_detector <- function(x, ...) {
  # cat, not cli: cli writes to stderr, which breaks expect_output() and
  # surprises users capturing stdout
  cat("Drift Detector Specification (", x$method, ")\n", sep = "")
  for (nm in names(x$params)) {
    cat("  ", nm, ": ", format(x$params[[nm]]), "\n", sep = "")
  }
  invisible(x)
}
