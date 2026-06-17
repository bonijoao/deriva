# Fisher family of STEPD-based detectors (de Lima Cabral & de Barros 2018,
# "Concept drift detection based on Fisher's Exact test", Information Sciences).
# Same recent-vs-older windowed structure as STEPD, but the proportions test is
# replaced (FTDD) or guarded (FPDD/FSDD) by Fisher's Exact test, which stays
# valid when the 2x2 table has small cell counts (sparse/imbalanced streams).
#
# deriva convention: obs == 1 means ERROR (the STEPD original uses 1=correct).
# So the recent window's error count is sum(window); drift fires when the RECENT
# error rate is significantly HIGHER than the older one. No external R oracle
# (datadriftR lacks these) -> validated against synthetic ground truth. Has
# warning. The 2x2 table compared at each step (rows = window, cols = outcome):
#
#                errors            corrects
#   recent       r_rec             n_rec - r_rec
#   older        r_old             n_old - r_old

fisher_family_init <- function(params) {
  list(params = params, window = numeric(0), n_total = 0, r_total = 0,
       warning_detected = FALSE, change_detected = FALSE)
}

# One-sided (recent error rate > older) Fisher's Exact test p-value.
fisher_pvalue <- function(r_old, n_old, r_rec, n_rec, p) {
  if (n_old <= 0 || n_rec <= 0) return(1)
  if (r_rec / n_rec <= r_old / n_old) return(1)   # only flag increases
  # column-major fill: row1 = recent, row2 = older; col1 = errors, col2 = correct
  tab <- matrix(c(r_rec, r_old, n_rec - r_rec, n_old - r_old), nrow = 2)
  stats::fisher.test(tab, alternative = "greater")$p.value
}

# One-sided (recent error rate > older) proportions z-test, optionally with the
# Yates continuity correction. continuity = TRUE reproduces STEPD's test (FPDD's
# fallback); continuity = FALSE is the chi-square homogeneity test (FSDD's).
prop_z_pvalue <- function(r_old, n_old, r_rec, n_rec, continuity) {
  if (n_old <= 0 || n_rec <= 0) return(1)
  p_old <- r_old / n_old
  p_rec <- r_rec / n_rec
  if (p_rec <= p_old) return(1)                    # only flag increases
  p_hat <- (r_old + r_rec) / (n_old + n_rec)
  denom <- p_hat * (1 - p_hat) * (1 / n_old + 1 / n_rec)
  if (denom <= 0) return(1)
  cc <- if (continuity) 0.5 * (1 / n_old + 1 / n_rec) else 0
  z <- (abs(p_old - p_rec) - cc) / sqrt(denom)
  if (z < 0) z <- 0
  stats::pnorm(z, lower.tail = FALSE)
}

# FPDD/FSDD switch to Fisher when any cell of the 2x2 table is "small"
# (< min_cell, classical threshold 5), otherwise use their proportions branch.
fisher_cells_small <- function(r_old, n_old, r_rec, n_rec, min_cell) {
  min(r_rec, n_rec - r_rec, r_old, n_old - r_old) < min_cell
}

ftdd_pvalue <- function(r_old, n_old, r_rec, n_rec, p) {
  fisher_pvalue(r_old, n_old, r_rec, n_rec, p)
}

fpdd_pvalue <- function(r_old, n_old, r_rec, n_rec, p) {
  if (fisher_cells_small(r_old, n_old, r_rec, n_rec, p$min_cell)) {
    fisher_pvalue(r_old, n_old, r_rec, n_rec, p)
  } else {
    prop_z_pvalue(r_old, n_old, r_rec, n_rec, continuity = TRUE)
  }
}

fsdd_pvalue <- function(r_old, n_old, r_rec, n_rec, p) {
  if (fisher_cells_small(r_old, n_old, r_rec, n_rec, p$min_cell)) {
    fisher_pvalue(r_old, n_old, r_rec, n_rec, p)
  } else {
    prop_z_pvalue(r_old, n_old, r_rec, n_rec, continuity = FALSE)
  }
}

# Shared STEPD-style windowed step; the variant supplies pvalue_fn.
fisher_family_step <- function(state, obs, pvalue_fn) {
  p <- state$params
  if (state$change_detected) state <- fisher_family_init(p)
  state$n_total <- state$n_total + 1
  state$r_total <- state$r_total + obs
  state$window <- c(state$window, obs)
  if (length(state$window) > p$window_size) {
    state$window <- state$window[-1]
  }
  if (state$n_total < p$min_instances || length(state$window) < p$window_size) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }
  r_rec <- sum(state$window)
  n_rec <- length(state$window)
  r_old <- state$r_total - r_rec
  n_old <- state$n_total - n_rec
  pv <- pvalue_fn(r_old, n_old, r_rec, n_rec, p)
  drift <- pv < p$out_control_level
  warning <- !drift && pv < p$warning_level
  state$change_detected <- drift
  state$warning_detected <- warning
  list(state = state, signal = list(warning = warning, drift = drift))
}

ftdd_init <- fisher_family_init
fpdd_init <- fisher_family_init
fsdd_init <- fisher_family_init

ftdd_step <- function(state, obs) fisher_family_step(state, obs, ftdd_pvalue)
fpdd_step <- function(state, obs) fisher_family_step(state, obs, fpdd_pvalue)
fsdd_step <- function(state, obs) fisher_family_step(state, obs, fsdd_pvalue)
