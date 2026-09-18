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

seed_to_rng <- function(seed) {
  if (is.null(seed)) return(NULL)
  withr::with_seed(as.integer(seed), get(".Random.seed", envir = globalenv()))
}

# Runs the engine on a private RNG stream, restoring the caller's global RNG afterwards.
run_engine_rng <- function(method, state, signal, rng = NULL) {
  if (is.null(rng)) {
    return(c(run_engine(method, state, signal), list(rng = NULL)))
  }
  # .Random.seed exists only in globalenv; the alias avoids R CMD check's global-assignment NOTE and with_preserve_seed() restores the caller's.
  genv <- globalenv()
  withr::with_preserve_seed({
    assign(".Random.seed", rng, envir = genv)
    out <- run_engine(method, state, signal)
    out$rng <- get(".Random.seed", envir = genv)
    out
  })
}
