# KSWIN - Kolmogorov-Smirnov Windowing (Raab et al. 2020).
# Implemented from the paper / curated pseudocode; validated against the
# OUTPUT of datadriftR (GPL) via the golden fixture. Code is original (MIT).
# Stochastic: step() draws random sub-windows with sample(); set a seed for
# reproducibility. No warning level -> signal$warning is always NA.

kswin_init <- function(params) {
  if (params$window_size <= params$stat_size) {
    cli::cli_abort(
      "{.arg window_size} ({params$window_size}) must be greater than {.arg stat_size} ({params$stat_size})."
    )
  }
  list(params = params, window = numeric(0))
}

kswin_step <- function(state, obs) {
  p <- state$params
  drift <- FALSE
  if (length(state$window) >= p$window_size) {
    state$window <- state$window[-1]
    rnd_indices <- sample(seq_len(length(state$window) - p$stat_size),
                          p$stat_size, replace = TRUE)
    rnd_window <- state$window[rnd_indices]
    last_window <- utils::tail(state$window, p$stat_size)
    tr <- suppressWarnings(stats::ks.test(rnd_window, last_window))
    if (tr$p.value <= p$alpha && tr$statistic > 0.1) {
      drift <- TRUE
      state$window <- utils::tail(state$window, p$stat_size)
    }
  }
  state$window <- c(state$window, obs)
  list(state = state, signal = list(warning = NA, drift = drift))
}
