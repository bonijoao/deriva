# HDDDM - Hellinger Distance Drift Detection Method (Ditzler & Polikar 2011,
# "Hellinger distance based drift detection for nonstationary environments",
# IEEE CIDUE 2011, 41-48). Batch procedure of Fig. 4 in one dimension: each
# batch becomes a histogram P with floor(sqrt(batch_size)) bins, its Hellinger
# distance to the reference histogram Q (Eq. 1) is computed, and drift is
# flagged when the change in distance |eps(t)| exceeds the adaptive threshold
# of Eq. (2), mean(|eps|) + gamma * sd(|eps|). Without drift the batch joins
# the reference (Q <- Q + P); on drift the reference becomes the batch (Q <- P).
# Ours: bin edges are equal-width over the first reference batch (the paper
# assumes a known finite support), and the outer bins absorb out-of-range and
# infinite values; the default batch_size (the paper does not report one); the
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
