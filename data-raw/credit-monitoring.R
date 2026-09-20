# Regenerates data/credit_monitoring.rda. Run by hand; not part of the build.
# Same story as the README Quick Start (seed = 2): one clean DDM detection
# at t = 542, zero false positives in the baseline.
credit_monitoring <- deriva::sim_drift_stream(
  n_pre = 500, n_post = 500,
  p_pre = 0.05, p_post = 0.30,
  seed = 2
)

save(credit_monitoring, file = "data/credit_monitoring.rda", compress = "xz")
