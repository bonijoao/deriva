devtools::load_all("D:/deriva-dev/deriva", quiet = TRUE)

# drifted_fit candidate: quiet baseline (seed 2) + strong stream
base <- sim_drift_stream(n_pre = 200, n_post = 0, seed = 2)
f0 <- fit(drift_detector("ddm"), base, signal = error)
cat("baseline drifts:", length(which(f0$history$.drift)), "\n")
f <- advance(f0, sim_drift_stream(n_pre = 0, n_post = 400, p_post = 0.5, seed = 2))
d <- which(f$history$.drift)
cat("total drifts:", length(d), "indices:", paste(head(d, 5), collapse = ","), "\n")
cat("all > 200:", all(d > 200), "| first:", d[1], "| n_obs:", nrow(f$history), "\n")

# no-drift candidate
f_quiet <- fit(drift_detector("ddm"), sim_drift_stream(n_pre = 200, n_post = 0, seed = 2), signal = error)
cat("quiet fit drifts:", length(which(f_quiet$history$.drift)), "\n")
