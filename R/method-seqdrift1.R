# SeqDrift1 - sequential change detector with a sliding left window
# (Sakthithasan, Pears & Koh 2013, "One pass concept change detection for data
# streams", PAKDD 2013, LNCS 7819). The predecessor of SeqDrift2: a RIGHT
# repository buffers recent values and, at every block boundary, its mean is
# compared with that of a LEFT window holding the most recent older blocks.
#
# Threshold: Theorem 1 of Pears, Sakthithasan & Koh (2014, Machine Learning 97),
# the Bernstein bound on the difference of two means, with delta split over
# successive tests by the geometric series 2(1 - 0.5^n). Structure (defaults,
# left window capped at 1 / delta blocks, warning zone that doubles the right
# repository) follows the author's MOA implementation, read for structure only
# (GPL); this code is original (MIT). MOA quirks deliberately not reproduced:
# means divided by the nominal sample size instead of the true count, a variance
# formula valid only for 0/1 values, and random sub-sampling of the left window.
# Ours: num_tests restarts at 0 after a drift (the new reference starts a fresh
# test sequence), and the warning zone is exposed through .warning.
# Deterministic. The guarantee assumes values in [0, 1], as for "seqdrift2".

# Theorem 1 of Pears et al. (2014): twice the converged SeqDrift2 bound.
seqdrift1_epsilon <- function(b, variance, delta, num_tests) {
  2 * seqdrift2_epsilon(b, variance, delta, num_tests)
}
