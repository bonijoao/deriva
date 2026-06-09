test_that("fit() consumes the baseline and returns a drift_detector_fit", {
  base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
  f <- fit(drift_detector("ddm"), base, signal = error)
  expect_s3_class(f, "drift_detector_fit")
  h <- f$history
  expect_identical(nrow(h), 100L)
  expect_true(all(c(".warning", ".drift", ".phase") %in% names(h)))
  expect_true(all(h$.phase == "baseline"))
  expect_identical(f$signal_col, "error")
  expect_gt(f$state$sample_count, 1) # engine actually ran
})

test_that("fit() validates the signal column", {
  base <- tibble::tibble(x = c(0.5, 0.7)) # not 0/1
  expect_error(fit(drift_detector("ddm"), base, signal = x), "0/1")
  expect_error(fit(drift_detector("ddm"), base, signal = missing_col), "not found")
})

test_that("fit() aborts on NA in the signal (documented DDM policy)", {
  base <- tibble::tibble(error = c(0, NA, 1))
  expect_error(fit(drift_detector("ddm"), base, signal = error), "NA")
})
