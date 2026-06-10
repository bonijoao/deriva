# HDDM_W - Hoeffding Drift Detection Method, W-test (Frias-Blanco et al. 2015).
# EWMA-based variant using McDiarmid bounds over four monitors (incr/decr x
# sample1/2). Input: 1 = error -> detects an increase in the EWMA error mean.
# Translation verified bit-for-bit against datadriftR (golden fixture). MIT.
# No min_instances warm-up. Has warning.

hddm_w_si <- function() list(EWMA_estimator = -1, indp_bounded_cond_sum = 1)

hddm_w_init <- function(params) {
  list(params = params, total = hddm_w_si(),
       s1_incr = hddm_w_si(), s2_incr = hddm_w_si(),
       s1_decr = hddm_w_si(), s2_decr = hddm_w_si(),
       incr_cutpoint = Inf, decr_cutpoint = Inf, width = 0,
       change_detected = FALSE, warning_detected = FALSE)
}

hddm_w_detect_incr <- function(s1, s2, confidence) {
  if (s1$EWMA_estimator < 0 || s2$EWMA_estimator < 0) return(FALSE)
  ibc <- s1$indp_bounded_cond_sum + s2$indp_bounded_cond_sum
  bound <- sqrt(ibc * log(1 / confidence) / 2)
  s2$EWMA_estimator - s1$EWMA_estimator > bound
}

hddm_w_update_incr <- function(s, value, confidence) {
  p <- s$params
  aux <- 1 - p$lambda_option
  bound <- sqrt(s$total$indp_bounded_cond_sum * log(1 / confidence) / 2)
  if (s$total$EWMA_estimator + bound < s$incr_cutpoint) {
    s$incr_cutpoint <- s$total$EWMA_estimator + bound
    s$s1_incr$EWMA_estimator <- s$total$EWMA_estimator
    s$s1_incr$indp_bounded_cond_sum <- s$total$indp_bounded_cond_sum
    s$s2_incr <- hddm_w_si()
  } else {
    if (s$s2_incr$EWMA_estimator < 0) {
      s$s2_incr$EWMA_estimator <- value
      s$s2_incr$indp_bounded_cond_sum <- 1
    } else {
      s$s2_incr$EWMA_estimator <- p$lambda_option * value + aux * s$s2_incr$EWMA_estimator
      s$s2_incr$indp_bounded_cond_sum <- p$lambda_option^2 + aux^2 * s$s2_incr$indp_bounded_cond_sum
    }
  }
  s
}

hddm_w_update_decr <- function(s, value, confidence) {
  p <- s$params
  aux <- 1 - p$lambda_option
  epsilon <- sqrt(s$total$indp_bounded_cond_sum * log(1 / confidence) / 2)
  if ((s$total$EWMA_estimator - epsilon) > s$decr_cutpoint) {
    s$decr_cutpoint <- s$total$EWMA_estimator - epsilon
    s$s1_decr$EWMA_estimator <- s$total$EWMA_estimator
    s$s1_decr$indp_bounded_cond_sum <- s$total$indp_bounded_cond_sum
    s$s2_decr <- hddm_w_si()
  } else {
    if (s$s2_decr$EWMA_estimator < 0) {
      s$s2_decr$EWMA_estimator <- value
      s$s2_decr$indp_bounded_cond_sum <- 1
    } else {
      s$s2_decr$EWMA_estimator <- p$lambda_option * value + aux * s$s2_decr$EWMA_estimator
      s$s2_decr$indp_bounded_cond_sum <- p$lambda_option^2 + aux^2 * s$s2_decr$indp_bounded_cond_sum
    }
  }
  s
}

hddm_w_reset <- function(s) {
  s$total <- hddm_w_si()
  s$s1_decr <- hddm_w_si(); s$s1_incr <- hddm_w_si()
  s$s2_decr <- hddm_w_si(); s$s2_incr <- hddm_w_si()
  s$incr_cutpoint <- Inf; s$decr_cutpoint <- Inf; s$width <- 0
  s$change_detected <- FALSE; s$warning_detected <- FALSE
  s
}

hddm_w_step <- function(state, obs) {
  p <- state$params
  aux <- 1 - p$lambda_option
  state$width <- state$width + 1
  if (state$total$EWMA_estimator < 0) {
    state$total$EWMA_estimator <- obs
    state$total$indp_bounded_cond_sum <- 1
  } else {
    state$total$EWMA_estimator <- p$lambda_option * obs + aux * state$total$EWMA_estimator
    state$total$indp_bounded_cond_sum <- p$lambda_option^2 + aux^2 * state$total$indp_bounded_cond_sum
  }
  state <- hddm_w_update_incr(state, obs, p$drift_confidence)
  if (hddm_w_detect_incr(state$s1_incr, state$s2_incr, p$drift_confidence)) {
    state <- hddm_w_reset(state)
    state$change_detected <- TRUE; state$warning_detected <- FALSE
  } else if (hddm_w_detect_incr(state$s1_incr, state$s2_incr, p$warning_confidence)) {
    state$change_detected <- FALSE; state$warning_detected <- TRUE
  } else {
    state$change_detected <- FALSE; state$warning_detected <- FALSE
  }
  state <- hddm_w_update_decr(state, obs, p$drift_confidence)
  if (p$two_side_option && hddm_w_detect_incr(state$s2_decr, state$s1_decr, p$drift_confidence)) {
    state <- hddm_w_reset(state)
  }
  list(state = state, signal = list(warning = state$warning_detected,
                                    drift = state$change_detected))
}
