# CUSUM - Cumulative Sum (Page 1954). Sequential cumulative-sum test for a
# persistent INCREASE in the mean of a numeric stream. Dual-use: an error
# stream (concept drift) or a raw continuous signal (data drift). The classic
# QC test of which Page-Hinkley is a variant; here the standard drift formulation
# (scikit-multiflow/MOA): accumulate positive deviations floored at zero and fire
# when the sum exceeds a threshold (no min-tracking, no forgetting — that is the
# difference from Page-Hinkley). No external R oracle -> validated synthetically.
# No warning level -> signal$warning is always NA. NA during warm-up.
cusum_init <- function(params) {
  list(params = params, sample_count = 1, x_mean = 0, sum = 0,
       change_detected = FALSE)
}

cusum_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- cusum_init(p)
  state$x_mean <- state$x_mean + (obs - state$x_mean) / state$sample_count
  state$sum <- max(0, state$sum + (obs - state$x_mean - p$delta))
  state$sample_count <- state$sample_count + 1
  state$change_detected <- FALSE
  if (state$sample_count < p$min_instances) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  drift <- state$sum > p$threshold
  state$change_detected <- drift
  list(state = state, signal = list(warning = NA, drift = drift))
}
