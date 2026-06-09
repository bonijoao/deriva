# EDDM - Early Drift Detection Method (Baena-Garcia et al. 2006).
# Implemented from the paper / curated pseudocode; validated against the
# OUTPUT of datadriftR (GPL) via the golden fixture. Code is original (MIT).
# Tracks the distance between consecutive errors; warning + drift levels are
# fractions of the historical max of mean+2*std. NA during warm-up.

eddm_init <- function(params) {
  list(params = params, m_n = 1, m_num_errors = 0, m_d = 0, m_lastd = 0,
       m_mean = 0, m_std_temp = 0, m_m2s_max = 0,
       warning_detected = FALSE, change_detected = FALSE)
}

eddm_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- eddm_init(p)
  state$m_n <- state$m_n + 1
  if (obs == 1) {
    state$warning_detected <- FALSE
    state$m_num_errors <- state$m_num_errors + 1
    state$m_lastd <- state$m_d
    state$m_d <- state$m_n - 1
    distance <- state$m_d - state$m_lastd
    old_mean <- state$m_mean
    state$m_mean <- state$m_mean + (distance - state$m_mean) / state$m_num_errors
    state$m_std_temp <- state$m_std_temp +
      (distance - state$m_mean) * (distance - old_mean)
    std <- sqrt(state$m_std_temp / state$m_num_errors)
    m2s <- state$m_mean + 2 * std
    if (state$m_n >= p$min_instances) {
      if (m2s > state$m_m2s_max) {
        state$m_m2s_max <- m2s
      } else {
        ratio <- m2s / state$m_m2s_max
        if (state$m_num_errors > p$min_instances && ratio < p$out_control_level) {
          state$change_detected <- TRUE
        } else if (state$m_num_errors > p$min_instances && ratio < p$warning_level) {
          state$warning_detected <- TRUE
        } else {
          state$warning_detected <- FALSE
        }
      }
    }
  }
  if (state$m_n < p$min_instances) {
    signal <- list(warning = NA, drift = NA)
  } else {
    signal <- list(warning = state$warning_detected, drift = state$change_detected)
  }
  list(state = state, signal = signal)
}
