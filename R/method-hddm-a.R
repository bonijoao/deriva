# HDDM_A - Hoeffding Drift Detection Method, A-test (Frias-Blanco et al. 2015).
# Compares the running mean against a tracked minimum/maximum using Hoeffding
# bounds. Input: 1 = error -> detects an increase in the error mean. Translation
# verified bit-for-bit against datadriftR (golden fixture). Original (MIT).
# No min_instances warm-up: the Hoeffding bounds prevent early firing. Has warning.
# Estimation/delay fields of the reference are output-only and omitted here.
hddm_a_init <- function(params) {
  list(params = params, total_n = 0, total_c = 0, n_min = 0, c_min = 0,
       n_max = 0, c_max = 0, change_detected = FALSE, warning_detected = FALSE)
}

hddm_a_mean_incr <- function(c_min, n_min, total_c, total_n, confidence) {
  if (n_min == total_n) return(FALSE)
  m <- (total_n - n_min) / n_min * (1 / total_n)
  cota <- sqrt(m / 2 * log(2 / confidence))
  total_c / total_n - c_min / n_min >= cota
}

hddm_a_mean_decr <- function(c_max, n_max, total_c, total_n, drift_confidence) {
  if (n_max == total_n) return(FALSE)
  m <- (total_n - n_max) / n_max * (1 / total_n)
  cota <- sqrt(m / 2 * log(2 / drift_confidence))
  c_max / n_max - total_c / total_n >= cota
}

hddm_a_step <- function(state, obs) {
  p <- state$params
  state$total_n <- state$total_n + 1
  state$total_c <- state$total_c + obs
  if (state$n_min == 0) { state$n_min <- state$total_n; state$c_min <- state$total_c }
  if (state$n_max == 0) { state$n_max <- state$total_n; state$c_max <- state$total_c }
  cota <- sqrt(1 / (2 * state$n_min) * log(1 / p$drift_confidence))
  cota1 <- sqrt(1 / (2 * state$total_n) * log(1 / p$drift_confidence))
  if (state$c_min / state$n_min + cota >= state$total_c / state$total_n + cota1) {
    state$c_min <- state$total_c; state$n_min <- state$total_n
  }
  cota <- sqrt(1 / (2 * state$n_max) * log(1 / p$drift_confidence))
  if (state$c_max / state$n_max - cota <= state$total_c / state$total_n - cota1) {
    state$c_max <- state$total_c; state$n_max <- state$total_n
  }
  if (hddm_a_mean_incr(state$c_min, state$n_min, state$total_c, state$total_n,
                       p$drift_confidence)) {
    state$n_min <- 0; state$n_max <- 0; state$total_n <- 0
    state$c_min <- 0; state$c_max <- 0; state$total_c <- 0
    state$change_detected <- TRUE; state$warning_detected <- FALSE
  } else if (hddm_a_mean_incr(state$c_min, state$n_min, state$total_c, state$total_n,
                              p$warning_confidence)) {
    state$change_detected <- FALSE; state$warning_detected <- TRUE
  } else {
    state$change_detected <- FALSE; state$warning_detected <- FALSE
  }
  if (p$two_side_option && hddm_a_mean_decr(state$c_max, state$n_max, state$total_c,
                                            state$total_n, p$drift_confidence)) {
    state$n_min <- 0; state$n_max <- 0; state$total_n <- 0
    state$c_min <- 0; state$c_max <- 0; state$total_c <- 0
  }
  list(state = state, signal = list(warning = state$warning_detected,
                                    drift = state$change_detected))
}
