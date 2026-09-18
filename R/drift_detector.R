#' Specify a drift detector
#'
#' Creates an inert detector specification (analogous to a parsnip model
#' spec). Nothing is computed until [fit()] is called on a baseline period.
#'
#' @param method Name of a registered detection method, e.g. `"ddm"`.
#' @param ... Method hyperparameters overriding the defaults (e.g.
#'   `min_instances = 50` for `"ddm"`). Unknown parameters and values
#'   outside a parameter's valid range error.
#' @param seed `NULL` (default) or a single whole number. When set, the
#'   detector draws from its own private random stream, carried inside the
#'   fitted object: results are reproducible, do not depend on how the stream
#'   is split into batches, and the session's global RNG is left untouched.
#'   Only `"kswin"` and `"seqdrift2"` are stochastic. With `NULL` they draw
#'   from the global RNG, so call [set.seed()] yourself for reproducibility.
#' @param keep Number of most recent annotated rows retained in the fitted
#'   object's history (default `10000`), bounding memory and the cost of each
#'   [advance()] on long-running streams. Totals in [glance()] and drift points
#'   in [tidy()] are tracked separately and stay exact whatever `keep` is.
#'   `Inf` keeps everything and `0` keeps nothing; both warn.
#'
#' @return A `drift_detector` specification object.
#' @export
#' @examples
#' drift_detector("ddm", min_instances = 50)
drift_detector <- function(method = "ddm", ..., seed = NULL, keep = 10000) {
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
  check_seed(seed)
  check_keep(keep)
  structure(
    list(method = method, params = params, seed = seed, keep = keep),
    class = "drift_detector"
  )
}

check_seed <- function(seed, call = rlang::caller_env()) {
  if (is.null(seed)) return(invisible(NULL))
  ok <- is.numeric(seed) && length(seed) == 1 && !is.na(seed) &&
    seed == trunc(seed) && abs(seed) <= .Machine$integer.max
  if (!ok) abort_param("seed", "NULL or a single whole number", seed, call)
  invisible(seed)
}

# Warns here, at spec creation, so advance() stays silent in a streaming loop.
check_keep <- function(keep, call = rlang::caller_env()) {
  ok <- is.numeric(keep) && length(keep) == 1 && !is.na(keep) && keep >= 0 &&
    (is.infinite(keep) || keep == trunc(keep))
  if (!ok) abort_param("keep", "a whole number >= 0, or Inf", keep, call)
  if (is.infinite(keep)) {
    cli::cli_warn(
      c("!" = "{.code keep = Inf} keeps the full history in memory for the life of the object.",
        "i" = "Memory grows with rows and columns: about 184 MB at 1M rows and 1.8 GB at 10M (23-column data).",
        "i" = "For long-running production streams prefer a finite window, e.g. {.code keep = 10000}."),
      class = "deriva_warning_keep_inf"
    )
  } else if (keep == 0) {
    cli::cli_warn(
      c("!" = "{.code keep = 0} disables row-level history.",
        "i" = "{.fn augment} returns no rows and {.fn autoplot} cannot draw.",
        "i" = "Totals and drift points stay exact in {.fn glance} and {.fn tidy}."),
      class = "deriva_warning_keep_zero"
    )
  }
  invisible(keep)
}

#' @export
print.drift_detector <- function(x, ...) {
  # cat, not cli: cli writes to stderr, which breaks expect_output() and
  # surprises users capturing stdout
  cat("Drift Detector Specification (", x$method, ")\n", sep = "")
  for (nm in names(x$params)) {
    cat("  ", nm, ": ", format(x$params[[nm]]), "\n", sep = "")
  }
  cat("  keep: ", format(x$keep), "\n", sep = "")
  if (!is.null(x$seed)) cat("  seed: ", format(x$seed), "\n", sep = "")
  invisible(x)
}
