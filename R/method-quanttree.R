# QuantTree - quantile histograms for change detection (Boracchi, Carrera,
# Cervellera & Maccio 2018, "QuantTree: Histograms for change detection in
# multivariate data streams", Proc. 35th ICML, PMLR 80, 639-648), in one
# dimension, where the tree of Algorithm 1 reduces to sorting (p. 4): a
# training set of N values gives K bins cut at its order statistics, each
# holding L_k training values. Each following batch of nu values is tested with
# the Pearson statistic of Eq. (6) against a threshold tau (Eq. 3). By Theorem 1
# the statistic's null law does not depend on the data, so tau depends only on
# N, K, nu and alpha; it is simulated as in Algorithm 2 / Eq. (5), drawing the
# bin probabilities from the Dirichlet(L_1, ..., L_{K-1}, L_K + 1) law of the
# Beta construction in Sec. 4 (an exact equivalent of drawing uniform training
# sets) and the batch counts from a multinomial.
# Ours: in 1-D bins are always split from the left, as the paper's proofs
# assume, so the histogram is deterministic; only the Pearson statistic (not
# the total variation of Eq. 7); smaller defaults than the paper's (N = 4096,
# K = 32, alpha = 0.05) so the warm-up stays short and false alarms rare; and a
# restart on drift (the paper defines a single-batch test): the next N values
# form a new training set, while tau, which depends only on the parameters, is
# kept. The guarantee needs continuous data; ties (e.g. 0/1 values) break the
# equal-count bins (the paper jitters such data, p. 6; we do not).
# Stochastic (the threshold simulation). Original code (MIT).

# Training values per bin: round(N / K) each, the last bin takes the rest.
qt_sizes <- function(N, K) {
  L <- rep(as.integer(round(N / K)), K)
  L[K] <- as.integer(N - sum(L[-K]))
  L
}

# Cut points at the order statistics z_(M_1), ..., z_(M_{K-1}).
qt_cuts <- function(train, K) {
  L <- qt_sizes(length(train), K)
  sort(train)[cumsum(L)[-K]]
}

# Bin counts for right-closed bins (-Inf, c_1], (c_1, c_2], ..., (c_{K-1}, Inf).
qt_counts <- function(x, cuts) {
  tabulate(findInterval(x, c(-Inf, cuts, Inf), left.open = TRUE,
                         all.inside = TRUE), length(cuts) + 1)
}

# Pearson statistic of Eq. (6), with expected bin probabilities L_k / N.
qt_pearson <- function(y, L, N) {
  e <- sum(y) * L / N
  sum((y - e)^2 / e)
}

# tau of Eq. (5): the smallest simulated value with at most alpha * n_sim
# simulated values above it.
qt_threshold <- function(N, K, nu, alpha, n_sim) {
  L <- qt_sizes(N, K)
  shape <- c(L[-K], L[K] + 1)
  g <- matrix(stats::rgamma(n_sim * K, shape = rep(shape, each = n_sim)), n_sim, K)
  rest <- g %*% lower.tri(diag(K), diag = TRUE)    # sum_{j >= k} g_j, per column k
  y <- matrix(0L, n_sim, K)
  left <- rep(nu, n_sim)
  for (k in seq_len(K - 1)) {                      # multinomial as a binomial chain
    y[, k] <- stats::rbinom(n_sim, left, pmin(1, g[, k] / rest[, k]))
    left <- left - y[, k]
  }
  y[, K] <- left
  e <- matrix(nu * L / N, n_sim, K, byrow = TRUE)
  v <- sort(rowSums((y - e)^2 / e))
  above <- n_sim - findInterval(v, v)              # #{v > t} at each t = v_i
  min(v[above <= alpha * n_sim])
}
