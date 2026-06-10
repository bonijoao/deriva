# FHDDMS - Stacking Fast Hoeffding Drift Detection Method
# (Pesaranghader, Viktor & Paquet 2017, Machine Learning).
# Extends FHDDM with TWO superimposed sliding windows over the same stream: a
# long window (gradual drift, smaller Hoeffding bound) and a short window that
# is the TAIL of the long one (abrupt drift, larger bound) -> a single physical
# buffer. Drift fires when either window's error rate exceeds its historical
# minimum by more than its Hoeffding bound.
# Adapted to deriva's 1=error convention (original tracks max correct prob):
# tracks the historical MIN error rate per window, like deriva's FHDDM.
# Drift-only (no warning, per the paper). No external R oracle (datadriftR has no
# FHDDMS) -> validated against synthetic ground truth.
# Returns FALSE while the long window fills (no min_instances; like FHDDM).
fhddms_init <- function(params) {
  list(params = params, window = numeric(0), n_err = 0,
       p_min_l = Inf, p_min_s = Inf, change_detected = FALSE)
}

fhddms_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- fhddms_init(p)

  # Slide the LONG window (the short window is its tail).
  if (length(state$window) >= p$window_size) {
    state$n_err <- state$n_err - state$window[1]
    state$window <- state$window[-1]
  }
  state$window <- c(state$window, obs)
  state$n_err <- state$n_err + obs

  if (length(state$window) < p$window_size) {
    return(list(state = state, signal = list(warning = FALSE, drift = FALSE)))
  }

  p_hat_l <- state$n_err / p$window_size
  n_err_s <- sum(state$window[(p$window_size - p$short_size + 1):p$window_size])
  p_hat_s <- n_err_s / p$short_size

  if (p_hat_l < state$p_min_l) state$p_min_l <- p_hat_l
  if (p_hat_s < state$p_min_s) state$p_min_s <- p_hat_s

  eps_l <- sqrt(log(1 / p$delta) / (2 * p$window_size))
  eps_s <- sqrt(log(1 / p$delta) / (2 * p$short_size))

  drift <- (p_hat_l - state$p_min_l) > eps_l ||
           (p_hat_s - state$p_min_s) > eps_s
  state$change_detected <- drift
  list(state = state, signal = list(warning = FALSE, drift = drift))
}
