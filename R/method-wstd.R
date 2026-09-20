# WSTD - Wilcoxon Rank Sum Test Drift Detector (de Barros, Hidalgo & de Lima
# Cabral 2018, Neurocomputing 275). STEPD-inspired: keeps a recent window and an
# older window, but compares them with the Wilcoxon rank-sum (Mann-Whitney) test
# instead of the test of equal proportions, and CAPS the older window at max_old
# so a long stable past cannot dilute the test's sensitivity. The paper notes an
# efficient rank-sum implementation (ranks + p-value without an explicit sort);
# here we use the normal approximation with tie + continuity correction, which is
# exact enough for the binary correctness stream and avoids stats::wilcox.test's
# ties warnings.
#
# deriva convention: obs == 1 means ERROR. Drift fires when the RECENT window has
# significantly HIGHER values (more errors) than the older one -> one-sided test.
# No external R oracle (datadriftR lacks WSTD) -> validated against synthetic
# ground truth. Has warning.

# Binary stream: average ranks and the tie term follow from the counts of 0s and 1s, no rank()/table().
wstd_pvalue_counts <- function(r_rec, n_rec, r_old, n_old) {
  if (n_rec == 0 || n_old == 0) return(1)
  N <- n_rec + n_old
  ones <- r_rec + r_old
  zeros <- N - ones
  W <- (n_rec - r_rec) * (zeros + 1) / 2 + r_rec * (zeros + (ones + 1) / 2)
  mu <- n_rec * (N + 1) / 2
  tie_term <- if (N > 1) ((zeros^3 - zeros) + (ones^3 - ones)) / (N * (N - 1)) else 0
  sigma2 <- (n_rec * n_old / 12) * ((N + 1) - tie_term)
  if (sigma2 <= 0) return(1)
  z <- (W - mu - 0.5) / sqrt(sigma2)
  if (z <= 0) return(1)
  stats::pnorm(z, lower.tail = FALSE)
}

# One-sided (recent > older) Wilcoxon rank-sum p-value via the tie-corrected
# normal approximation. Returns 1 (no evidence) when recent is not higher.
wstd_pvalue <- function(recent, older) {
  wstd_pvalue_counts(sum(recent), length(recent), sum(older), length(older))
}

wstd_init <- function(params) {
  list(params = params, buf = numeric(0), n_total = 0,
       warning_detected = FALSE, change_detected = FALSE)
}

wstd_step <- function(state, obs) {
  p <- state$params
  if (state$change_detected) state <- wstd_init(p)
  state$n_total <- state$n_total + 1
  state$buf <- c(state$buf, obs)
  cap <- p$window_size + p$max_old                # recent + capped older
  if (length(state$buf) > cap) {
    state$buf <- state$buf[-seq_len(length(state$buf) - cap)]
  }
  # need a full recent window AND a non-empty older window
  if (state$n_total < p$min_instances || length(state$buf) <= p$window_size) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  ws <- p$window_size
  n <- length(state$buf)
  recent <- state$buf[(n - ws + 1):n]
  older  <- state$buf[seq_len(n - ws)]
  pv <- wstd_pvalue(recent, older)
  drift <- pv < p$out_control_level
  warning <- !drift && pv < p$warning_level
  state$change_detected <- drift
  state$warning_detected <- warning
  list(state = state, signal = list(warning = warning, drift = drift))
}
