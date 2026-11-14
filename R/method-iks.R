# IKS - drift detection with the incremental Kolmogorov-Smirnov test (dos Reis,
# Flach, Matwin & Batista 2016, "Fast unsupervised online drift detection using
# incremental Kolmogorov-Smirnov test", KDD '16, 1545-1554). Procedure of
# Sec. 4 in one dimension: a fixed reference window of W values is compared
# with a sliding window of the last W values by a two-sided KS test after every
# observation; drift when D > c(alpha) * sqrt(2 / W) (Sec. 3.1), and the
# reference is then replaced by the current window.
# The paper's randomized treap only speeds up the update and "gives the exact
# same results as KS"; we compute the exact ECDF statistic directly, which
# also handles ties exactly.
# Unlike "kswin", the reference stays fixed until a drift and both windows are
# used whole, so IKS is deterministic.
# Ours: the initial reference is the first W observations (the paper uses the
# model's training data); the windows never overlap - the current window
# starts empty, at the start and after a drift, since the two-sample test
# assumes independent samples; no correction for testing on every observation
# (the paper's remedy is its small alpha = 0.001). Original code (MIT).

# Asymptotic Smirnov critical value; reproduces the usual table
# (0.05 -> 1.36, 0.001 -> 1.95).
iks_c <- function(alpha) sqrt(-log(alpha / 2) / 2)

# Exact two-sample KS statistic: the ECDF supremum over the pooled values.
iks_d <- function(ref_sorted, cur) {
  cur <- sort(cur)
  z <- unique(c(ref_sorted, cur))
  max(abs(findInterval(z, ref_sorted) / length(ref_sorted) -
            findInterval(z, cur) / length(cur)))
}
