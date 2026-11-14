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
# equal-count bins and make most batches alarm (the paper jitters such data,
# p. 6; we do not, and warn once instead).
# Stochastic (the threshold simulation). Original code (MIT).

# Training values per bin: floor(N / K) each, with the remainder spread one by
# one over the last bins. The paper's round(N / K) with the rest in the last
# bin leaves it empty or negative when N is not a multiple of K (ours).
qt_sizes <- function(N, K) {
  L <- rep(as.integer(N %/% K), K)
  r <- as.integer(N %% K)
  if (r > 0) L[(K - r + 1):K] <- L[(K - r + 1):K] + 1L
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
  e <- nu * L / N
  rest <- rowSums(g)                               # sum_{j >= k} g_j
  left <- rep(nu, n_sim)
  v <- numeric(n_sim)
  for (k in seq_len(K - 1)) {                      # multinomial as a binomial chain
    y <- stats::rbinom(n_sim, left, pmin(1, g[, k] / rest))
    v <- v + (y - e[k])^2 / e[k]
    left <- left - y
    rest <- rest - g[, k]
  }
  v <- sort(v + (left - e[K])^2 / e[K])
  above <- n_sim - findInterval(v, v)              # #{v > t} at each t = v_i
  min(v[above <= alpha * n_sim])
}

quanttree_init <- function(params, tau = NA_real_, warned = FALSE) {
  list(params = params, tau = tau, warned = warned, train = numeric(0), cuts = NULL,
       L = qt_sizes(params$train_size, params$n_bins), batch = numeric(0),
       verdict = NA)
}

# Flags change on the observation that completes a batch and carry forward in
# between; NA while the training set fills, at the start and after a drift.
quanttree_step <- function(state, obs) {
  p <- state$params
  if (is.null(state$cuts)) {                       # filling the training set
    state$train <- c(state$train, obs)
    if (length(state$train) == p$train_size) {
      state$cuts <- qt_cuts(state$train, p$n_bins)
      if (!state$warned && anyDuplicated(state$train) > 0) {
        state$warned <- TRUE                       # once per detector
        cli::cli_warn(c(
          "The {.val quanttree} training set has tied values.",
          "i" = "Its bins are no longer equal-count, so most batches will be flagged as drift.",
          "i" = "QuantTree assumes continuous data; it does not suit 0/1 or count signals."
        ))
      }
      state$train <- numeric(0)
      if (is.na(state$tau)) {
        state$tau <- qt_threshold(p$train_size, p$n_bins, p$batch_size, p$alpha, p$n_sim)
      }
    }
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  state$batch <- c(state$batch, obs)
  if (length(state$batch) < p$batch_size) {
    return(list(state = state, signal = list(warning = NA, drift = state$verdict)))
  }
  y <- qt_counts(state$batch, state$cuts)
  drift <- qt_pearson(y, state$L, p$train_size) > state$tau
  state$batch <- numeric(0)
  state$verdict <- FALSE
  if (drift) state <- quanttree_init(p, state$tau, state$warned)  # restart, keeping tau (ours)
  list(state = state, signal = list(warning = NA, drift = drift))
}
