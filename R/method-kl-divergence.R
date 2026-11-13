# KL divergence change detection (Dasu, Krishnan, Venkatasubramanian & Yi
# 2006, "An information-theoretic approach to detecting changes in
# multi-dimensional data streams"), Algorithm 2.1 in one dimension.
# Implemented from the paper; no external R oracle -> synthetic validation.
# Code is original (MIT).
#
# A fixed reference window W_ref (the first `window_size` values of a cycle) is
# compared with a sliding window W_t of the most recent `window_size` values.
# Both are summarised as "types" (counts) over cells built once from W_ref by a
# 1-D kdq-tree (recursive midpoint bisection, paper section 5); probabilities
# use the Krichevsky-Trofimov 0.5 correction (paper section 3.1). The critical
# value d_hi is the (1 - alpha) quantile of bootstrap distances (section 4);
# drift is flagged after ceiling(persistence * window_size) consecutive steps
# with D(W_ref || W_t) > d_hi, and the cycle starts over.
#
# Choices that are ours, not the paper's: the outer cells extend to -Inf/Inf so
# values outside the reference range are counted; the bootstrap resamples the
# reference window only (the sole sample of H0 at that moment); a constant
# reference gets a cell of its own; defaults window_size = 200 and
# max_cell_points = 20 are scaled down from the paper's n = 10000 / tau = 100.
# Stochastic (the bootstrap): honours drift_detector(seed =). No warning level.

# Break points of the kdq-tree cells built on `ref`, on the original scale.
# Cells are [b_i, b_{i+1}) as findInterval() sees them; outer breaks are +-Inf.
kl_cells <- function(ref, max_cell_points, min_cell_width) {
  lo <- min(ref)
  width <- max(ref) - lo
  if (width == 0) {
    return(c(-Inf, lo, lo + max(abs(lo), 1) * 1e-9, Inf))
  }
  s <- (ref - lo) / width
  split <- function(x, a, b) {
    if (length(x) < max_cell_points || (b - a) < min_cell_width) return(numeric(0))
    mid <- (a + b) / 2
    c(split(x[x < mid], a, mid), mid, split(x[x >= mid], mid, b))
  }
  c(-Inf, lo + split(s, 0, 1) * width, Inf)
}

kl_counts <- function(x, breaks) {
  tabulate(findInterval(x, breaks), length(breaks) - 1L)
}

# Base-2 KL distance between two types with Krichevsky-Trofimov probabilities.
kl_kt_divergence <- function(ref_counts, win_counts) {
  k <- length(ref_counts)
  p <- (ref_counts + 0.5) / (sum(ref_counts) + k / 2)
  q <- (win_counts + 0.5) / (sum(win_counts) + k / 2)
  sum(p * log2(p / q))
}

# Critical value: (1 - alpha) quantile of distances between the two halves of
# n_boot resamples of size 2n drawn with replacement from the reference.
kl_bootstrap <- function(ref, breaks, n_boot, alpha) {
  n <- length(ref)
  d <- vapply(seq_len(n_boot), function(i) {
    s <- sample(ref, 2L * n, replace = TRUE)
    kl_kt_divergence(kl_counts(s[seq_len(n)], breaks),
                     kl_counts(s[n + seq_len(n)], breaks))
  }, numeric(1))
  stats::quantile(d, 1 - alpha, names = FALSE)
}
