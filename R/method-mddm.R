# MDDM - McDiarmid Drift Detection Methods (Pesaranghader, Viktor & Paquet 2018).
# Weighted sliding window: recent predictions carry higher weight, so the
# weighted error rate reacts faster to a drop in performance. Fires when the
# weighted error mean exceeds its historical minimum by more than the McDiarmid
# bound. Three variants differ ONLY in the weighting scheme:
#   MDDM-A (arithmetic): w_i = 1 + (i-1)*d
#   MDDM-G (geometric):  w_i = r^(i-1)
#   MDDM-E (Euler):      w_i = e^(lambda*(i-1))
# Adapted to deriva's 1=error convention (paper uses 1=correct + max-tracking):
# tracks the MIN weighted error mean. Drift-only (no warning), like FHDDMS.
# No external R oracle (datadriftR has no MDDM) -> validated synthetically.
# Returns FALSE while the window fills (no min_instances; like FHDDM).

# Normalize weights and precompute the McDiarmid epsilon (eq. 6-8 of the paper).
mddm_setup <- function(w, delta) {
  v <- w / sum(w)
  list(weights = v, eps = sqrt(sum(v^2) / 2 * log(1 / delta)))
}

mddm_state <- function(params, w) {
  se <- mddm_setup(w, params$delta)
  list(params = params, window = numeric(0), weights = se$weights,
       eps = se$eps, mu_min = Inf, change_detected = FALSE)
}

mddm_a_init <- function(params) {
  i <- seq_len(params$window_size)
  mddm_state(params, 1 + (i - 1) * params$d)
}

mddm_g_init <- function(params) {
  i <- seq_len(params$window_size)
  mddm_state(params, params$r ^ (i - 1))
}

mddm_e_init <- function(params) {
  i <- seq_len(params$window_size)
  mddm_state(params, exp(params$lambda * (i - 1)))
}

# Shared step for all three variants (weights/eps already in state).
mddm_step <- function(state, obs) {
  n <- state$params$window_size
  if (state$change_detected) {
    state$window <- numeric(0)
    state$mu_min <- Inf
    state$change_detected <- FALSE
  }
  if (length(state$window) >= n) state$window <- state$window[-1]
  state$window <- c(state$window, obs)
  if (length(state$window) < n) {
    return(list(state = state, signal = list(warning = FALSE, drift = FALSE)))
  }
  mu <- sum(state$window * state$weights)        # weighted error mean (sum(v)=1)
  if (mu < state$mu_min) state$mu_min <- mu
  drift <- (mu - state$mu_min) >= state$eps
  state$change_detected <- drift
  list(state = state, signal = list(warning = FALSE, drift = drift))
}
