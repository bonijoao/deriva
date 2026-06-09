# Generic sequential engine (design section 3, layer 1). The ONLY loop in the
# package: every detector is a pure step() folded here. The imperative style
# is intentional and contained.
run_engine <- function(method, state, signal) {
  n <- length(signal)
  warning <- rep(NA, n)
  drift <- rep(NA, n)
  for (i in seq_len(n)) {
    res <- method$step(state, signal[[i]])
    state <- res$state
    warning[[i]] <- res$signal$warning
    drift[[i]] <- res$signal$drift
  }
  list(
    state = state,
    signals = tibble::tibble(
      .warning = as.logical(warning),
      .drift = as.logical(drift)
    )
  )
}
