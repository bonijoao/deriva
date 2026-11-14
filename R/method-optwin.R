# OPTWIN - drift identification with optimal sub-windows (Tosi & Theobald 2024,
# "OPTWIN: Drift identification with optimal sub-windows", IEEE ICDE Workshops,
# DBML 2024). Algorithm 1: a sliding window W of errors is split at the optimal
# cut of Eq. (1), solved for the largest historical sub-window W_hist such that
# rho = t_ppf(d', df) * sqrt(1 / n_hist + f_ppf(d', n_hist - 1, n_new - 1) / n_new)
# can still be met, with d' = confidence^(1/4) and df from Eq. (2) of the
# extended version (arXiv:2305.11942); without such a cut, the middle. An
# F-test on the variances and a one-sided Welch t-test (Eq. 3) compare W_hist
# with W_new; drift when either is significant and the mean error rose.
# The cut depends only on |W|, confidence and rho, so it is solved once per
# window size and cached.
# The authors' code (github.com/maurodlt/optwin) was read for the defaults, the
# warning level and the reference cut table only; this code is original (MIT).
# Ours, and deviations from that code: (1) the F-test degrees of freedom are
# (n_hist - 1, n_new - 1), as in Algorithm 1 and the authors' tables; (2) df is
# Eq. (2) as printed (the code uses 1/f^2); (3) the t denominator uses
# variances, as in Eq. (3) (the code uses standard deviations); (4) the t
# statistic is mean(W_new) - mean(W_hist), the sign that can detect a rise (as
# printed, Eq. 3 could not); (5) sample standard deviations (the code divides
# by n). The warning level (t-test at warning_confidence = 0.98) comes from the
# authors' code; the papers define none. f_test = FALSE (ours, default TRUE)
# leaves the F-test out: on low error rates a sub-window with almost no errors
# has a near-zero variance, and the F-test then fires on stationary data.
# Deterministic.

optwin_cache <- new.env(parent = emptyenv())

# Welch degrees of freedom with sigma_new^2 bounded by f * sigma_hist^2 (Eq. 2).
optwin_df <- function(nh, nn, f) {
  (1 / nh + f / nn)^2 / ((1 / nh)^2 / (nh - 1) + (f / nn)^2 / (nn - 1))
}

# Optimal cut (size of W_hist) for a window of n values, with the quantiles the
# tests need at that cut. Memoised per (confidence, rho, n).
optwin_cut <- function(n, confidence, rho) {
  key <- paste(confidence, rho, n)
  hit <- optwin_cache[[key]]
  if (!is.null(hit)) return(hit)
  dp <- confidence^(1 / 4)
  R <- function(nn) {
    nh <- n - nn
    f <- stats::qf(dp, nh - 1, nn - 1)
    stats::qt(dp, optwin_df(nh, nn, f)) * sqrt(1 / nh + f / nn)
  }
  cut <- NA_integer_
  lo <- 2L
  while (is.na(cut) && lo <= n - 2L) {             # smallest W_new, in chunks
    nn <- lo:min(lo + 63L, n - 2L)
    ok <- which(R(nn) <= rho)
    if (length(ok)) cut <- as.integer(n - nn[ok[1]])
    lo <- lo + 64L
  }
  if (is.na(cut)) cut <- as.integer(floor(n / 2) + 1)  # no root: the middle
  nn <- n - cut
  fq <- stats::qf(dp, cut - 1, nn - 1)
  df <- optwin_df(cut, nn, fq)
  out <- list(cut = cut, df = df, fq = fq, tq = stats::qt(dp, df))
  optwin_cache[[key]] <- out
  out
}

optwin_init <- function(params) {
  list(params = params, W = numeric(0), warning = FALSE)
}

# Algorithm 1. eta keeps the F ratio finite on a zero-variance sub-window.
optwin_step <- function(state, obs) {
  p <- state$params
  eta <- 1e-5
  state$W <- c(state$W, obs)
  n <- length(state$W)
  if (n > p$max_window) {                          # drop the oldest value
    state$W <- state$W[-1]
    n <- n - 1L
  }
  if (n < p$min_window) return(list(state = state, signal = list(warning = NA, drift = NA)))
  k <- optwin_cut(n, p$confidence, p$rho)
  h <- state$W[seq_len(k$cut)]
  w <- state$W[(k$cut + 1):n]
  m_h <- mean(h)
  m_n <- mean(w)
  s_h <- stats::sd(h) + eta
  s_n <- stats::sd(w) + eta
  f_sig <- p$f_test && s_n^2 / s_h^2 > k$fq
  tstat <- (m_n - m_h) / sqrt(s_h^2 / k$cut + s_n^2 / (n - k$cut))   # Eq. (3), sign for a rise
  drift <- (f_sig || tstat > k$tq) && m_n > m_h
  if (drift) {                                     # restart from the triggering value
    state$W <- obs
    state$warning <- FALSE
  } else {
    state$warning <- tstat > stats::qt(p$warning_confidence, k$df)
  }
  list(state = state, signal = list(warning = state$warning, drift = drift))
}
