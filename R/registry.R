# Internal method registry (design section 4). Not exported in v1:
# third-party extension is deliberately deferred (design section 10b).
the <- new.env(parent = emptyenv())
the$methods <- list()

register_drift_method <- function(name, init, step, signal_type, params, meta) {
  stopifnot(is.character(name), length(name) == 1)
  stopifnot(is.function(init), is.function(step))
  if (!signal_type %in% c("error", "distribution")) {
    cli::cli_abort("{.arg signal_type} must be \"error\" or \"distribution\", not {.val {signal_type}}.")
  }
  the$methods[[name]] <- list(
    name = name, init = init, step = step,
    signal_type = signal_type, params = params, meta = meta
  )
  invisible(name)
}

drift_method <- function(name, call = rlang::caller_env()) {
  m <- the$methods[[name]]
  if (is.null(m)) {
    cli::cli_abort(
      c("Unknown drift detection method {.val {name}}.",
        "i" = "Available methods: {.val {names(the$methods)}}."),
      call = call
    )
  }
  m
}
