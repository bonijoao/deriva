# seed = 2 gives a quiet baseline (no DDM false positive in the first 200 obs,
# verified against datadriftR) so all drift lands in the stream phase.
drifted_fit <- function() {
  base <- sim_drift_stream(n_pre = 200, n_post = 0, seed = 2)
  f0 <- fit(drift_detector("ddm"), base, signal = error)
  advance(f0, sim_drift_stream(n_pre = 0, n_post = 400, p_post = 0.5, seed = 2))
}

test_that("tidy() lists drift points with index and phase", {
  td <- tidy(drifted_fit())
  expect_s3_class(td, "tbl_df")
  expect_named(td, c("index", "phase"))
  expect_gt(nrow(td), 0)
  expect_true(all(td$index > 200))      # drift only in the stream phase
  expect_true(all(td$phase == "stream"))
})

test_that("tidy() returns 0 rows when no drift", {
  base <- sim_drift_stream(n_pre = 200, n_post = 0, seed = 2)
  f0 <- fit(drift_detector("ddm"), base, signal = error)
  expect_identical(nrow(tidy(f0)), 0L)
})

test_that("glance() returns a 1-row summary", {
  g <- glance(drifted_fit())
  expect_identical(nrow(g), 1L)
  expect_named(g, c("method", "n_obs", "n_warning", "n_drift", "first_drift"))
  expect_identical(g$method, "ddm")
  expect_identical(g$n_obs, 600L)
  expect_gt(g$n_drift, 0)
  expect_gt(g$first_drift, 200L)
})
