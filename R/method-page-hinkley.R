# Page-Hinkley test (Page 1954). Sequential CUSUM for a persistent change in
# the mean of a numeric stream. Dual-use: an error stream (concept drift) or a
# raw continuous signal (data drift). Implemented from the curated pseudocode;
# validated against datadriftR (GPL) via the golden fixture. Original (MIT).
# No warning level -> signal$warning is always NA. NA during warm-up.

page_hinkley_init <- function(params) {
  list(params = params, sample_count = 1, x_mean = 0, sum = 0,
       PH = 0, min_PH = Inf, change_detected = FALSE)
}

page_hinkley_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- page_hinkley_init(p)
  state$sum <- p$alpha * state$sum + obs
  state$x_mean <- state$sum / state$sample_count
  state$PH <- max(0, p$alpha * state$PH + (obs - state$x_mean - p$delta))
  state$min_PH <- min(state$PH, state$min_PH)
  state$sample_count <- state$sample_count + 1
  state$change_detected <- FALSE
  if (state$sample_count < p$min_instances) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  drift <- (state$PH - state$min_PH) > p$threshold
  state$change_detected <- drift
  list(state = state, signal = list(warning = NA, drift = drift))
}
