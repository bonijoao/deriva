# Runs `method` on the bundled stream matching its signal type (seed fixed for the stochastic ones).
run_on_bundled <- function(method) {
  m <- deriva:::the$methods[[method]]
  error_based <- m$signal_type == "error"
  data <- if (error_based) deriva::credit_monitoring else deriva::sensor_monitoring
  col <- as.name(if (error_based) "error" else "value")
  do.call(deriva::detect_drift, list(data, .col = col, method = method, seed = 1))
}
