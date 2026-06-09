#' Specify a drift detector
#'
#' Creates an inert detector specification (analogous to a parsnip model
#' spec). Nothing is computed until [fit()] is called on a baseline period.
#'
#' @param method Name of a registered detection method, e.g. `"ddm"`.
#' @param ... Method hyperparameters overriding the defaults (e.g.
#'   `min_instances = 50` for `"ddm"`). Unknown parameters error.
#'
#' @return A `drift_detector` specification object.
#' @export
#' @examples
#' drift_detector("ddm", min_instances = 50)
drift_detector <- function(method = "ddm", ...) {
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
  params[names(user)] <- user
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
