# HDDDM - Hellinger Distance Drift Detection Method (Ditzler & Polikar 2011,
# "Hellinger distance based drift detection for nonstationary environments",
# IEEE CIDUE 2011, 41-48). Batch procedure of Fig. 4 in one dimension: each
# batch becomes a histogram P with floor(sqrt(batch_size)) bins, its Hellinger
# distance to the reference histogram Q (Eq. 1) is computed, and drift is
# flagged when the change in distance |eps(t)| exceeds the adaptive threshold
# of Eq. (2), mean(|eps|) + gamma * sd(|eps|). Without drift the batch joins
# the reference (Q <- Q + P); on drift the reference becomes the batch (Q <- P).
# Ours: bin edges are equal-width over the reference batch, rebuilt from the
# drift batch when it becomes the new reference (the paper assumes a known
# finite support and keeps the bins), and the outer bins absorb out-of-range
# and infinite values; the default batch_size (the paper does not report one); the
# t-statistic threshold of Eq. (3) is left out (its degrees of freedom are not
# defined, and the paper prefers Eq. 2). Only counts are stored, as in the
# paper (assumption iii). Deterministic. Original code (MIT).

# Equal-width edges over the finite range of x, widened if the range is zero.
hdddm_edges <- function(x, b) {
  x <- x[is.finite(x)]
  r <- if (length(x)) range(x) else c(0, 0)
  if (r[1] == r[2]) r <- r + c(-0.5, 0.5)
  seq(r[1], r[2], length.out = b + 1)
}

# Bin counts; values outside the edges fall in the first or last bin.
hdddm_counts <- function(x, edges) {
  tabulate(findInterval(x, edges, all.inside = TRUE), length(edges) - 1)
}

# Hellinger distance between two count histograms (Eq. 1), in [0, sqrt(2)].
hdddm_distance <- function(P, Q) {
  sqrt(sum((sqrt(P / sum(P)) - sqrt(Q / sum(Q)))^2))
}

hdddm_init <- function(params) {
  list(params = params, buf = numeric(0), edges = NULL, Q = NULL,
       prev_d = NA_real_, eps = numeric(0), verdict = NA)
}

# Fig. 4 of Ditzler & Polikar (2011). Flags change on the observation that
# completes a batch and carry forward in between; NA while (re-)warming.
hdddm_step <- function(state, obs) {
  p <- state$params
  state$buf <- c(state$buf, obs)
  if (length(state$buf) < p$batch_size) {
    return(list(state = state, signal = list(warning = NA, drift = state$verdict)))
  }
  batch <- state$buf
  state$buf <- numeric(0)
  if (is.null(state$edges)) {                      # first batch: the reference
    state$edges <- hdddm_edges(batch, floor(sqrt(p$batch_size)))
    state$Q <- hdddm_counts(batch, state$edges)
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  P <- hdddm_counts(batch, state$edges)
  d <- hdddm_distance(P, state$Q)
  drift <- NA
  if (!is.na(state$prev_d)) {
    e <- abs(d - state$prev_d)
    if (length(state$eps) >= 1) {
      m <- mean(state$eps)
      beta <- m + p$gamma * sqrt(mean((state$eps - m)^2))  # Eq. (2), population sd
      drift <- e > beta
    }
  }
  if (isTRUE(drift)) {                             # the batch becomes the reference
    # its own bins (ours): edges from the old regime would lump the new one into
    # an outer bin and hide any further change in the same direction
    state$edges <- hdddm_edges(batch, length(state$Q))
    state$Q <- hdddm_counts(batch, state$edges)
    state$prev_d <- NA_real_
    state$eps <- numeric(0)
    state$verdict <- NA
  } else {
    if (!is.na(state$prev_d)) state$eps <- c(state$eps, abs(d - state$prev_d))
    state$prev_d <- d
    state$Q <- state$Q + P
    state$verdict <- drift
  }
  list(state = state, signal = list(warning = NA, drift = drift))
}
