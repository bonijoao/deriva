# EWMA for concept drift (Ross et al. 2012). EWMA of the 0/1 error stream;
# drift when it deviates from the running mean by more than L analytic SDs.
# No external R oracle -> validated against synthetic ground truth.
# Input: 1 = error. No warning level. NA during warm-up.
ewma_init <- function(params) {
  list(params = params, n = 0, mu0 = 0, z = 0, change_detected = FALSE)
}

ewma_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- ewma_init(p)
  state$n <- state$n + 1
  state$mu0 <- state$mu0 + (obs - state$mu0) / state$n
  state$z <- p$lambda * obs + (1 - p$lambda) * state$z
  if (state$n < p$min_instances) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  var_proc <- state$mu0 * (1 - state$mu0)
  sigma_ewma <- sqrt(p$lambda / (2 - p$lambda) * var_proc *
                       (1 - (1 - p$lambda)^(2 * state$n)))
  drift <- abs(state$z - state$mu0) > p$L * sigma_ewma
  state$change_detected <- drift
  list(state = state, signal = list(warning = NA, drift = drift))
}
