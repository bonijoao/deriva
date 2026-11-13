# SeqDrift1 - sequential change detector with a sliding left window
# (Sakthithasan, Pears & Koh 2013, "One pass concept change detection for data
# streams", PAKDD 2013, LNCS 7819). The predecessor of SeqDrift2: a RIGHT
# repository buffers recent values and, at every block boundary, its mean is
# compared with that of a LEFT window holding the most recent older blocks.
#
# Threshold: Theorem 1 of Pears, Sakthithasan & Koh (2014, Machine Learning 97),
# the Bernstein bound on the difference of two means, with delta split over
# successive tests by the geometric series 2(1 - 0.5^n). Structure (defaults,
# left window capped at 1 / delta blocks, warning zone that doubles the right
# repository) follows the author's MOA implementation, read for structure only
# (GPL); this code is original (MIT). MOA quirks deliberately not reproduced:
# means divided by the nominal sample size instead of the true count, a variance
# formula valid only for 0/1 values, and random sub-sampling of the left window.
# Ours: num_tests restarts at 0 after a drift (the new reference starts a fresh
# test sequence), and the warning zone is exposed through .warning.
# Deterministic. The guarantee assumes values in [0, 1], as for "seqdrift2".

# Theorem 1 of Pears et al. (2014): twice the converged SeqDrift2 bound.
seqdrift1_epsilon <- function(b, variance, delta, num_tests) {
  2 * seqdrift2_epsilon(b, variance, delta, num_tests)
}

seqdrift1_init <- function(params) {
  list(params = params, left = numeric(0), right = numeric(0),
       sample_size = params$block_size, num_tests = 0,
       warning = FALSE, judging = FALSE)
}

seqdrift1_step <- function(state, obs) {
  p <- state$params
  b <- p$block_size
  cap <- floor(1 / p$delta) * b                    # MOA: 1 / delta blocks at most
  state$right <- c(state$right, obs)
  drift <- FALSE
  if (length(state$right) >= state$sample_size) {  # a test point
    if (length(state$left) == 0) {                 # first block: the reference
      state$left <- state$right
      state$right <- numeric(0)
    } else {
      state$judging <- TRUE
      state$num_tests <- state$num_tests + 1
      v <- stats::var(c(state$left, state$right))
      if (!is.finite(v)) v <- 0
      n <- length(state$right)
      diff <- abs(mean(state$right) - mean(state$left))
      if (diff >= seqdrift1_epsilon(n, v, p$delta, state$num_tests)) {
        drift <- TRUE                              # the recent data is the new reference
        state$left <- state$right
        state$right <- numeric(0)
        state$sample_size <- b
        state$num_tests <- 0
        state$warning <- FALSE
      } else if (diff >= seqdrift1_epsilon(n, v, p$delta_warning, state$num_tests)) {
        state$warning <- TRUE                      # keep the right window growing
        state$sample_size <- min(2 * state$sample_size, cap)
        if (length(state$right) >= state$sample_size) {
          # already at the cap: slide by dropping the oldest block
          state$right <- utils::tail(state$right, state$sample_size - b)
        }
      } else {                                     # homogeneous: right joins left
        state$warning <- FALSE
        state$left <- utils::tail(c(state$left, state$right), cap)
        state$right <- numeric(0)
        state$sample_size <- b
      }
    }
  }
  if (!state$judging) return(list(state = state, signal = list(warning = NA, drift = NA)))
  signal <- list(warning = state$warning, drift = drift)
  if (drift) state$judging <- FALSE                # re-warm until the next test
  list(state = state, signal = signal)
}
