make_fit <- function() {
  base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
  fit(drift_detector("ddm"), base, signal = error)
}

test_that("augment(fit) returns the accumulated history", {
  f0 <- make_fit()
  h <- augment(f0)
  expect_s3_class(h, "tbl_df")
  expect_identical(nrow(h), 100L)
  expect_true(all(c(".warning", ".drift", ".phase") %in% names(h)))
})

test_that("augment(fit, new_data) is a read-only preview", {
  f0 <- make_fit()
  batch <- sim_drift_stream(n_pre = 0, n_post = 50, p_post = 0.05, seed = 2)
  prev <- augment(f0, batch)
  expect_identical(nrow(prev), 50L)
  expect_true(all(c(".warning", ".drift") %in% names(prev)))
  expect_false(".phase" %in% names(prev)) # preview is not history
  expect_identical(nrow(augment(f0)), 100L) # f0 NOT advanced
})

test_that("preview annotations equal what advance() would record", {
  f0 <- make_fit()
  batch <- sim_drift_stream(n_pre = 0, n_post = 50, p_post = 0.3, seed = 3)
  prev <- augment(f0, batch)
  adv <- advance(f0, batch)$history[101:150, ]
  expect_identical(prev$.drift, adv$.drift)
  expect_identical(prev$.warning, adv$.warning)
})
