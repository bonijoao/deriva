# SEED - block-based adaptive windowing (Huang, Koh, Dobbie & Pears 2014,
# "Drift Detection Using Stream Volatility"). Same idea as ADWIN: keep a
# variable-length window and flag drift when the means of an older vs. a newer
# sub-window differ by more than the Hoeffding/ADWIN bound; but the window is
# organised into fixed-size BLOCKS (not exponential buckets), tested only at
# block boundaries, and compressed by merging adjacent homogeneous blocks
# (linear compression) to bound memory. The bound is identical to deriva's
# ADWIN (see method-adwin.R): eps = sqrt(2*m*v*dd) + (2/3)*dd*m.
#
# No external R oracle (datadriftR lacks SEED) -> synthetic validation.
# signal_type = "distribution" (numeric, like ADWIN). No warning level (NA).
# Window-based warm-up returns FALSE. Compression is implemented as a documented
# simplification of MOA's alpha-decayed schedule: it merges adjacent blocks whose
# means are within epsilon_prime, sparing the two most recent blocks so detection
# resolution at the head is preserved.

seed_init <- function(params) {
  list(params = params, blocks = list(), n_total = 0,
       blocks_since_compress = 0, drift_detected = FALSE, n_detections = 0)
}

# Append value to the newest block; start a fresh block when the current is full.
seed_add <- function(s, value) {
  bs <- s$params$block_size
  nb <- length(s$blocks)
  if (nb == 0 || s$blocks[[nb]]$n >= bs) {
    s$blocks[[nb + 1]] <- list(total = value, variance = 0, n = 1)
    s$blocks_since_compress <- s$blocks_since_compress + 1
  } else {
    b <- s$blocks[[nb]]
    old_mean <- b$total / b$n
    b$total <- b$total + value
    b$n <- b$n + 1
    new_mean <- b$total / b$n
    b$variance <- b$variance + (value - old_mean) * (value - new_mean)
    s$blocks[[nb]] <- b
  }
  s
}

# Aggregate width / sum / mean / variance of the whole window from the blocks.
seed_window_stats <- function(blocks) {
  width <- 0; total <- 0
  for (b in blocks) { width <- width + b$n; total <- total + b$total }
  if (width == 0) return(list(width = 0, total = 0, mean = 0, variance = 0))
  wmean <- total / width
  var_sum <- 0
  for (b in blocks) {
    bm <- b$total / b$n
    var_sum <- var_sum + b$variance + b$n * (bm - wmean)^2
  }
  list(width = width, total = total, mean = wmean, variance = var_sum)
}

# ADWIN/Hoeffding bound with Bonferroni-style log term (identical to ADWIN).
seed_bound <- function(n0, n1, width, variance, delta) {
  dd <- log(2 * log(width) / delta)
  v <- variance / width
  m <- (1 / n0) + (1 / n1)
  sqrt(2 * m * v * dd) + (2 / 3) * dd * m
}

# Scan all block-boundary cut points; on the first cut whose sub-window means
# differ by more than the bound, drop the OLDER sub-window and re-scan.
seed_detect <- function(s) {
  p <- s$params
  detected_any <- FALSE
  repeat {
    blocks <- s$blocks
    nb <- length(blocks)
    if (nb < 2) break
    st <- seed_window_stats(blocks)
    if (st$width < 2) break
    cut_found <- FALSE
    n0 <- 0; sum0 <- 0
    for (i in seq_len(nb - 1)) {            # cut AFTER block i (older = 1..i)
      n0 <- n0 + blocks[[i]]$n
      sum0 <- sum0 + blocks[[i]]$total
      n1 <- st$width - n0
      sum1 <- st$total - sum0
      if (n0 < 1 || n1 < 1) next
      mean0 <- sum0 / n0
      mean1 <- sum1 / n1
      eps <- seed_bound(n0, n1, st$width, st$variance, p$delta)
      if (is.finite(eps) && abs(mean0 - mean1) > eps) {
        s$blocks <- blocks[(i + 1):nb]       # drop older sub-window
        detected_any <- TRUE
        cut_found <- TRUE
        break
      }
    }
    if (!cut_found) break
  }
  list(state = s, detected = detected_any)
}

# Linear compression: merge adjacent blocks with close means, sparing the two
# most recent blocks (preserves detection resolution at the head).
seed_compress <- function(s) {
  p <- s$params
  blocks <- s$blocks
  nb <- length(blocks)
  if (nb < 4) { s$blocks_since_compress <- 0; return(s) }
  head_keep <- blocks[(nb - 1):nb]           # spare the two newest
  body <- blocks[seq_len(nb - 2)]
  merged <- list()
  cur <- body[[1]]
  for (i in 2:length(body)) {
    nxt <- body[[i]]
    mean_cur <- cur$total / cur$n
    mean_nxt <- nxt$total / nxt$n
    if (abs(mean_cur - mean_nxt) < p$epsilon_prime) {
      n_comb <- cur$n + nxt$n
      total_comb <- cur$total + nxt$total
      mean_comb <- total_comb / n_comb
      var_comb <- cur$variance + nxt$variance +
        cur$n * (mean_cur - mean_comb)^2 + nxt$n * (mean_nxt - mean_comb)^2
      cur <- list(total = total_comb, variance = var_comb, n = n_comb)
    } else {
      merged[[length(merged) + 1]] <- cur
      cur <- nxt
    }
  }
  merged[[length(merged) + 1]] <- cur
  s$blocks <- c(merged, head_keep)
  s$blocks_since_compress <- 0
  s
}

seed_step <- function(state, obs) {
  p <- state$params
  if (state$drift_detected) state <- seed_init(p)
  state$drift_detected <- FALSE
  state$n_total <- state$n_total + 1
  state <- seed_add(state, obs)
  if (state$n_total %% p$block_size == 0) {  # test only at block boundaries
    r <- seed_detect(state)
    state <- r$state
    if (r$detected) {
      state$drift_detected <- TRUE
      state$n_detections <- state$n_detections + 1
    }
    if (state$blocks_since_compress > p$compression_term) {
      state <- seed_compress(state)
    }
  }
  list(state = state, signal = list(warning = NA, drift = state$drift_detected))
}
