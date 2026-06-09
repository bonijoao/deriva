test_that("sim_dist_stream() returns the documented shape", {
  s <- sim_dist_stream(n_pre = 100, n_post = 50, seed = 1)
  expect_s3_class(s, "tbl_df")
  expect_named(s, c("t", "value", "drift_true"))
  expect_identical(nrow(s), 150L)
  expect_true(is.numeric(s$value))
  expect_identical(s$drift_true, c(rep(FALSE, 100), rep(TRUE, 50)))
})

test_that("sim_dist_stream() is reproducible and shifts the mean", {
  expect_identical(sim_dist_stream(seed = 7), sim_dist_stream(seed = 7))
  s <- sim_dist_stream(n_pre = 2000, n_post = 2000, mean_pre = 0, mean_post = 3, seed = 1)
  expect_lt(abs(mean(s$value[1:2000]) - 0), 0.15)
  expect_gt(mean(s$value[2001:4000]), 2.5)
})
