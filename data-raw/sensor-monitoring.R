# Regenerates data/sensor_monitoring.rda. Run by hand; not part of the build.
sensor_monitoring <- deriva::sim_dist_stream(
  n_pre = 500, n_post = 500,
  mean_pre = 0, mean_post = 2,
  seed = 2
)

save(sensor_monitoring, file = "data/sensor_monitoring.rda", compress = "xz")
