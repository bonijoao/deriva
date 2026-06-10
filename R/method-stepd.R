# STEPD - Statistical Test of Equal Proportions Detector (Nishida 2008).
# Compares the recent error rate against the older error rate with a
# continuity-corrected chi-square test of equal proportions. Adapted to
# deriva's 1=error convention (the original uses 1=correct): drift fires when
# the RECENT error rate is significantly HIGHER than the older one.
# No external R oracle -> validated against synthetic ground truth. Has warning.
stepd_init <- function(params) {
  list(params = params, window = numeric(0), n_total = 0, r_total = 0,
       warning_detected = FALSE, change_detected = FALSE)
}

# one-sided (recent > old) chi-square p-value with Yates continuity correction
stepd_pvalue <- function(r_old, n_old, r_rec, n_rec) {
  if (n_old <= 0 || n_rec <= 0) return(1)
  p_old <- r_old / n_old
  p_rec <- r_rec / n_rec
  if (p_rec <= p_old) return(1)                       # only flag increases
  p_hat <- (r_old + r_rec) / (n_old + n_rec)
  denom <- p_hat * (1 - p_hat) * (1 / n_old + 1 / n_rec)
  if (denom <= 0) return(1)
  cc <- 0.5 * (1 / n_old + 1 / n_rec)                 # continuity correction
  z <- (abs(p_old - p_rec) - cc) / sqrt(denom)
  if (z < 0) z <- 0
  stats::pnorm(z, lower.tail = FALSE)                 # one-sided
}

stepd_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- stepd_init(p)
  state$n_total <- state$n_total + 1
  state$r_total <- state$r_total + obs
  state$window <- c(state$window, obs)
  if (length(state$window) > p$window_size) {
    state$window <- state$window[-1]
  }
  if (state$n_total < p$min_instances || length(state$window) < p$window_size) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  r_rec <- sum(state$window)
  n_rec <- length(state$window)
  r_old <- state$r_total - r_rec
  n_old <- state$n_total - n_rec
  pv <- stepd_pvalue(r_old, n_old, r_rec, n_rec)
  drift <- pv < p$out_control_level
  warning <- !drift && pv < p$warning_level
  state$change_detected <- drift
  state$warning_detected <- warning
  list(state = state, signal = list(warning = warning, drift = drift))
}
