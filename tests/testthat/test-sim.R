test_that("sim_drift_stream() returns the documented shape", {
  s <- sim_drift_stream(n_pre = 100, n_post = 50, seed = 1)
  expect_s3_class(s, "tbl_df")
  expect_named(s, c("t", "error", "drift_true"))
  expect_identical(nrow(s), 150L)
  expect_true(all(s$error %in% c(0, 1)))
  expect_identical(s$drift_true, c(rep(FALSE, 100), rep(TRUE, 50)))
})

test_that("sim_drift_stream() is reproducible with seed", {
  expect_identical(sim_drift_stream(seed = 7), sim_drift_stream(seed = 7))
})

test_that("error rate actually shifts at the drift point", {
  s <- sim_drift_stream(n_pre = 2000, n_post = 2000, p_pre = 0.05, p_post = 0.3, seed = 1)
  expect_lt(mean(s$error[1:2000]), 0.1)
  expect_gt(mean(s$error[2001:4000]), 0.2)
})
