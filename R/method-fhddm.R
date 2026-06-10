# FHDDM - Fast Hoeffding Drift Detection Method (Pesaranghader & Viktor 2016).
# Fixed sliding window; tracks the historical MIN error rate and fires when the
# current error rate exceeds it by more than the Hoeffding bound. Adapted to
# deriva's 1=error convention (original tracks max correct prob). No external R
# oracle -> validated against synthetic ground truth. Has warning.
# Returns FALSE while the window fills (no min_instances; like KSWIN).
fhddm_init <- function(params) {
  list(params = params, window = numeric(0), n_err = 0, p_min = Inf,
       warning_detected = FALSE, change_detected = FALSE)
}

fhddm_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- fhddm_init(p)
  if (length(state$window) >= p$window_size) {
    state$n_err <- state$n_err - state$window[1]
    state$window <- state$window[-1]
  }
  state$window <- c(state$window, obs)
  state$n_err <- state$n_err + obs
  if (length(state$window) < p$window_size) {
    return(list(state = state, signal = list(warning = FALSE, drift = FALSE)))
  }
  p_hat <- state$n_err / p$window_size
  if (p_hat < state$p_min) state$p_min <- p_hat
  eps_d <- sqrt(log(1 / p$delta) / (2 * p$window_size))
  eps_w <- sqrt(log(1 / p$delta_warning) / (2 * p$window_size))
  drift <- (p_hat - state$p_min) > eps_d
  warning <- !drift && (p_hat - state$p_min) > eps_w
  state$change_detected <- drift
  state$warning_detected <- warning
  list(state = state, signal = list(warning = warning, drift = drift))
}
