# ADWIN - Adaptive Windowing (Bifet & Gavalda 2007). Maintains a variable-length
# window of recent values as an exponential histogram of buckets; when the means
# of two sub-windows differ by more than an adaptive (Hoeffding-style) bound, the
# older sub-window is dropped and drift is flagged. Translation verified
# bit-for-bit against datadriftR (golden fixture). Original (MIT).
# signal_type = "distribution" (numeric). No warning level (NA). Window-based
# warm-up returns FALSE (no min_instances).

adwin_init <- function(params) {
  list(params = params, n = 0, sum = 0, variance = 0, width = 0, tick = 0,
       drift_detected = FALSE, n_detections = 0,
       buckets = list(), bucket_count = integer())
}

adwin_insert <- function(s, value) {
  if (length(s$buckets) == 0) {
    s$buckets <- list(list(list(total = value, variance = 0, n = 1)))
    s$bucket_count <- 1
  } else {
    s$buckets[[1]] <- c(s$buckets[[1]], list(list(total = value, variance = 0, n = 1)))
    s$bucket_count[1] <- s$bucket_count[1] + 1
  }
  s$width <- s$width + 1
  old_mean <- if (s$width > 1) s$sum / (s$width - 1) else 0
  s$sum <- s$sum + value
  new_mean <- s$sum / s$width
  if (s$width > 1) s$variance <- s$variance + (value - old_mean) * (value - new_mean)
  s
}

adwin_compress <- function(s) {
  level <- 1
  while (level <= length(s$bucket_count)) {
    if (is.na(s$bucket_count[level]) || s$bucket_count[level] <= s$params$max_buckets) break
    if (length(s$buckets[[level]]) >= 2) {
      b1 <- s$buckets[[level]][[1]]
      b2 <- s$buckets[[level]][[2]]
      n_combined <- b1$n + b2$n
      total_combined <- b1$total + b2$total
      mean1 <- b1$total / b1$n
      mean2 <- b2$total / b2$n
      mean_combined <- total_combined / n_combined
      var_combined <- b1$variance + b2$variance +
        b1$n * (mean1 - mean_combined)^2 + b2$n * (mean2 - mean_combined)^2
      new_bucket <- list(total = total_combined, variance = var_combined, n = n_combined)
      s$buckets[[level]] <- s$buckets[[level]][-(1:2)]
      s$bucket_count[level] <- s$bucket_count[level] - 2
      next_level <- level + 1
      if (next_level > length(s$buckets)) {
        s$buckets[[next_level]] <- list()
        s$bucket_count[next_level] <- 0
      }
      s$buckets[[next_level]] <- c(s$buckets[[next_level]], list(new_bucket))
      s$bucket_count[next_level] <- s$bucket_count[next_level] + 1
    }
    level <- level + 1
  }
  s
}

adwin_recalc_var <- function(s) {
  if (s$width <= 1) { s$variance <- 0; return(s) }
  mean_val <- s$sum / s$width
  var_sum <- 0
  for (level in seq_along(s$buckets)) {
    for (bucket in s$buckets[[level]]) {
      bm <- bucket$total / bucket$n
      var_sum <- var_sum + bucket$variance + bucket$n * (bm - mean_val)^2
    }
  }
  s$variance <- var_sum
  s
}

adwin_remove_old <- function(s, n_to_remove) {
  removed <- 0
  for (level in seq_along(s$buckets)) {
    while (length(s$buckets[[level]]) > 0 && removed < n_to_remove) {
      bucket <- s$buckets[[level]][[1]]
      if (removed + bucket$n <= n_to_remove) {
        s$sum <- s$sum - bucket$total
        s$width <- s$width - bucket$n
        removed <- removed + bucket$n
        s$buckets[[level]] <- s$buckets[[level]][-1]
        s$bucket_count[level] <- max(0, s$bucket_count[level] - 1)
      } else break
    }
    if (removed >= n_to_remove) break
  }
  adwin_recalc_var(s)
}

adwin_detect_once <- function(s) {
  p <- s$params
  if (s$width < 2 * p$min_window_length) return(list(state = s, detected = FALSE))
  n0 <- 0
  sum0 <- 0
  for (level in seq_along(s$buckets)) {
    bal <- s$buckets[[level]]
    if (length(bal) == 0) next
    for (j in seq_along(bal)) {
      bucket <- bal[[j]]
      n0 <- n0 + bucket$n
      sum0 <- sum0 + bucket$total
      n1 <- s$width - n0
      sum1 <- s$sum - sum0
      if (n0 < p$min_window_length || n1 < p$min_window_length) next
      mean0 <- sum0 / n0
      mean1 <- sum1 / n1
      delta_prime <- log(2 * log(s$width) / p$delta)
      m_recip <- (1 / (n0 - p$min_window_length + 1)) + (1 / (n1 - p$min_window_length + 1))
      var_in_window <- s$variance / s$width
      eps <- sqrt(2 * m_recip * var_in_window * delta_prime) +
        (2 / 3) * delta_prime * m_recip
      if (abs(mean0 - mean1) > eps) {
        s <- adwin_remove_old(s, n0)
        return(list(state = s, detected = TRUE))
      }
    }
  }
  list(state = s, detected = FALSE)
}

adwin_step <- function(state, obs) {
  p <- state$params
  if (state$drift_detected) state <- adwin_init(p)
  state$drift_detected <- FALSE
  state$n <- state$n + 1
  state$tick <- state$tick + 1
  state <- adwin_insert(state, obs)
  state <- adwin_compress(state)
  if (state$tick >= p$clock && state$width > p$grace_period) {
    state$tick <- 0
    repeat {
      if (state$width <= p$min_window_length * 2) break
      r <- adwin_detect_once(state)
      state <- r$state
      if (r$detected) {
        state$drift_detected <- TRUE
        state$n_detections <- state$n_detections + 1
      } else break
    }
  }
  list(state = state, signal = list(warning = NA, drift = state$drift_detected))
}
