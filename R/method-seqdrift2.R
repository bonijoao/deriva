# SeqDrift2 - sequential change detector with reservoir sampling (Pears,
# Sakthithasan & Koh 2014, "Detecting concept change in dynamic data streams",
# Machine Learning 97). Keeps two equal-sized stores: a RIGHT repository that
# buffers the most recent block of values, and a LEFT reservoir that holds a
# uniform random sample of the older data (Vitter reservoir sampling). At every
# block boundary it bounds the difference between the two means with the
# BERNSTEIN inequality and flags drift when |mean_right - mean_left| exceeds it.
#
# Reservoir sampling makes SeqDrift2 STOCHASTIC (unlike ADWIN/SEED): the same
# stream can yield slightly different detections across runs. Set a seed for
# reproducibility. No external R oracle (datadriftR lacks SeqDrift2) -> synthetic
# validation. signal_type = "distribution"; no warning (NA); window-based warm-up
# returns FALSE. The false-positive/delay optimisation refinement of the paper
# (mean-increase modulation of the bound) is intentionally omitted; the converged
# Bernstein epsilon (k -> 0 limit) is used directly.

seqdrift2_init <- function(params) {
  list(params = params, right = numeric(0), left = numeric(0), left_count = 0,
       n_total = 0, num_tests = 0, drift_detected = FALSE, n_detections = 0)
}

# Converged Bernstein bound on the difference of means (k -> 0 limit), with a
# geometric multiple-testing correction over the number of tests performed.
seqdrift2_epsilon <- function(N, variance, delta, num_tests) {
  dseries <- 2 * (1 - 0.5^num_tests)            # geometric series correction
  ddeltadash <- delta / dseries
  x <- log(4 / ddeltadash)
  (x + sqrt(x^2 + 18 * N * x * variance)) / (3 * N)
}

# Offer one value to the left reservoir (Vitter): fill until full, then replace a
# uniformly random slot with probability capacity / count.
seqdrift2_offer <- function(s, v) {
  cap <- s$params$block_size
  s$left_count <- s$left_count + 1
  if (length(s$left) < cap) {
    s$left <- c(s$left, v)
  } else {
    j <- sample.int(s$left_count, 1L)
    if (j <= cap) s$left[j] <- v
  }
  s
}

# Move every value of the right repository into the reservoir, then clear it.
seqdrift2_promote <- function(s) {
  for (v in s$right) s <- seqdrift2_offer(s, v)
  s$right <- numeric(0)
  s
}

seqdrift2_step <- function(state, obs) {
  p <- state$params
  if (state$drift_detected) state <- seqdrift2_init(p)
  state$drift_detected <- FALSE
  state$n_total <- state$n_total + 1
  state$right <- c(state$right, obs)
  if (length(state$right) >= p$block_size) {     # block boundary -> test
    if (length(state$left) > 0) {
      state$num_tests <- state$num_tests + 1
      combined <- c(state$left, state$right)
      variance <- stats::var(combined)
      if (!is.finite(variance)) variance <- 0
      N <- length(state$right)
      eps <- seqdrift2_epsilon(N, variance, p$delta, state$num_tests)
      diff <- abs(mean(state$right) - mean(state$left))
      if (is.finite(eps) && diff > eps) {
        state$drift_detected <- TRUE             # state resets on next step
        state$n_detections <- state$n_detections + 1
      } else {
        state <- seqdrift2_promote(state)        # age the right block into the reservoir
      }
    } else {
      state <- seqdrift2_promote(state)          # first block: seed the reservoir
    }
  }
  list(state = state, signal = list(warning = NA, drift = state$drift_detected))
}
