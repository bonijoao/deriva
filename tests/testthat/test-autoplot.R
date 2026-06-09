test_that("autoplot() draws running error rate with drift marks", {
  skip_if_not_installed("ggplot2")
  base <- sim_drift_stream(n_pre = 200, n_post = 0, seed = 2)
  f <- fit(drift_detector("ddm"), base, signal = error) |>
    advance(sim_drift_stream(n_pre = 0, n_post = 400, p_post = 0.5, seed = 2))
  p <- ggplot2::autoplot(f)
  expect_s3_class(p, "ggplot")
})
