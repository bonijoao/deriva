# DDM — Drift Detection Method (Gama et al. 2004, SBIA).
# Implemented from the paper / curated pseudocode; validated against the
# OUTPUT of datadriftR (GPL) via the golden fixture. Code is original (MIT).

ddm_init <- function(params) {
  list(
    params = params,
    sample_count = 1,
    miss_prob = 1,
    miss_std = 0,
    miss_prob_min = Inf,
    miss_sd_min = Inf,
    miss_prob_sd_min = Inf,
    change_detected = FALSE
  )
}

ddm_step <- function(state, obs) {
  if (state$change_detected) {
    state <- ddm_init(state$params)
  }

  p <- state$miss_prob + (obs - state$miss_prob) / state$sample_count
  s <- sqrt(p * (1 - p) / state$sample_count)
  state$miss_prob <- p
  state$miss_std <- s
  state$sample_count <- state$sample_count + 1

  if (state$sample_count < state$params$min_instances) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }

  if (p + s <= state$miss_prob_sd_min) {
    state$miss_prob_min <- p
    state$miss_sd_min <- s
    state$miss_prob_sd_min <- p + s
  }

  drift <- p + s > state$miss_prob_min +
    state$params$out_control_level * state$miss_sd_min
  warning <- !drift && p + s > state$miss_prob_min +
    state$params$warning_level * state$miss_sd_min

  state$change_detected <- drift
  list(state = state, signal = list(warning = warning, drift = drift))
}
